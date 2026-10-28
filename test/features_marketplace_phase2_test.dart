import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:koji/app/koji_web_api_client.dart';
import 'package:koji/features/marketplace/repository/marketplace_repository.dart';

class MockKojiWebApiClient extends Mock implements KojiWebApiClient {}

void main() {
  group('MarketplaceRepository - Phase 2 Messaging & Payment', () {
    late MarketplaceRepository repository;
    late MockKojiWebApiClient mockClient;

    setUp(() {
      mockClient = MockKojiWebApiClient();
      repository = MarketplaceRepository(mockClient);
    });

    // === MESSAGING TESTS ===
    test('getOfferMessages fetches all messages for an offer', () async {
      const offerId = 'offer-123';

      when(() => mockClient.get(
            '/api/marketplace/offres/$offerId/messages',
          )).thenAnswer(
        (_) async => {
          'messages': [
            {
              'id': 'msg-1',
              'text': 'Bonjour, quels sont vos délais?',
              'sender': 'entreprise-789',
              'createdAt': '2026-11-10T10:00:00Z',
            },
            {
              'id': 'msg-2',
              'text': 'Délai de 2 semaines',
              'sender': 'self',
              'createdAt': '2026-11-10T11:00:00Z',
            },
          ]
        },
      );

      final result = await repository.getOfferMessages(offerId);

      expect(result.length, 2);
      expect(result[0]['text'], 'Bonjour, quels sont vos délais?');
      expect(result[1]['sender'], 'self');

      verify(() => mockClient.get(
        '/api/marketplace/offres/$offerId/messages',
      )).called(1);
    });

    test('sendOfferMessage posts message to offer thread', () async {
      const offerId = 'offer-123';
      const messageText = 'Ma réponse...';

      when(() => mockClient.postJson(
            '/api/marketplace/offres/$offerId/messages',
            any(),
          )).thenAnswer(
        (_) async => {
          'message': {
            'id': 'msg-new',
            'text': messageText,
            'sender': 'self',
            'createdAt': '2026-11-10T12:00:00Z',
          }
        },
      );

      final result = await repository.sendOfferMessage(
        offerId: offerId,
        text: messageText,
      );

      expect(result['text'], messageText);
      expect(result['sender'], 'self');

      verify(() => mockClient.postJson(
        '/api/marketplace/offres/$offerId/messages',
        {'text': messageText},
      )).called(1);
    });

    // === PAYMENT TESTS ===
    test('getPaymentCheckoutUrl fetches Stripe session URL', () async {
      const offerId = 'offer-123';
      const step = 'checkout';
      const stripeUrl =
          'https://checkout.stripe.com/pay/cs_test_abc123';

      when(() => mockClient.get(
            '/api/marketplace/offres/$offerId/paiement/$step',
          )).thenAnswer(
        (_) async => {
          'checkoutUrl': stripeUrl,
          'step': step,
          'amount': 5000,
          'currency': 'eur',
        },
      );

      final result = await repository.getPaymentCheckoutUrl(
        offerId: offerId,
        step: step,
      );

      expect(result['checkoutUrl'], stripeUrl);
      expect(result['amount'], 5000);

      verify(() => mockClient.get(
        '/api/marketplace/offres/$offerId/paiement/$step',
      )).called(1);
    });

    test('validatePayment confirms Stripe checkout completion', () async {
      const offerId = 'offer-123';
      const step = 'validate';
      const sessionId = 'cs_test_abc123';

      when(() => mockClient.postJson(
            '/api/marketplace/offres/$offerId/paiement/$step/valider',
            any(),
          )).thenAnswer(
        (_) async => {
          'success': true,
          'status': 'paid',
          'amount': 5000,
          'createdAt': '2026-11-10T13:00:00Z',
        },
      );

      final result = await repository.validatePayment(
        offerId: offerId,
        step: step,
        sessionId: sessionId,
      );

      expect(result['success'], true);
      expect(result['status'], 'paid');

      verify(() => mockClient.postJson(
        '/api/marketplace/offres/$offerId/paiement/$step/valider',
        {'sessionId': sessionId},
      )).called(1);
    });

    test('validatePayment without sessionId still works', () async {
      const offerId = 'offer-123';
      const step = 'validate';

      when(() => mockClient.postJson(
            '/api/marketplace/offres/$offerId/paiement/$step/valider',
            any(),
          )).thenAnswer(
        (_) async => {'success': true, 'status': 'paid'},
      );

      final result = await repository.validatePayment(
        offerId: offerId,
        step: step,
      );

      expect(result['success'], true);

      verify(() => mockClient.postJson(
        '/api/marketplace/offres/$offerId/paiement/$step/valider',
        {},
      )).called(1);
    });
  });
}
