import '../../../core/api/api_client.dart';
import '../domain/app_user.dart';
import 'package:flutter/foundation.dart';

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
  Future<AppUser?> loginWithToken(String idToken, {int? volunteerId}) async {
    final body = <String, dynamic>{'id_token': idToken};
    if (volunteerId != null) body['volunteer_id'] = volunteerId;

    if (kDebugMode) print('AuthRepository.loginWithToken() calling POST /api/auth with body: $body');
    
    try {
      final json = await apiClient.post('/api/auth', body: body);
      if (kDebugMode) print('POST /api/auth response: $json');
      
      final user = AppUser.fromJson(json as Map<String, dynamic>);
      if (kDebugMode) print('Parsed user: ${user.email} with role ${user.role}');
      
      return user;
    } catch (e) {
      if (kDebugMode) print('loginWithToken() error: $e');
      rethrow;
    }
  }

  /// Get the current authenticated user from the backend.
  Future<AppUser?> getCurrentUser() async {
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

  /// Get the demo user (recruiter demo environment only).
  Future<AppUser?> getDemoUser() async {
    final json = await apiClient.get('/api/auth/demo');
    return AppUser.fromJson(json as Map<String, dynamic>);
  }
}
