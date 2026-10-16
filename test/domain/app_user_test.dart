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

    test('anonymous visitors can only view', () {
      const p = Permissions(null);
      expect(p.isSignedIn, isFalse);
      expect(p.canEditPlanOn(today, today: today), isFalse);
      expect(p.canManageData, isFalse);
      expect(p.canEditFamiliarityOf(1), isFalse);
    });

    test('pending accounts can only view', () {
      final p = Permissions(_user(UserRole.pending, volunteerId: 1));
      expect(p.isPending, isTrue);
      expect(p.canEditPlanOn(today, today: today), isFalse);
      expect(p.canEditFamiliarityOf(1), isFalse);
    });

    test('volunteers edit plans from 3 days ago onward', () {
      final p = Permissions(_user(UserRole.volunteer));
      expect(p.canEditPlanOn(DateTime(2026, 12, 1), today: today), isTrue);
      expect(p.canEditPlanOn(today, today: today), isTrue);
      expect(p.canEditPlanOn(DateTime(2026, 10, 13), today: today), isTrue);
      expect(p.canEditPlanOn(DateTime(2026, 10, 12), today: today), isFalse);
      expect(p.canManageData, isFalse);
    });

    test('the edit window crosses month boundaries', () {
      final p = Permissions(_user(UserRole.volunteer));
      final march2 = DateTime(2026, 3, 2);
      expect(p.canEditPlanOn(DateTime(2026, 2, 27), today: march2), isTrue);
      expect(p.canEditPlanOn(DateTime(2026, 2, 26), today: march2), isFalse);
    });

    test('volunteers edit only their own familiarity', () {
      final p = Permissions(_user(UserRole.volunteer, volunteerId: 7));
      expect(p.canEditFamiliarityOf(7), isTrue);
      expect(p.canEditFamiliarityOf(8), isFalse);
    });

    test('admins edit anything but users', () {
      final p = Permissions(_user(UserRole.admin));
      expect(p.canEditPlanOn(DateTime(2020), today: today), isTrue);
      expect(p.canManageData, isTrue);
      expect(p.canEditFamiliarityOf(8), isTrue);
      expect(p.canManageUsers, isFalse);
    });

    test('super admins also manage users', () {
      expect(Permissions(_user(UserRole.superAdmin)).canManageUsers, isTrue);
    });
  });
}
