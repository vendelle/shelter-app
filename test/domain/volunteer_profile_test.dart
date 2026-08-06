import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_app/features/volunteer_detail/domain/volunteer_profile.dart';

VolunteerProfile _profile({
  List<Map<String, dynamic>> visits = const [],
  List<Map<String, dynamic>> dogs = const [],
}) {
  return VolunteerProfile.fromJson({
    'volunteer': {
      'id': 1,
      'first_name': 'Anna',
      'last_name': 'Kowalska',
      'archived': false,
      'role': 'senior',
    },
    'visits': visits,
    'dogs': dogs,
  });
}

void main() {
  group('VolunteerVisit', () {
    test('fromJson strips a time component from the date', () {
      final v = VolunteerVisit.fromJson(
          {'walk_date': '2026-08-04T00:00:00.000Z', 'walk_count': 2});
      expect(v.walkDate, '2026-08-04');
      expect(v.walkCount, 2);
    });
  });

  group('VolunteerDogWalkCount', () {
    test('fromJson parses fields', () {
      final d = VolunteerDogWalkCount.fromJson(
          {'dog_id': 5, 'dog_name': 'Rex', 'walk_count': 7});
      expect(d.dogId, 5);
      expect(d.dogName, 'Rex');
      expect(d.walkCount, 7);
    });
  });

  group('VolunteerProfile', () {
    test('fromJson parses volunteer, visits, and dogs', () {
      final profile = _profile(
        visits: [
          {'walk_date': '2026-08-04', 'walk_count': 2},
        ],
        dogs: [
          {'dog_id': 1, 'dog_name': 'Rex', 'walk_count': 12},
        ],
      );

      expect(profile.volunteer.fullName, 'Anna Kowalska');
      expect(profile.visits, hasLength(1));
      expect(profile.dogs, hasLength(1));
    });

    test('totals and averages are zero-guarded with no visits', () {
      final profile = _profile();

      expect(profile.totalVisits, 0);
      expect(profile.totalWalks, 0);
      expect(profile.avgVisitsPerMonth, 0);
      expect(profile.avgWalksPerVisit, 0);
      expect(profile.visitsByMonth, isEmpty);
    });

    test('averages are computed over a fixed 6-month window', () {
      final profile = _profile(visits: [
        {'walk_date': '2026-08-04', 'walk_count': 2},
        {'walk_date': '2026-08-01', 'walk_count': 1},
        {'walk_date': '2026-07-15', 'walk_count': 3},
      ]);

      expect(profile.totalVisits, 3);
      expect(profile.totalWalks, 6);
      expect(profile.avgVisitsPerMonth, closeTo(3 / 6, 0.0001));
      expect(profile.avgWalksPerVisit, closeTo(6 / 3, 0.0001));
    });

    test('visitsByMonth groups by calendar month, most recent first', () {
      final profile = _profile(visits: [
        {'walk_date': '2026-08-04', 'walk_count': 2},
        {'walk_date': '2026-08-01', 'walk_count': 1},
        {'walk_date': '2026-07-15', 'walk_count': 3},
        {'walk_date': '2025-12-20', 'walk_count': 1},
      ]);

      final months = profile.visitsByMonth;
      expect(months, hasLength(3));

      expect(months[0].year, 2026);
      expect(months[0].month, 8);
      expect(months[0].visits, hasLength(2));
      expect(months[0].totalWalks, 3);

      expect(months[1].year, 2026);
      expect(months[1].month, 7);
      expect(months[1].totalWalks, 3);

      expect(months[2].year, 2025);
      expect(months[2].month, 12);
      expect(months[2].totalWalks, 1);
    });
  });
}
