import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:koji/app/koji_web_api_client.dart';
import 'package:koji/features/marketplace/repository/marketplace_repository.dart';

class MockKojiWebApiClient extends Mock implements KojiWebApiClient {}

void main() {
  group('MarketplaceRepository - Phase 1 RDV Booking', () {
    late MarketplaceRepository repository;
    late MockKojiWebApiClient mockClient;

    setUp(() {
      mockClient = MockKojiWebApiClient();
      repository = MarketplaceRepository(mockClient);
    });

    test('requestRdv sends correct payload to /api/marketplace/offres/:id/visite',
        () async {
      const offerId = 'offer-123';
      final proposedDateTime = DateTime(2026, 11, 15, 10, 30);
      const note = 'Après 18h';

      when(() => mockClient.postJson(
            '/api/marketplace/offres/$offerId/visite',
            any(),
          )).thenAnswer(
        (_) async => {
          'visitId': 'visit-456',
          'status': 'pending',
          'proposedDateTime': proposedDateTime.toIso8601String(),
        },
      );

      final result = await repository.requestRdv(
        offerId: offerId,
        proposedDateTime: proposedDateTime,
        note: note,
      );

      expect(result['visitId'], 'visit-456');
      expect(result['status'], 'pending');

      verify(() => mockClient.postJson(
        '/api/marketplace/offres/$offerId/visite',
        {
          'proposedDateTime': proposedDateTime.toIso8601String(),
          'note': note,
        },
      )).called(1);
    });

    test('getRdvRequests fetches list of RDV requests for an offer', () async {
      const offerId = 'offer-123';

      when(() => mockClient.get(
            '/api/marketplace/offres/$offerId/visite',
          )).thenAnswer(
        (_) async => {
          'visites': [
            {
              'id': 'visit-1',
              'proposedDateTime': '2026-11-15T10:30:00Z',
              'status': 'pending',
            },
            {
              'id': 'visit-2',
              'proposedDateTime': '2026-11-16T14:00:00Z',
              'status': 'accepted',
            },
          ]
        },
      );

      final result = await repository.getRdvRequests(offerId);

      expect(result.length, 2);
      expect(result[0]['id'], 'visit-1');
      expect(result[1]['status'], 'accepted');

      verify(() => mockClient.get(
        '/api/marketplace/offres/$offerId/visite',
      )).called(1);
    });

    test('respondToRdv sends accept/decline response', () async {
      const offerId = 'offer-123';
      const visitId = 'visit-456';
      const accepted = true;
      const confirmedDateTime = '2026-11-15T10:30:00Z';

      when(() => mockClient.patchJson(
            '/api/marketplace/offres/$offerId/visite/$visitId',
            any(),
          )).thenAnswer(
        (_) async => {
          'visitId': visitId,
          'accepted': accepted,
          'confirmedDateTime': confirmedDateTime,
        },
      );

      final result = await repository.respondToRdv(
        offerId: offerId,
        visitId: visitId,
        accepted: accepted,
        confirmedDateTime: confirmedDateTime,
      );

      expect(result['accepted'], true);
      expect(result['confirmedDateTime'], confirmedDateTime);

      verify(() => mockClient.patchJson(
        '/api/marketplace/offres/$offerId/visite/$visitId',
        {
          'accepted': accepted,
          'confirmedDateTime': confirmedDateTime,
        },
      )).called(1);
    });

    test('publishOffer sends all required fields', () async {
      when(() => mockClient.postJson(
            '/api/chantier-offres',
            any(),
          )).thenAnswer(
        (_) async => {
          'offre': {
            'id': 'offer-789',
            'metier': 'Plomberie',
            'status': 'published',
          }
        },
      );

      final result = await repository.publishOffer(
        expertiseId: 'exp-123',
        conseilsSelectionnes: ['conseil-1'],
        description: 'Besoin de plomberie',
        metier: 'Plomberie',
        address: '123 Rue de la Paix',
        city: 'Paris',
        postalCode: '75001',
        lat: 48.8566,
        lon: 2.3522,
      );

      expect(result['id'], 'offer-789');
      expect(result['metier'], 'Plomberie');

      verify(() => mockClient.postJson(
        '/api/chantier-offres',
        any(),
      )).called(1);
    });
  });
}
