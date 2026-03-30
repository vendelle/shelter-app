import '../domain/dog_walk_summary.dart';

abstract class OverviewRepository {
  Future<List<DogWalkSummary>> getDogWalkSummaries();
}

/// Mock data for local development.
/// Replace with [ApiOverviewRepository] when connecting to the real API.
class MockOverviewRepository implements OverviewRepository {
  @override
  Future<List<DogWalkSummary>> getDogWalkSummaries() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));

    return const [
      DogWalkSummary(dogId: 1, dogName: 'Burek', kennel: 'A1', thisWeekWalks: 0, lastWeekWalks: 3),
      DogWalkSummary(dogId: 2, dogName: 'Luna', kennel: 'A2', thisWeekWalks: 1, lastWeekWalks: 4),
      DogWalkSummary(dogId: 3, dogName: 'Reksio', kennel: 'A3', thisWeekWalks: 5, lastWeekWalks: 3),
      DogWalkSummary(dogId: 4, dogName: 'Misia', kennel: 'B1', thisWeekWalks: 0, lastWeekWalks: 0),
      DogWalkSummary(dogId: 5, dogName: 'Tofik', kennel: 'B2', thisWeekWalks: 2, lastWeekWalks: 2),
      DogWalkSummary(dogId: 6, dogName: 'Czarek', kennel: 'B3', thisWeekWalks: 3, lastWeekWalks: 5),
      DogWalkSummary(dogId: 7, dogName: 'Azor', kennel: 'C1', thisWeekWalks: 0, lastWeekWalks: 1),
      DogWalkSummary(dogId: 8, dogName: 'Bela', kennel: 'C2', thisWeekWalks: 4, lastWeekWalks: 4),
      DogWalkSummary(dogId: 9, dogName: 'Rocky', kennel: 'C3', thisWeekWalks: 1, lastWeekWalks: 3),
      DogWalkSummary(dogId: 10, dogName: 'Figa', kennel: 'D1', thisWeekWalks: 2, lastWeekWalks: 1),
      DogWalkSummary(dogId: 11, dogName: 'Max', kennel: 'D2', thisWeekWalks: 6, lastWeekWalks: 5),
      DogWalkSummary(dogId: 12, dogName: 'Kora', kennel: 'D3', thisWeekWalks: 0, lastWeekWalks: 2),
      DogWalkSummary(dogId: 13, dogName: 'Puszek', kennel: 'E1', thisWeekWalks: 3, lastWeekWalks: 3),
      DogWalkSummary(dogId: 14, dogName: 'Łata', kennel: 'E2', thisWeekWalks: 1, lastWeekWalks: 0),
    ];
  }
}
