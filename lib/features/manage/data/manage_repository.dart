import '../../../core/api/api_client.dart';
import '../../shared/domain/dog.dart';
import '../../shared/domain/volunteer.dart';
import '../../planner/domain/planner_dog.dart';

class FamiliarityEntry {
  final int volunteerId;
  final int dogId;
  final DogFamiliarityLevel level;

  const FamiliarityEntry({
    required this.volunteerId,
    required this.dogId,
    required this.level,
  });

  factory FamiliarityEntry.fromJson(Map<String, dynamic> json) {
    return FamiliarityEntry(
      volunteerId: json['volunteer_id'] as int,
      dogId: json['dog_id'] as int,
      level: _parseFamiliarity(json['level'] as String),
    );
  }

  static DogFamiliarityLevel _parseFamiliarity(String level) {
    return switch (level) {
      'good' => DogFamiliarityLevel.good,
      'difficult' => DogFamiliarityLevel.difficult,
      'never' => DogFamiliarityLevel.never,
      _ => DogFamiliarityLevel.unknown,
    };
  }

  static String familiarityToString(DogFamiliarityLevel level) {
    return switch (level) {
      DogFamiliarityLevel.good => 'good',
      DogFamiliarityLevel.difficult => 'difficult',
      DogFamiliarityLevel.never => 'never',
      DogFamiliarityLevel.unknown => 'unknown',
    };
  }
}

class ManageRepository {
  ManageRepository(this._api);
  final ApiClient _api;

  // --- Dogs ---

  Future<List<Dog>> getDogs({bool onlyArchived = false}) async {
    final params = <String, String>{};
    if (onlyArchived) params['only_archived'] = 'true';
    final data = await _api.get('/api/dogs', queryParams: params) as List;
    return data.map((json) => Dog.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Dog> createDog({
    required String name,
    required String shelterId,
    required String kennel,
  }) async {
    final data = await _api.post('/api/dogs', body: {
      'name': name,
      'shelterid': shelterId,
      'kennel': kennel,
    });
    return Dog.fromJson(data as Map<String, dynamic>);
  }

  Future<Dog> updateDog({
    required int id,
    String? name,
    String? shelterId,
    String? kennel,
  }) async {
    final body = <String, dynamic>{'id': id};
    if (name != null) body['name'] = name;
    if (shelterId != null) body['shelterid'] = shelterId;
    if (kennel != null) body['kennel'] = kennel;
    final data = await _api.patch('/api/dogs', body: body);
    return Dog.fromJson(data as Map<String, dynamic>);
  }

  Future<Dog> archiveDog(int id, {bool archive = true}) async {
    final data = await _api.put('/api/dogs', queryParams: {
      'id': id.toString(),
      'archive': archive.toString(),
    });
    return Dog.fromJson(data as Map<String, dynamic>);
  }

  // --- Volunteers ---

  Future<List<Volunteer>> getVolunteers({bool onlyArchived = false}) async {
    final params = <String, String>{};
    if (onlyArchived) params['only_archived'] = 'true';
    final data = await _api.get('/api/volunteers', queryParams: params) as List;
    return data.map((json) => Volunteer.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Volunteer> createVolunteer({
    required String firstName,
    required String lastName,
    VolunteerRole role = VolunteerRole.newHelper,
  }) async {
    final data = await _api.post('/api/volunteers', body: {
      'first_name': firstName,
      'last_name': lastName,
      'role': role.toJson(),
    });
    return Volunteer.fromJson(data as Map<String, dynamic>);
  }

  Future<Volunteer> updateVolunteer({
    required int id,
    String? firstName,
    String? lastName,
    VolunteerRole? role,
  }) async {
    final body = <String, dynamic>{'id': id};
    if (firstName != null) body['first_name'] = firstName;
    if (lastName != null) body['last_name'] = lastName;
    if (role != null) body['role'] = role.toJson();
    final data = await _api.patch('/api/volunteers', body: body);
    return Volunteer.fromJson(data as Map<String, dynamic>);
  }

  Future<Volunteer> archiveVolunteer(int id, {bool archive = true}) async {
    final data = await _api.put('/api/volunteers', queryParams: {
      'id': id.toString(),
      'archive': archive.toString(),
    });
    return Volunteer.fromJson(data as Map<String, dynamic>);
  }

  // --- Familiarity ---

  Future<List<FamiliarityEntry>> getFamiliarity(int volunteerId) async {
    final data = await _api.get('/api/familiarity', queryParams: {
      'volunteer_id': volunteerId.toString(),
    }) as List;
    return data.map((json) => FamiliarityEntry.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<void> setFamiliarity({
    required int volunteerId,
    required int dogId,
    required DogFamiliarityLevel level,
  }) async {
    await _api.put('/api/familiarity', body: {
      'volunteer_id': volunteerId,
      'dog_id': dogId,
      'level': FamiliarityEntry.familiarityToString(level),
    });
  }

  Future<void> removeFamiliarity({
    required int volunteerId,
    required int dogId,
  }) async {
    await _api.delete('/api/familiarity', queryParams: {
      'volunteer_id': volunteerId.toString(),
      'dog_id': dogId.toString(),
    });
  }
}
