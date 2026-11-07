import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_app/features/auth/domain/app_user.dart';
import 'package:shelter_app/features/auth/domain/user_account.dart';

AppUser _user(UserRole role, {int? volunteerId}) => AppUser(
      id: 1,
      email: 'anna@gmail.com',
      role: role,
      volunteerId: volunteerId,
    );

void main() {
  group('UserRole', () {
    test('round-trips through JSON', () {
      for (final role in UserRole.values) {
        expect(UserRole.fromJson(role.toJson()), role);
      }
      expect(UserRole.superAdmin.toJson(), 'super_admin');
    });

    test('treats unknown values as pending', () {
      expect(UserRole.fromJson('owner'), UserRole.pending);
      expect(UserRole.fromJson(null), UserRole.pending);
    });

    test('orders roles lowest first', () {
      expect(UserRole.admin.isAtLeast(UserRole.volunteer), isTrue);
      expect(UserRole.volunteer.isAtLeast(UserRole.admin), isFalse);
    });

    test('keeps the export-only role off the ladder', () {
      expect(UserRole.exporter.isAtLeast(UserRole.pending), isFalse);
      expect(UserRole.superAdmin.isAtLeast(UserRole.exporter), isFalse);
    });
  });

  test('AppUser.fromJson reads the API shape', () {
    final user = AppUser.fromJson({
      'id': 5,
      'email': 'anna@gmail.com',
      'display_name': 'Anna K',
      'photo_url': null,
      'volunteer_id': 7,
      'role': 'admin',
    });
    expect(user.id, 5);
    expect(user.displayName, 'Anna K');
    expect(user.volunteerId, 7);
    expect(user.role, UserRole.admin);
  });

  test('UserAccount.fromJson joins the volunteer name and invite state', () {
    final account = UserAccount.fromJson({
      'id': 9,
      'email': 'jan@gmail.com',
      'display_name': null,
      'photo_url': null,
      'volunteer_id': 3,
      'volunteer_first_name': 'Jan',
      'volunteer_last_name': 'Nowak',
      'role': 'volunteer',
      'invite_pending': true,
      'created_at': '2026-10-01T10:00:00.000Z',
      'last_login_at': null,
    });
    expect(account.volunteerName, 'Jan Nowak');
    expect(account.invitePending, isTrue);
    expect(account.label, 'jan@gmail.com');
    expect(account.lastLoginAt, isNull);
  });

  group('Permissions', () {
    final today = DateTime(2026, 10, 16);

    test('anonymous visitors see nothing', () {
      const p = Permissions(null);
      expect(p.isSignedIn, isFalse);
      expect(p.canView, isFalse);
      expect(p.canEditPlanOn(today, today: today), isFalse);
      expect(p.canEditFamiliarityOf(1), isFalse);
    });

    test('pending accounts see nothing', () {
      final p = Permissions(_user(UserRole.pending, volunteerId: 1));
      expect(p.isPending, isTrue);
      expect(p.canView, isFalse);
      expect(p.canEditPlanOn(today, today: today), isFalse);
      expect(p.canEditFamiliarityOf(1), isFalse);
    });

    test('export-only accounts see nothing but the export', () {
      final p = Permissions(_user(UserRole.exporter));
      expect(p.isExporter, isTrue);
      expect(p.canView, isFalse);
      expect(p.canManageData, isFalse);
      expect(p.canEditPlanOn(today, today: today), isFalse);
      expect(p.canEditFamiliarityOf(1), isFalse);
    });

    for (final role in [UserRole.volunteer, UserRole.admin]) {
      test('${role.name}s edit plans from 2 days ago to 2 days ahead', () {
        final p = Permissions(_user(role));
        expect(p.canView, isTrue);
        expect(p.canEditPlanOn(DateTime(2026, 10, 14), today: today), isTrue);
        expect(p.canEditPlanOn(DateTime(2026, 10, 18), today: today), isTrue);
        expect(p.canEditPlanOn(DateTime(2026, 10, 13), today: today), isFalse);
        expect(p.canEditPlanOn(DateTime(2026, 10, 19), today: today), isFalse);
      });
    }

    test('the edit window crosses month boundaries', () {
      final p = Permissions(_user(UserRole.volunteer));
      final march1 = DateTime(2026, 3, 1);
      expect(p.canEditPlanOn(DateTime(2026, 2, 27), today: march1), isTrue);
      expect(p.canEditPlanOn(DateTime(2026, 2, 26), today: march1), isFalse);
    });

    test('volunteers edit only their own familiarity, not shelter data', () {
      final p = Permissions(_user(UserRole.volunteer, volunteerId: 7));
      expect(p.canEditFamiliarityOf(7), isTrue);
      expect(p.canEditFamiliarityOf(8), isFalse);
      expect(p.canManageData, isFalse);
    });

    test('admins manage shelter data but not users', () {
      final p = Permissions(_user(UserRole.admin));
      expect(p.canManageData, isTrue);
      expect(p.canEditFamiliarityOf(8), isTrue);
      expect(p.canManageUsers, isFalse);
    });

    test('the super admin edits any day and manages users', () {
      final p = Permissions(_user(UserRole.superAdmin));
      expect(p.canManageUsers, isTrue);
      expect(p.canEditPlanOn(DateTime(2020), today: today), isTrue);
      expect(p.canEditPlanOn(DateTime(2030), today: today), isTrue);
    });
  });
}
