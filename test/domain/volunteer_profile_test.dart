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

String _fmt(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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

    test('avgWalksPerVisit is total walks divided by total visits', () {
      final profile = _profile(visits: [
        {'walk_date': '2026-08-04', 'walk_count': 2},
        {'walk_date': '2026-08-01', 'walk_count': 1},
        {'walk_date': '2026-07-15', 'walk_count': 3},
      ]);

      expect(profile.totalVisits, 3);
      expect(profile.totalWalks, 6);
      expect(profile.avgWalksPerVisit, closeTo(6 / 3, 0.0001));
    });

    test(
        'avgVisitsPerMonth divides by months since the earliest visit for '
        'a recent joiner, not a flat 6', () {
      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month, 1);
      final lastMonth = DateTime(now.year, now.month - 1, 15);

      // Earliest visit was last month, so this volunteer looks 2 months
      // active (this month + last), not the full 6-month window.
      final profile = _profile(visits: [
        {'walk_date': _fmt(thisMonth), 'walk_count': 2},
        {
          'walk_date': _fmt(DateTime(thisMonth.year, thisMonth.month, 2)),
          'walk_count': 1,
        },
        {'walk_date': _fmt(lastMonth), 'walk_count': 1},
      ]);

      expect(profile.totalVisits, 3);
      expect(profile.avgVisitsPerMonth, closeTo(3 / 2, 0.0001));
    });

    test('avgVisitsPerMonth caps the months-active denominator at 6', () {
      final now = DateTime.now();
      final eightMonthsAgo = DateTime(now.year, now.month - 8, 10);

      final profile = _profile(visits: [
        {'walk_date': _fmt(eightMonthsAgo), 'walk_count': 1},
        {'walk_date': _fmt(now), 'walk_count': 1},
      ]);

      expect(profile.totalVisits, 2);
      expect(profile.avgVisitsPerMonth, closeTo(2 / 6, 0.0001));
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
      expect(months[0].visitCount, 2);
      expect(months[0].totalWalks, 3);

      expect(months[1].year, 2026);
      expect(months[1].month, 7);
      expect(months[1].visitCount, 1);
      expect(months[1].totalWalks, 3);

      expect(months[2].year, 2025);
      expect(months[2].month, 12);
      expect(months[2].visitCount, 1);
      expect(months[2].totalWalks, 1);
    });
  });
}
