import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_app/features/auth/domain/app_user.dart';

void main() {
  group('AppUser', () {
    test('fromJson parses all fields', () {
      final user = AppUser.fromJson({
        'id': 1,
        'firebase_uid': 'uid-abc',
        'email': 'test@example.com',
        'display_name': 'Test User',
        'photo_url': 'https://example.com/pic.jpg',
        'volunteer_id': 5,
        'role': 'volunteer',
      });

      expect(user.id, 1);
      expect(user.firebaseUid, 'uid-abc');
      expect(user.email, 'test@example.com');
      expect(user.displayName, 'Test User');
      expect(user.photoUrl, 'https://example.com/pic.jpg');
      expect(user.volunteerId, 5);
      expect(user.role, UserRole.volunteer);
    });

    test('fromJson handles null optional fields', () {
      final user = AppUser.fromJson({
        'id': 2,
        'firebase_uid': 'uid-xyz',
        'email': 'other@example.com',
        'display_name': null,
        'photo_url': null,
        'volunteer_id': null,
        'role': 'pending',
      });

      expect(user.displayName, isNull);
      expect(user.photoUrl, isNull);
      expect(user.volunteerId, isNull);
      expect(user.role, UserRole.pending);
    });

    test('isPending returns true for pending role', () {
      const user = AppUser(
        id: 1,
        firebaseUid: 'uid',
        email: 'a@b.com',
        role: UserRole.pending,
      );

      expect(user.isPending, true);
      expect(user.isApproved, false);
    });

    test('isApproved returns true for non-pending roles', () {
      for (final role in [UserRole.volunteer, UserRole.admin, UserRole.superAdmin]) {
        final user = AppUser(
          id: 1,
          firebaseUid: 'uid',
          email: 'a@b.com',
          role: role,
        );
        expect(user.isApproved, true, reason: 'Role $role should be approved');
        expect(user.isPending, false);
      }
    });

    test('isAdmin returns true for admin and super_admin', () {
      const admin = AppUser(
        id: 1, firebaseUid: 'uid', email: 'a@b.com', role: UserRole.admin,
      );
      const superAdmin = AppUser(
        id: 2, firebaseUid: 'uid2', email: 'b@c.com', role: UserRole.superAdmin,
      );
      const volunteer = AppUser(
        id: 3, firebaseUid: 'uid3', email: 'c@d.com', role: UserRole.volunteer,
      );

      expect(admin.isAdmin, true);
      expect(superAdmin.isAdmin, true);
      expect(volunteer.isAdmin, false);
    });

    test('isSuperAdmin returns true only for super_admin', () {
      const admin = AppUser(
        id: 1, firebaseUid: 'uid', email: 'a@b.com', role: UserRole.admin,
      );
      const superAdmin = AppUser(
        id: 2, firebaseUid: 'uid2', email: 'b@c.com', role: UserRole.superAdmin,
      );

      expect(admin.isSuperAdmin, false);
      expect(superAdmin.isSuperAdmin, true);
    });

    test('canEditFamiliarity admin can edit anyone', () {
      const admin = AppUser(
        id: 1, firebaseUid: 'uid', email: 'a@b.com',
        role: UserRole.admin, volunteerId: 10,
      );

      expect(admin.canEditFamiliarity(10), true);
      expect(admin.canEditFamiliarity(99), true);
    });

    test('canEditFamiliarity volunteer can only edit own', () {
      const vol = AppUser(
        id: 1, firebaseUid: 'uid', email: 'a@b.com',
        role: UserRole.volunteer, volunteerId: 10,
      );

      expect(vol.canEditFamiliarity(10), true);
      expect(vol.canEditFamiliarity(99), false);
    });

    test('canEditFamiliarity volunteer without link cannot edit any', () {
      const vol = AppUser(
        id: 1, firebaseUid: 'uid', email: 'a@b.com',
        role: UserRole.volunteer,
      );

      expect(vol.canEditFamiliarity(10), false);
    });
  });

  group('UserRole', () {
    test('fromString parses all roles', () {
      expect(UserRole.fromString('pending'), UserRole.pending);
      expect(UserRole.fromString('volunteer'), UserRole.volunteer);
      expect(UserRole.fromString('admin'), UserRole.admin);
      expect(UserRole.fromString('super_admin'), UserRole.superAdmin);
    });

    test('fromString defaults to pending for unknown', () {
      expect(UserRole.fromString(null), UserRole.pending);
      expect(UserRole.fromString('unknown'), UserRole.pending);
    });

    test('toJson returns correct strings', () {
      expect(UserRole.pending.toJson(), 'pending');
      expect(UserRole.volunteer.toJson(), 'volunteer');
      expect(UserRole.admin.toJson(), 'admin');
      expect(UserRole.superAdmin.toJson(), 'super_admin');
    });

    test('label returns human-readable text', () {
      expect(UserRole.pending.label, isNotEmpty);
      expect(UserRole.volunteer.label, isNotEmpty);
      expect(UserRole.admin.label, isNotEmpty);
      expect(UserRole.superAdmin.label, isNotEmpty);
    });
  });
}
