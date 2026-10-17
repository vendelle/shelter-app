import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_app/features/dog_detail/domain/shelter_profile.dart';

void main() {
  group('ShelterProfile.fromJson', () {
    test('reads the API shape', () {
      final profile = ShelterProfile.fromJson({
        'dog_id': 12,
        'kennel': '412',
        'region': 'R12',
        'url': 'https://napaluchu.waw.pl/animal/0573-26p/',
        'found': true,
        'status': 'Do adopcji',
        'photo_url': 'https://images.example/1.jpg',
        'birth_date': '2020-12-19',
        'weight_kg': 24,
        'neutered': true,
        'arrival_date': '2026-06-20',
        'arrival_reason': 'zwrot z adopcji',
        'departure_date': null,
        'location': '430 R12 (domek)',
        'fetched_at': '2026-10-17T08:00:00.000Z',
        'location_suggestion': {'kennel': '430', 'region': 'R12'},
      });

      expect(profile.found, isTrue);
      expect(profile.weightKg, 24.0);
      expect(profile.birthDate, DateTime(2020, 12, 19));
      expect(profile.fetchedAt, DateTime.utc(2026, 10, 17, 8).toLocal());
      expect(profile.locationSuggestion?.kennel, '430');
      expect(profile.refreshFailed, isFalse);
    });

    test('handles a dog the website does not have', () {
      final profile = ShelterProfile.fromJson({
        'dog_id': 1,
        'url': null,
        'found': false,
        'fetched_at': null,
        'location_suggestion': null,
        'refresh_failed': true,
      });
      expect(profile.found, isFalse);
      expect(profile.fetchedAt, isNull);
      expect(profile.refreshFailed, isTrue);
    });
  });

  test('canRefresh enforces the 5-minute cooldown', () {
    final now = DateTime(2026, 10, 17, 12);
    ShelterProfile fetched(Duration ago) =>
        ShelterProfile(dogId: 1, fetchedAt: now.subtract(ago));

    expect(fetched(const Duration(minutes: 4)).canRefresh(now: now), isFalse);
    expect(fetched(const Duration(minutes: 5)).canRefresh(now: now), isTrue);
    expect(const ShelterProfile(dogId: 1).canRefresh(now: now), isTrue);
  });

  group('ageOn', () {
    ShelterProfile born(DateTime date) =>
        ShelterProfile(dogId: 1, birthDate: date);

    test('counts whole years and months', () {
      expect(born(DateTime(2020, 12, 19)).ageOn(DateTime(2026, 10, 17)),
          (years: 5, months: 9));
    });

    test('a month is complete only on its day', () {
      expect(born(DateTime(2026, 8, 20)).ageOn(DateTime(2026, 10, 19)),
          (years: 0, months: 1));
      expect(born(DateTime(2026, 8, 20)).ageOn(DateTime(2026, 10, 20)),
          (years: 0, months: 2));
    });

    test('is null without a (sensible) birth date', () {
      expect(const ShelterProfile(dogId: 1).ageOn(DateTime(2026)), isNull);
      expect(born(DateTime(2030)).ageOn(DateTime(2026)), isNull);
    });
  });
}
