import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_app/features/shared/domain/volunteer.dart';

void main() {
  group('Volunteer', () {
    test('creates with required fields', () {
      const volunteer = Volunteer(
        id: 1,
        firstName: 'Anna',
        lastName: 'Kowalska',
      );

      expect(volunteer.id, 1);
      expect(volunteer.firstName, 'Anna');
      expect(volunteer.lastName, 'Kowalska');
      expect(volunteer.archived, false);
      expect(volunteer.role, VolunteerRole.newHelper);
    });

    test('fullName concatenates first and last name', () {
      const volunteer = Volunteer(
        id: 1,
        firstName: 'Anna',
        lastName: 'Kowalska',
      );

      expect(volunteer.fullName, 'Anna Kowalska');
    });

    test('fromJson parses correctly', () {
      final volunteer = Volunteer.fromJson({
        'id': 42,
        'first_name': 'Jan',
        'last_name': 'Nowak',
      });

      expect(volunteer.id, 42);
      expect(volunteer.firstName, 'Jan');
      expect(volunteer.lastName, 'Nowak');
      expect(volunteer.fullName, 'Jan Nowak');
      expect(volunteer.archived, false);
      expect(volunteer.role, VolunteerRole.newHelper);
    });

    test('fromJson parses archived and role', () {
      final volunteer = Volunteer.fromJson({
        'id': 1,
        'first_name': 'Anna',
        'last_name': 'K',
        'archived': true,
        'role': 'senior',
      });

      expect(volunteer.archived, true);
      expect(volunteer.role, VolunteerRole.senior);
    });

    test('fromJson defaults archived to false when null', () {
      final volunteer = Volunteer.fromJson({
        'id': 1,
        'first_name': 'A',
        'last_name': 'B',
        'archived': null,
      });

      expect(volunteer.archived, false);
    });
  });

  group('VolunteerRole', () {
    test('fromString maps known roles', () {
      expect(VolunteerRole.fromString('senior'), VolunteerRole.senior);
      expect(VolunteerRole.fromString('independent'), VolunteerRole.independent);
      expect(VolunteerRole.fromString('supporter'), VolunteerRole.supporter);
      expect(VolunteerRole.fromString('new'), VolunteerRole.newHelper);
    });

    test('fromString defaults unknown values to newHelper', () {
      expect(VolunteerRole.fromString(null), VolunteerRole.newHelper);
      expect(VolunteerRole.fromString('unknown'), VolunteerRole.newHelper);
      expect(VolunteerRole.fromString(''), VolunteerRole.newHelper);
    });

    test('toJson returns correct strings', () {
      expect(VolunteerRole.senior.toJson(), 'senior');
      expect(VolunteerRole.independent.toJson(), 'independent');
      expect(VolunteerRole.supporter.toJson(), 'supporter');
      expect(VolunteerRole.newHelper.toJson(), 'new');
    });

    test('label returns display names', () {
      expect(VolunteerRole.senior.label, 'Volunteer');
      expect(VolunteerRole.independent.label, 'Independent supporter');
      expect(VolunteerRole.supporter.label, 'Supporter');
      expect(VolunteerRole.newHelper.label, 'New');
    });
  });
}
