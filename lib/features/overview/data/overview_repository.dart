import '../../../core/api/api_client.dart';
import '../domain/dog_walk_summary.dart';

abstract class OverviewRepository {
  Future<List<DogWalkSummary>> getDogWalkSummaries();
}

/// Fetches real walk data from the Vercel API.
class ApiOverviewRepository implements OverviewRepository {
  ApiOverviewRepository(this._api);
  final ApiClient _api;

  @override
  Future<List<DogWalkSummary>> getDogWalkSummaries() async {
    final data = await _api.get('/api/dogs-walks') as List;
    return data.map((json) {
      final m = json as Map<String, dynamic>;
      return DogWalkSummary(
        dogId: m['id'] as int,
        dogName: m['name'] as String,
        shelterId: m['shelterid'] as String? ?? '',
        kennel: m['kennel'] as String? ?? '',
        region: m['region'] as String?,
        thisWeekWalks: m['this_week_walks'] as int? ?? 0,
        lastWeekWalks: m['last_week_walks'] as int? ?? 0,
      );
    }).toList();
  }
}

/// Mock data for local development.
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
