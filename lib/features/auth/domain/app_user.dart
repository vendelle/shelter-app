import 'package:shelter_app/l10n/app_localizations.dart';

/// App access level, lowest first. Mirrors `api/_lib/permissions.ts`.
/// [exporter] sits outside that ladder: it only downloads the walks CSV.
enum UserRole {
  pending,
  volunteer,
  admin,
  superAdmin,
  exporter;

  static UserRole fromJson(String? value) {
    return switch (value) {
      'volunteer' => UserRole.volunteer,
      'admin' => UserRole.admin,
      'super_admin' => UserRole.superAdmin,
      'exporter' => UserRole.exporter,
      _ => UserRole.pending,
    };
  }

  String toJson() {
    return switch (this) {
      UserRole.pending => 'pending',
      UserRole.volunteer => 'volunteer',
      UserRole.admin => 'admin',
      UserRole.superAdmin => 'super_admin',
      UserRole.exporter => 'exporter',
    };
  }

  bool isAtLeast(UserRole other) =>
      this != exporter && other != exporter && index >= other.index;
}

extension UserRoleL10n on UserRole {
  String localizedLabel(AppLocalizations l10n) {
    return switch (this) {
      UserRole.pending => l10n.userRolePending,
      UserRole.volunteer => l10n.userRoleVolunteer,
      UserRole.admin => l10n.userRoleAdmin,
      UserRole.superAdmin => l10n.userRoleSuperAdmin,
      UserRole.exporter => l10n.userRoleExporter,
    };
  }
}

/// The signed-in person's account (`GET /api/users?me`).
class AppUser {
  final int id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final int? volunteerId;
  final UserRole role;

  const AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.volunteerId,
    required this.role,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      photoUrl: json['photo_url'] as String?,
      volunteerId: json['volunteer_id'] as int?,
      role: UserRole.fromJson(json['role'] as String?),
    );
  }
}

/// What the current visitor may change — `null` user means anonymous.
///
/// The API enforces the same rules (`api/_lib/permissions.ts`); these only
/// decide which controls the UI offers.
class Permissions {
  const Permissions(this.user);

  final AppUser? user;

  /// Day plans are editable from this many days ago to [planEditDaysAhead]
  /// days ahead; only a super admin can edit outside that.
  static const planEditDaysBack = 2;
  static const planEditDaysAhead = 2;

  bool _isAtLeast(UserRole role) => user?.role.isAtLeast(role) ?? false;

  bool get isSignedIn => user != null;
  bool get isPending => user?.role == UserRole.pending;

  /// The shelter's export-only account: sees just the walks CSV export.
  bool get isExporter => user?.role == UserRole.exporter;

  /// Signed in and approved — the app shows nothing to anyone else.
  bool get canView => _isAtLeast(UserRole.volunteer);
  bool get canManageData => _isAtLeast(UserRole.admin);
  bool get canManageUsers => _isAtLeast(UserRole.superAdmin);

  /// Whether the walk plan for [date] may be changed. [today] is for tests.
  bool canEditPlanOn(DateTime date, {DateTime? today}) {
    if (_isAtLeast(UserRole.superAdmin)) return true;
    if (!canView) return false;
    final now = today ?? DateTime.now();
    final day = DateTime(date.year, date.month, date.day);
    final from = DateTime(now.year, now.month, now.day - planEditDaysBack);
    final to = DateTime(now.year, now.month, now.day + planEditDaysAhead);
    return !day.isBefore(from) && !day.isAfter(to);
  }

  bool canEditFamiliarityOf(int volunteerId) {
    if (canManageData) return true;
    return _isAtLeast(UserRole.volunteer) && user!.volunteerId == volunteerId;
  }
}
