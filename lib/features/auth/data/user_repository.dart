import '../../../core/api/api_client.dart';
import '../domain/app_user.dart';
import '../domain/user_account.dart';

/// Accounts API (`/api/users`).
class UserRepository {
  UserRepository(this._api);
  final ApiClient _api;

  /// The signed-in account; the backend creates it (or claims an invite)
  /// on first call.
  Future<AppUser> fetchMe() async {
    final data = await _api.get('/api/users', queryParams: {'me': ''});
    return AppUser.fromJson(data as Map<String, dynamic>);
  }

  // --- super_admin only ---

  Future<List<UserAccount>> getAccounts() async {
    final data = await _api.get('/api/users') as List;
    return data
        .map((json) => UserAccount.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<UserAccount> invite({
    required String email,
    required UserRole role,
    int? volunteerId,
  }) async {
    final data = await _api.post('/api/users', body: {
      'email': email,
      'role': role.toJson(),
      'volunteer_id': ?volunteerId,
    });
    return UserAccount.fromJson(data as Map<String, dynamic>);
  }

  Future<UserAccount> setRole(int id, UserRole role) async {
    final data = await _api.patch('/api/users', body: {
      'id': id,
      'role': role.toJson(),
    });
    return UserAccount.fromJson(data as Map<String, dynamic>);
  }

  /// Links the account to a volunteer profile; null unlinks it.
  Future<UserAccount> setVolunteer(int id, int? volunteerId) async {
    final data = await _api.patch('/api/users', body: {
      'id': id,
      'volunteer_id': volunteerId,
    });
    return UserAccount.fromJson(data as Map<String, dynamic>);
  }

  Future<void> delete(int id) =>
      _api.delete('/api/users', queryParams: {'id': id.toString()});
}
