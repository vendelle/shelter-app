import '../../../core/api/api_client.dart';
import '../domain/volunteer_profile.dart';

abstract class VolunteerDetailRepository {
  Future<VolunteerProfile> getProfile(int volunteerId);
}

class ApiVolunteerDetailRepository implements VolunteerDetailRepository {
  ApiVolunteerDetailRepository(this._api);
  final ApiClient _api;

  @override
  Future<VolunteerProfile> getProfile(int volunteerId) async {
    final data = await _api.get('/api/volunteers',
        queryParams: {'id': volunteerId.toString()});
    return VolunteerProfile.fromJson(data as Map<String, dynamic>);
  }
}
