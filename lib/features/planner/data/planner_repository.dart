import '../../shared/domain/volunteer.dart';
import '../domain/planner_dog.dart';
import '../domain/volunteer_assignment.dart';

abstract class PlannerRepository {
  /// Loads assignments for a given date.
  Future<List<VolunteerAssignment>> getAssignments(DateTime date);

  /// Saves all assignments for a given date (replaces existing).
  Future<void> saveAssignments(
      DateTime date, List<VolunteerAssignment> assignments);

  /// Returns all available volunteers.
  Future<List<Volunteer>> getVolunteers();

  /// Returns all available (non-archived) dogs with walk stats and familiarity
  /// for the given volunteer.
  Future<List<PlannerDog>> getDogsForVolunteer(int volunteerId);

  /// Returns the total number of available (non-archived) dogs.
  Future<int> getDogCount();
}

class MockPlannerRepository implements PlannerRepository {
  // Simulated familiarity data: {volunteerId: {dogId: familiarity}}
  static final Map<int, Map<int, DogFamiliarityLevel>> _familiarityData = {
    1: {
      1: DogFamiliarityLevel.good,
      3: DogFamiliarityLevel.good,
      5: DogFamiliarityLevel.caution,
      8: DogFamiliarityLevel.neutral,
    },
    2: {
      2: DogFamiliarityLevel.good,
      4: DogFamiliarityLevel.good,
      7: DogFamiliarityLevel.caution,
    },
    3: {
      1: DogFamiliarityLevel.neutral,
      6: DogFamiliarityLevel.good,
      9: DogFamiliarityLevel.good,
    },
    4: {
      3: DogFamiliarityLevel.good,
      10: DogFamiliarityLevel.good,
      12: DogFamiliarityLevel.caution,
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
