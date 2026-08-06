import '../../shared/domain/volunteer.dart';

/// One date on which the volunteer walked at least one dog, with how many
/// walks were logged that day.
class VolunteerVisit {
  final String walkDate; // yyyy-MM-dd
  final int walkCount;

  const VolunteerVisit({required this.walkDate, required this.walkCount});

  factory VolunteerVisit.fromJson(Map<String, dynamic> json) {
    final rawDate = json['walk_date'] as String;
    return VolunteerVisit(
      walkDate: rawDate.contains('T') ? rawDate.substring(0, 10) : rawDate,
      walkCount: json['walk_count'] as int,
    );
  }

  DateTime get date => DateTime.parse(walkDate);
}

/// How many times this volunteer walked a specific (active) dog in the
/// tracked window. Dogs never walked by this volunteer are included with
/// [walkCount] 0.
class VolunteerDogWalkCount {
  final int dogId;
  final String dogName;
  final int walkCount;

  const VolunteerDogWalkCount({
    required this.dogId,
    required this.dogName,
    required this.walkCount,
  });

  factory VolunteerDogWalkCount.fromJson(Map<String, dynamic> json) {
    return VolunteerDogWalkCount(
      dogId: json['dog_id'] as int,
      dogName: json['dog_name'] as String,
      walkCount: json['walk_count'] as int,
    );
  }
}

/// Visits that fall in a single calendar month.
class MonthlyVisits {
  final int year;
  final int month; // 1-12
  final List<VolunteerVisit> visits;

  const MonthlyVisits({
    required this.year,
    required this.month,
    required this.visits,
  });

  /// Number of visits (distinct days) in this month.
  int get visitCount => visits.length;

  int get totalWalks => visits.fold(0, (sum, v) => sum + v.walkCount);
}

/// Aggregate stats behind the volunteer profile screen: visits over the
/// past 6 months and per-dog walk counts over the past 90 days.
class VolunteerProfile {
  static const monthsTracked = 6;

  final Volunteer volunteer;
  final List<VolunteerVisit> visits;
  final List<VolunteerDogWalkCount> dogs;

  const VolunteerProfile({
    required this.volunteer,
    required this.visits,
    required this.dogs,
  });

  factory VolunteerProfile.fromJson(Map<String, dynamic> json) {
    return VolunteerProfile(
      volunteer:
          Volunteer.fromJson(json['volunteer'] as Map<String, dynamic>),
      visits: (json['visits'] as List)
          .map((v) => VolunteerVisit.fromJson(v as Map<String, dynamic>))
          .toList(),
      dogs: (json['dogs'] as List)
          .map((d) => VolunteerDogWalkCount.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }

  int get totalVisits => visits.length;

  int get totalWalks => visits.fold(0, (sum, v) => sum + v.walkCount);

  /// Months to average visits over. There's no explicit join date tracked
  /// yet, so this approximates "months active" from the earliest visit in
  /// the 6-month window — if they had no visit before that, assume they
  /// just joined then. Without this, a volunteer who started last month
  /// would have their average diluted by a flat 6-month divisor and look
  /// far less active than they are. Capped at [monthsTracked] so it's a
  /// no-op for anyone active the whole window.
  int get _monthsActive {
    if (visits.isEmpty) return monthsTracked;
    final earliest =
        visits.map((v) => v.date).reduce((a, b) => a.isBefore(b) ? a : b);
    final now = DateTime.now();
    final months =
        (now.year - earliest.year) * 12 + (now.month - earliest.month) + 1;
    return months.clamp(1, monthsTracked);
  }

  double get avgVisitsPerMonth => totalVisits / _monthsActive;

  double get avgWalksPerVisit =>
      totalVisits == 0 ? 0 : totalWalks / totalVisits;

  /// Visits grouped by calendar month, most recent month first — used for
  /// the "January 4, February 2" style breakdown.
  List<MonthlyVisits> get visitsByMonth {
    final groups = <String, List<VolunteerVisit>>{};
    for (final visit in visits) {
      final d = visit.date;
      final key = '${d.year}-${d.month}';
      groups.putIfAbsent(key, () => []).add(visit);
    }
    final months = groups.entries.map((entry) {
      final parts = entry.key.split('-');
      return MonthlyVisits(
        year: int.parse(parts[0]),
        month: int.parse(parts[1]),
        visits: entry.value,
      );
    }).toList();
    months.sort((a, b) {
      final cmp = b.year.compareTo(a.year);
      return cmp != 0 ? cmp : b.month.compareTo(a.month);
    });
    return months;
  }
}
