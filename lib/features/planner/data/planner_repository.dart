import '../../../core/api/api_client.dart';
import '../../shared/domain/volunteer.dart';
import '../domain/planner_dog.dart';
import '../domain/volunteer_assignment.dart';

abstract class PlannerRepository {
  Future<List<VolunteerAssignment>> getAssignments(DateTime date);
  Future<void> saveAssignments(
      DateTime date, List<VolunteerAssignment> assignments);
  Future<List<Volunteer>> getVolunteers();
  Future<List<PlannerDog>> getDogsForVolunteer(int volunteerId);
  Future<int> getDogCount();
}

// ---------------------------------------------------------------------------
// Real API repository
// ---------------------------------------------------------------------------

class ApiPlannerRepository implements PlannerRepository {
  ApiPlannerRepository(this._api);
  final ApiClient _api;

  @override
  Future<List<VolunteerAssignment>> getAssignments(DateTime date) async {
    final dateStr = _dateKey(date);
    final data = await _api.get('/api/dayplan', queryParams: {'date': dateStr}) as List;

    // Group rows by volunteer_id
    final Map<int, VolunteerAssignment> byVolunteer = {};
    for (final row in data) {
      final m = row as Map<String, dynamic>;
      final volunteerId = m['volunteer_id'] as int?;
      if (volunteerId == null) continue;

      byVolunteer.putIfAbsent(
        volunteerId,
        () => VolunteerAssignment(
          volunteerId: volunteerId,
          volunteerName: m['volunteer_name'] as String? ?? 'Unknown',
          note: m['volunteer_note'] as String?,
        ),
      );

      byVolunteer[volunteerId]!.dogs.add(DogEntry(
        dogId: m['dog_id'] as int,
        dogName: m['dog_name'] as String? ?? 'Unknown',
        shelterId: m['shelterid'] as String?,
        kennel: m['kennel'] as String?,
        region: m['region'] as String?,
        groupIndex: m['group_index'] as int?,
        note: m['dog_note'] as String?,
      ));
    }

    return byVolunteer.values.toList();
  }

  @override
  Future<void> saveAssignments(
      DateTime date, List<VolunteerAssignment> assignments) async {
    final walks = <Map<String, dynamic>>[];
    for (final a in assignments) {
      for (final d in a.dogs) {
        walks.add({
          'dog_id': d.dogId,
          'volunteer_id': a.volunteerId,
          'dog_note': d.note,
          'group_index': d.groupIndex,
        });
      }
    }

    final volunteerNotes = assignments
        .where((a) => a.note != null && a.note!.isNotEmpty)
        .map((a) => {
              'volunteer_id': a.volunteerId,
              'note': a.note,
            })
        .toList();

    await _api.post('/api/dayplan', body: {
      'walk_date': _dateKey(date),
      'walks': walks,
      'volunteer_notes': volunteerNotes,
    });
  }

  @override
  Future<List<Volunteer>> getVolunteers() async {
    final data = await _api.get('/api/volunteers') as List;
    return data.map((json) => Volunteer.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<PlannerDog>> getDogsForVolunteer(int volunteerId) async {
    // Fetch dogs with walk stats
    final dogsData = await _api.get('/api/dogs-walks') as List;

    // Try to fetch familiarity (may not be deployed yet)
    final familiarityMap = <int, DogFamiliarityLevel>{};
    try {
      final familiarityData = await _api.get('/api/familiarity',
          queryParams: {'volunteer_id': volunteerId.toString()}) as List;
      for (final entry in familiarityData) {
        final m = entry as Map<String, dynamic>;
        final dogId = m['dog_id'] as int;
        final level = switch (m['level'] as String) {
          'good' => DogFamiliarityLevel.good,
          'difficult' => DogFamiliarityLevel.difficult,
          'never' => DogFamiliarityLevel.never,
          _ => DogFamiliarityLevel.unknown,
        };
        familiarityMap[dogId] = level;
      }
    } catch (_) {
      // Familiarity endpoint not available yet — continue without it
    }

    return dogsData.map((json) {
      final m = json as Map<String, dynamic>;
      final dogId = m['id'] as int;
      return PlannerDog(
        id: dogId,
        name: m['name'] as String,
        shelterId: m['shelterid'] as String? ?? '',
        kennel: m['kennel'] as String? ?? '',
        region: m['region'] as String?,
        thisWeekWalks: m['this_week_walks'] as int? ?? 0,
        lastWeekWalks: m['last_week_walks'] as int? ?? 0,
        familiarity: familiarityMap[dogId] ?? DogFamiliarityLevel.unknown,
      );
    }).toList();
  }

  @override
  Future<int> getDogCount() async {
    final data = await _api.get('/api/dogs') as List;
    return data.length;
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class MockPlannerRepository implements PlannerRepository {
  // Simulated familiarity data: {volunteerId: {dogId: familiarity}}
  static final Map<int, Map<int, DogFamiliarityLevel>> _familiarityData = {
    1: {
      1: DogFamiliarityLevel.good,
      3: DogFamiliarityLevel.good,
      5: DogFamiliarityLevel.never,
      8: DogFamiliarityLevel.difficult,
    },
    2: {
      2: DogFamiliarityLevel.good,
      4: DogFamiliarityLevel.good,
      7: DogFamiliarityLevel.never,
    },
    3: {
      1: DogFamiliarityLevel.difficult,
      6: DogFamiliarityLevel.good,
      9: DogFamiliarityLevel.good,
    },
    4: {
      3: DogFamiliarityLevel.good,
      10: DogFamiliarityLevel.good,
      12: DogFamiliarityLevel.never,
    },
  };

  static const _dogs = [
    _MockDog(1, 'Burek', 'A1', 0, 3),
    _MockDog(2, 'Luna', 'A2', 1, 4),
    _MockDog(3, 'Reksio', 'A3', 5, 3),
    _MockDog(4, 'Misia', 'B1', 0, 0),
    _MockDog(5, 'Tofik', 'B2', 2, 2),
    _MockDog(6, 'Czarek', 'B3', 3, 5),
    _MockDog(7, 'Azor', 'C1', 0, 1),
    _MockDog(8, 'Bela', 'C2', 4, 4),
    _MockDog(9, 'Rocky', 'C3', 1, 3),
    _MockDog(10, 'Figa', 'D1', 2, 1),
    _MockDog(11, 'Max', 'D2', 6, 5),
    _MockDog(12, 'Kora', 'D3', 0, 2),
    _MockDog(13, 'Puszek', 'E1', 3, 3),
    _MockDog(14, 'Łata', 'E2', 1, 0),
  ];

  static const _volunteers = [
    Volunteer(id: 1, firstName: 'Anna', lastName: 'Kowalska'),
    Volunteer(id: 2, firstName: 'Piotr', lastName: 'Nowak'),
    Volunteer(id: 3, firstName: 'Kasia', lastName: 'Wiśniewska'),
    Volunteer(id: 4, firstName: 'Tomek', lastName: 'Zieliński'),
    Volunteer(id: 5, firstName: 'Magda', lastName: 'Wójcik'),
    Volunteer(id: 6, firstName: 'Bartek', lastName: 'Kamiński'),
    Volunteer(id: 7, firstName: 'Ola', lastName: 'Lewandowska'),
    Volunteer(id: 8, firstName: 'Michał', lastName: 'Szymański'),
  ];

  // Simulate saved state per date
  final Map<String, List<VolunteerAssignment>> _savedAssignments = {};

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  Future<List<VolunteerAssignment>> getAssignments(DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final key = _dateKey(date);
    return _savedAssignments[key]
            ?.map((a) => a.copyWith())
            .toList() ??
        [];
  }

  @override
  Future<void> saveAssignments(
      DateTime date, List<VolunteerAssignment> assignments) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final key = _dateKey(date);
    _savedAssignments[key] =
        assignments.map((a) => a.copyWith()).toList();
  }

  @override
  Future<List<Volunteer>> getVolunteers() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _volunteers;
  }

  @override
  Future<List<PlannerDog>> getDogsForVolunteer(int volunteerId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final familiarityMap = _familiarityData[volunteerId] ?? {};

    return _dogs.map((d) {
      return PlannerDog(
        id: d.id,
        name: d.name,
        kennel: d.kennel,
        thisWeekWalks: d.thisWeekWalks,
        lastWeekWalks: d.lastWeekWalks,
        familiarity: familiarityMap[d.id] ?? DogFamiliarityLevel.unknown,
      );
    }).toList();
  }

  @override
  Future<int> getDogCount() async => _dogs.length;
}

class _MockDog {
  final int id;
  final String name;
  final String kennel;
  final int thisWeekWalks;
  final int lastWeekWalks;

  const _MockDog(
      this.id, this.name, this.kennel, this.thisWeekWalks, this.lastWeekWalks);
}
