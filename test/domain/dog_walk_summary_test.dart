import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_app/features/overview/domain/dog_walk_summary.dart';

void main() {
  group('DogWalkSummary', () {
    test('creates with required fields', () {
      const summary = DogWalkSummary(
        dogId: 1,
        dogName: 'Burek',
        kennel: 'A1',
        thisWeekWalks: 2,
        lastWeekWalks: 3,
      );

      expect(summary.dogId, 1);
      expect(summary.dogName, 'Burek');
      expect(summary.kennel, 'A1');
    });

    test('fromJson parses correctly', () {
      final summary = DogWalkSummary.fromJson({
        'dog_id': 1,
        'dog_name': 'Burek',
        'kennel': 'A1',
        'this_week_walks': 2,
        'last_week_walks': 3,
      });

      expect(summary.dogId, 1);
      expect(summary.dogName, 'Burek');
      expect(summary.kennel, 'A1');
      expect(summary.thisWeekWalks, 2);
      expect(summary.lastWeekWalks, 3);
    });

    test('fromJson handles null kennel', () {
      final summary = DogWalkSummary.fromJson({
        'dog_id': 1,
        'dog_name': 'Burek',
        'kennel': null,
        'this_week_walks': 0,
        'last_week_walks': 0,
      });

      expect(summary.kennel, '');
    });

    test('fromJson handles string walk counts', () {
      final summary = DogWalkSummary.fromJson({
        'dog_id': 1,
        'dog_name': 'Burek',
        'kennel': 'A1',
        'this_week_walks': '5',
        'last_week_walks': '3',
      });

      expect(summary.thisWeekWalks, 5);
      expect(summary.lastWeekWalks, 3);
    });

    group('urgency', () {
      test('0 walks = urgent', () {
        const summary = DogWalkSummary(
          dogId: 1, dogName: 'A', kennel: 'A1',
          thisWeekWalks: 0, lastWeekWalks: 3,
        );
        expect(summary.urgency, WalkUrgency.urgent);
      });

      test('1-2 walks = moderate', () {
        const s1 = DogWalkSummary(
          dogId: 1, dogName: 'A', kennel: 'A1',
          thisWeekWalks: 1, lastWeekWalks: 0,
        );
        const s2 = DogWalkSummary(
          dogId: 2, dogName: 'B', kennel: 'A2',
          thisWeekWalks: 2, lastWeekWalks: 0,
        );
        expect(s1.urgency, WalkUrgency.moderate);
        expect(s2.urgency, WalkUrgency.moderate);
      });

      test('3+ walks = good', () {
        const summary = DogWalkSummary(
          dogId: 1, dogName: 'A', kennel: 'A1',
          thisWeekWalks: 3, lastWeekWalks: 0,
        );
        expect(summary.urgency, WalkUrgency.good);
      });
    });

    group('trend', () {
      test('positive trend when more walks than last week', () {
        const summary = DogWalkSummary(
          dogId: 1, dogName: 'A', kennel: 'A1',
          thisWeekWalks: 5, lastWeekWalks: 2,
        );
        expect(summary.trend, 3);
      });

      test('negative trend when fewer walks than last week', () {
        const summary = DogWalkSummary(
          dogId: 1, dogName: 'A', kennel: 'A1',
          thisWeekWalks: 1, lastWeekWalks: 4,
        );
        expect(summary.trend, -3);
      });

      test('zero trend when same walks', () {
        const summary = DogWalkSummary(
          dogId: 1, dogName: 'A', kennel: 'A1',
          thisWeekWalks: 3, lastWeekWalks: 3,
        );
        expect(summary.trend, 0);
      });
    });
  });
}
