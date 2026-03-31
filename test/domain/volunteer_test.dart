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
    });
  });
}
