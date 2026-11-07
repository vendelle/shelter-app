import '../../../core/api/api_client.dart';
import '../domain/dog_relationship.dart';
import '../domain/dog_walk_history.dart';
import '../domain/shelter_profile.dart';
import '../domain/walk_partner.dart';

abstract class DogDetailRepository {
  Future<List<DogRelationship>> getRelationships(int dogId);
  Future<List<DogRelationship>> getAllRelationships();
  Future<void> upsertRelationship({
    required int dogId1,
    required int dogId2,
    required DogRelationshipLevel level,
    String? notes,
  });
  Future<void> deleteRelationship(int dogId1, int dogId2);
  Future<List<DogWalkHistory>> getWalkHistory(int dogId);
  Future<List<WalkPartner>> getWalkPartners(int dogId);

  /// The shelter website's data, as stored (fetched on first view).
  Future<ShelterProfile> getShelterProfile(int dogId);

  /// Fetches from the website again — a no-op within the 5-minute cooldown.
  Future<ShelterProfile> refreshShelterProfile(int dogId);

  /// Admin: take ([accept]) or dismiss the website's kennel/region.
  Future<ShelterProfile> resolveLocationSuggestion(int dogId,
      {required bool accept});

  /// IDs of active dogs whose website kennel/region differs from ours.
  Future<Set<int>> getLocationSuggestionDogIds();

  /// Photo URL per active dog id, for the dogs that have one.
  Future<Map<int, String>> getDogPhotoUrls();
}

class ApiDogDetailRepository implements DogDetailRepository {
  ApiDogDetailRepository(this._api);
  final ApiClient _api;

  @override
  Future<List<DogRelationship>> getRelationships(int dogId) async {
    final data = await _api.get('/api/dog-relationships',
        queryParams: {'dog_id': dogId.toString()}) as List;
    return data
        .map((j) => DogRelationship.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<DogRelationship>> getAllRelationships() async {
    final data = await _api.get('/api/dog-relationships') as List;
    return data
        .map((j) => DogRelationship.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> upsertRelationship({
    required int dogId1,
    required int dogId2,
    required DogRelationshipLevel level,
    String? notes,
  }) async {
    // The PUT response only carries dog_id_1/dog_id_2/level/notes (no dog
    // names — see api/dog-relationships.ts), unlike the GET endpoints which
    // join in names for display. Parsing it as a DogRelationship used to
    // throw on the missing name fields; callers never used the return
    // value anyway (they invalidate providers and refetch via GET), so
    // there's nothing to parse here.
    await _api.put('/api/dog-relationships', body: {
      'dog_id_1': dogId1,
      'dog_id_2': dogId2,
      'level': relationshipLevelToString(level),
      'notes': notes,
    });
  }

  @override
  Future<void> deleteRelationship(int dogId1, int dogId2) async {
    await _api.delete('/api/dog-relationships', queryParams: {
      'dog_id_1': dogId1.toString(),
      'dog_id_2': dogId2.toString(),
    });
  }

  @override
  Future<List<DogWalkHistory>> getWalkHistory(int dogId) async {
    final data = await _api.get('/api/dog-history',
        queryParams: {'dog_id': dogId.toString()}) as List;
    return data
        .map((j) => DogWalkHistory.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<WalkPartner>> getWalkPartners(int dogId) async {
    final data = await _api.get('/api/walk-partners',
        queryParams: {'dog_id': dogId.toString()}) as List;
    return data
        .map((j) => WalkPartner.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ShelterProfile> getShelterProfile(int dogId) async {
    final data =
        await _api.get('/api/dogs', queryParams: {'shelter': '$dogId'});
    return ShelterProfile.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<ShelterProfile> refreshShelterProfile(int dogId) async {
    final data =
        await _api.post('/api/dogs', queryParams: {'shelter': '$dogId'});
    return ShelterProfile.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<ShelterProfile> resolveLocationSuggestion(int dogId,
      {required bool accept}) async {
    final data = await _api.put(
      '/api/dogs',
      queryParams: {'shelter': '$dogId'},
      body: {'action': accept ? 'accept' : 'ignore'},
    );
    return ShelterProfile.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<Set<int>> getLocationSuggestionDogIds() async {
    final data = await _api.get('/api/dogs',
        queryParams: {'shelter': 'suggestions'}) as List;
    return {
      for (final s in data) (s as Map<String, dynamic>)['dog_id'] as int,
    };
  }

  @override
  Future<Map<int, String>> getDogPhotoUrls() async {
    final data =
        await _api.get('/api/dogs', queryParams: {'shelter': 'thumbs'}) as List;
    return {
      for (final p in data)
        (p as Map<String, dynamic>)['dog_id'] as int: p['photo_url'] as String,
    };
  }
}
