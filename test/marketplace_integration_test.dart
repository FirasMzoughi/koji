import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:koji/app/koji_web_api_client.dart';
import 'package:koji/features/marketplace/repository/marketplace_repository.dart';

class MockKojiWebApiClient extends Mock implements KojiWebApiClient {}

void main() {
  group('Marketplace Full Flow Integration Tests', () {
    late MarketplaceRepository repository;
    late MockKojiWebApiClient mockClient;

    setUp(() {
      mockClient = MockKojiWebApiClient();
      repository = MarketplaceRepository(mockClient);
    });

    test(
        'Complete marketplace workflow: view offer → request RDV → message → payment',
        () async {
      const offerId = 'offer-integration-test-123';
      const rdvDateTime = '2026-11-15T10:30:00Z';
      const messageText = 'Quels sont vos délais?';

      // Step 1: Get offer detail
      when(() => mockClient.get('/api/chantier-offres/$offerId'))
          .thenAnswer((_) async => {
            'offre': {
              'id': offerId,
              'metier': 'Plomberie',
              'description': 'Fuite au rez-de-chaussée',
              'status': 'published',
            }
          });

      // Step 2: Request RDV
      when(() => mockClient.postJson(
            '/api/marketplace/offres/$offerId/visite',
            any(),
          )).thenAnswer(
        (_) async => {
          'visitId': 'visit-456',
          'status': 'pending',
          'proposedDateTime': rdvDateTime,
        },
      );

      // Step 3: Send message
      when(() => mockClient.postJson(
            '/api/marketplace/offres/$offerId/messages',
            any(),
          )).thenAnswer(
        (_) async => {
          'message': {
            'id': 'msg-1',
            'text': messageText,
            'sender': 'self',
            'createdAt': '2026-11-10T11:00:00Z',
          }
        },
      );

      // Step 4: Get payment checkout
      const stripeCheckoutUrl =
          'https://checkout.stripe.com/pay/cs_test_abc123';
      when(() => mockClient.get(
            '/api/marketplace/offres/$offerId/paiement/review',
          )).thenAnswer(
        (_) async => {
          'checkoutUrl': stripeCheckoutUrl,
          'amount': 5000,
          'currency': 'eur',
        },
      );

      // Step 5: Validate payment
      when(() => mockClient.postJson(
            '/api/marketplace/offres/$offerId/paiement/validate/valider',
            any(),
          )).thenAnswer(
        (_) async => {
          'success': true,
          'status': 'paid',
          'amount': 5000,
        },
      );

      // === Execute full workflow ===

      // 1. View offer
      final offerData = await repository.getOfferDetail(offerId);
      expect(offerData['metier'], 'Plomberie');
      expect(offerData['status'], 'published');

      // 2. Request RDV
      final rdvResult = await repository.requestRdv(
        offerId: offerId,
        proposedDateTime: DateTime.parse(rdvDateTime),
        note: 'Après 18h',
      );
      expect(rdvResult['status'], 'pending');
      expect(rdvResult['visitId'], 'visit-456');

      // 3. Send message
      final msgResult = await repository.sendOfferMessage(
        offerId: offerId,
        text: messageText,
      );
      expect(msgResult['text'], messageText);
      expect(msgResult['sender'], 'self');

      // 4. Get payment URL
      final paymentData = await repository.getPaymentCheckoutUrl(
        offerId: offerId,
        step: 'review',
      );
      expect(paymentData['checkoutUrl'], stripeCheckoutUrl);
      expect(paymentData['amount'], 5000);

      // 5. Validate payment
      final paymentResult = await repository.validatePayment(
        offerId: offerId,
        step: 'validate',
        sessionId: 'cs_test_abc123',
      );
      expect(paymentResult['success'], true);
      expect(paymentResult['status'], 'paid');

      // Verify all API calls were made in order
      verify(() => mockClient.get('/api/chantier-offres/$offerId')).called(1);
      verify(() => mockClient.postJson(
        '/api/marketplace/offres/$offerId/visite',
        any(),
      )).called(1);
      verify(() => mockClient.postJson(
        '/api/marketplace/offres/$offerId/messages',
        any(),
      )).called(1);
      verify(() => mockClient.get(
        '/api/marketplace/offres/$offerId/paiement/review',
      )).called(1);
      verify(() => mockClient.postJson(
        '/api/marketplace/offres/$offerId/paiement/validate/valider',
        any(),
      )).called(1);
    });

    test('Messaging thread persists across multiple messages', () async {
      const offerId = 'offer-456';

      // Mock message history
      when(() => mockClient.get(
            '/api/marketplace/offres/$offerId/messages',
          )).thenAnswer(
        (_) async => {
          'messages': [
            {
              'id': 'msg-1',
              'text': 'Premier message',
              'sender': 'entreprise',
              'createdAt': '2026-11-09T10:00:00Z',
            },
            {
              'id': 'msg-2',
              'text': 'Ma réponse',
              'sender': 'self',
              'createdAt': '2026-11-09T11:00:00Z',
            },
          ]
        },
      );

      when(() => mockClient.postJson(
            '/api/marketplace/offres/$offerId/messages',
            any(),
          )).thenAnswer(
        (_) async => {
          'message': {
            'id': 'msg-3',
            'text': 'Message 3',
            'sender': 'self',
            'createdAt': '2026-11-10T09:00:00Z',
          }
        },
      );

      // Get initial messages
      final messages = await repository.getOfferMessages(offerId);
      expect(messages.length, 2);
      expect(messages[0]['sender'], 'entreprise');
      expect(messages[1]['sender'], 'self');

      // Send new message
      final newMsg = await repository.sendOfferMessage(
        offerId: offerId,
        text: 'Message 3',
      );
      expect(newMsg['id'], 'msg-3');

      // Verify thread continuity
      verify(() => mockClient.get(
        '/api/marketplace/offres/$offerId/messages',
      )).called(1);
      verify(() => mockClient.postJson(
        '/api/marketplace/offres/$offerId/messages',
        any(),
      )).called(1);
    });

    test('RDV and payment are independent workflows', () async {
      const offerId = 'offer-789';

      // Can request RDV without payment
      when(() => mockClient.postJson(
            '/api/marketplace/offres/$offerId/visite',
            any(),
          )).thenAnswer(
        (_) async => {'status': 'pending', 'visitId': 'visit-1'},
      );

      final rdv = await repository.requestRdv(
        offerId: offerId,
        proposedDateTime: DateTime.now().add(const Duration(days: 5)),
      );
      expect(rdv['status'], 'pending');

      // Can process payment independently
      when(() => mockClient.get(
            '/api/marketplace/offres/$offerId/paiement/review',
          )).thenAnswer(
        (_) async => {
          'checkoutUrl': 'https://checkout.stripe.com/...',
          'amount': 10000,
        },
      );

      final payment = await repository.getPaymentCheckoutUrl(
        offerId: offerId,
        step: 'review',
      );
      expect(payment['amount'], 10000);

      // Both should work independently
      verify(() => mockClient.postJson(
        '/api/marketplace/offres/$offerId/visite',
        any(),
      )).called(1);
      verify(() => mockClient.get(
        '/api/marketplace/offres/$offerId/paiement/review',
      )).called(1);
    });
  });
}
