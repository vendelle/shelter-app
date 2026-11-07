import 'app_user.dart';

/// An account as listed in user management (`GET /api/users`).
class UserAccount {
  final int id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final int? volunteerId;
  final String? volunteerName;
  final UserRole role;

  /// Invited by email, but that Google account hasn't signed in yet.
  final bool invitePending;
  final DateTime? lastLoginAt;

  const UserAccount({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.volunteerId,
    this.volunteerName,
    required this.role,
    this.invitePending = false,
    this.lastLoginAt,
  });

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    final firstName = json['volunteer_first_name'] as String?;
    final lastName = json['volunteer_last_name'] as String?;
    final lastLogin = json['last_login_at'] as String?;
    return UserAccount(
      id: json['id'] as int,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      photoUrl: json['photo_url'] as String?,
      volunteerId: json['volunteer_id'] as int?,
      volunteerName: firstName == null
          ? null
          : [firstName, lastName].whereType<String>().join(' '),
      role: UserRole.fromJson(json['role'] as String?),
      invitePending: json['invite_pending'] as bool? ?? false,
      lastLoginAt: lastLogin == null ? null : DateTime.parse(lastLogin),
    );
  }

  /// Name to show: Google profile name, else the email.
  String get label => displayName ?? email;
}
