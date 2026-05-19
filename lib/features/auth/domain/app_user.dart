/// App user account from the backend.
///
/// Represents an authenticated user with their role and optional
/// volunteer profile link.
class AppUser {
  final int id;
  final String firebaseUid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final int? volunteerId;
  final UserRole role;

  const AppUser({
    required this.id,
    required this.firebaseUid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.volunteerId,
    required this.role,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      firebaseUid: json['firebase_uid'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      photoUrl: json['photo_url'] as String?,
      volunteerId: json['volunteer_id'] as int?,
      role: UserRole.fromString(json['role'] as String?),
    );
  }

  bool get isPending => role == UserRole.pending;
  bool get isApproved => role != UserRole.pending;
  bool get isAdmin => role == UserRole.admin || role == UserRole.superAdmin;
  bool get isSuperAdmin => role == UserRole.superAdmin;

  /// Whether this user can edit familiarity preferences for the given volunteer.
  bool canEditFamiliarity(int targetVolunteerId) {
    if (isAdmin) return true;
    return volunteerId == targetVolunteerId;
  }
}

enum UserRole {
  pending,
  volunteer,
  admin,
  superAdmin;

  static UserRole fromString(String? value) {
    return switch (value) {
      'pending' => UserRole.pending,
      'volunteer' => UserRole.volunteer,
      'admin' => UserRole.admin,
      'super_admin' => UserRole.superAdmin,
      _ => UserRole.pending,
    };
  }

  String toJson() {
    return switch (this) {
      UserRole.pending => 'pending',
      UserRole.volunteer => 'volunteer',
      UserRole.admin => 'admin',
      UserRole.superAdmin => 'super_admin',
    };
  }

  String get label {
    return switch (this) {
      UserRole.pending => 'Pending approval',
      UserRole.volunteer => 'Volunteer',
      UserRole.admin => 'Admin',
      UserRole.superAdmin => 'Super Admin',
    };
  }
}
