import 'package:shelter_app/features/dog_detail/data/dog_detail_repository.dart';
import 'package:shelter_app/features/dog_detail/domain/dog_relationship.dart';
import 'package:shelter_app/features/dog_detail/domain/dog_walk_history.dart';
import 'package:shelter_app/features/dog_detail/domain/shelter_profile.dart';
import 'package:shelter_app/features/dog_detail/domain/walk_partner.dart';

/// In-memory [DogDetailRepository]: empty lists, and [profile] for the
/// shelter-website calls.
class FakeDogDetailRepository implements DogDetailRepository {
  FakeDogDetailRepository({required this.profile, this.afterRefresh});

  ShelterProfile profile;

  /// What "Odśwież teraz" returns; defaults to [profile].
  ShelterProfile? afterRefresh;

  int refreshCalls = 0;
  final resolved = <bool>[];

  @override
  Future<ShelterProfile> getShelterProfile(int dogId) async => profile;

  @override
  Future<ShelterProfile> refreshShelterProfile(int dogId) async {
    refreshCalls++;
    return profile = afterRefresh ?? profile;
  }

  @override
  Future<ShelterProfile> resolveLocationSuggestion(int dogId,
      {required bool accept}) async {
    resolved.add(accept);
    return profile = ShelterProfile(
      dogId: dogId,
      found: profile.found,
      location: profile.location,
      kennel: accept ? profile.locationSuggestion?.kennel : profile.kennel,
      region: profile.region,
    );
  }

  @override
  Future<Set<int>> getLocationSuggestionDogIds() async => {};

  @override
  Future<Map<int, String>> getDogPhotoUrls() async => {};

  @override
  Future<List<DogRelationship>> getRelationships(int dogId) async => [];

  @override
  Future<List<DogRelationship>> getAllRelationships() async => [];

  @override
  Future<void> upsertRelationship({
    required int dogId1,
    required int dogId2,
    required DogRelationshipLevel level,
    String? notes,
  }) async {}

  @override
  Future<void> deleteRelationship(int dogId1, int dogId2) async {}

  @override
  Future<List<DogWalkHistory>> getWalkHistory(int dogId) async => [];

  @override
  Future<List<WalkPartner>> getWalkPartners(int dogId) async => [];
}
