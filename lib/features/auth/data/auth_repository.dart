import '../../../core/api/api_client.dart';
import '../domain/app_user.dart';

/// Repository for authentication operations.
///
/// Combines Firebase Auth (sign-in provider) with the backend user record.
class AuthRepository {
  AuthRepository({required this.apiClient});

  final ApiClient apiClient;

  /// Exchange a Firebase ID token for a backend user record.
  ///
  /// Creates the user on first login; returns existing user on subsequent logins.
  /// Optionally links to a [volunteerId].
  Future<AppUser> loginWithToken(String idToken, {int? volunteerId}) async {
    final body = <String, dynamic>{'id_token': idToken};
    if (volunteerId != null) body['volunteer_id'] = volunteerId;

    final json = await apiClient.post('/api/auth', body: body);
    return AppUser.fromJson(json as Map<String, dynamic>);
  }

  /// Get the current authenticated user from the backend.
  Future<AppUser> getCurrentUser() async {
    final json = await apiClient.get('/api/auth');
    return AppUser.fromJson(json as Map<String, dynamic>);
  }

  /// List all users (super_admin only).
  Future<List<Map<String, dynamic>>> listUsers() async {
    final json = await apiClient.get('/api/users');
    return (json as List).cast<Map<String, dynamic>>();
  }

  /// Update a user's role and/or volunteer link (super_admin only).
  Future<Map<String, dynamic>> updateUser({
    required int userId,
    String? role,
    int? volunteerId,
  }) async {
    final body = <String, dynamic>{'id': userId};
    if (role != null) body['role'] = role;
    if (volunteerId != null) body['volunteer_id'] = volunteerId;

    final json = await apiClient.patch('/api/users', body: body);
    return json as Map<String, dynamic>;
  }
}
