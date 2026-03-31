import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_app/features/planner/domain/planner_dog.dart';

void main() {
  group('PlannerDog', () {
    test('creates with required fields', () {
      const dog = PlannerDog(
        id: 1,
        name: 'Burek',
        kennel: 'A1',
        thisWeekWalks: 2,
        lastWeekWalks: 3,
      );

      expect(dog.id, 1);
      expect(dog.name, 'Burek');
      expect(dog.kennel, 'A1');
      expect(dog.thisWeekWalks, 2);
      expect(dog.lastWeekWalks, 3);
      expect(dog.familiarity, DogFamiliarityLevel.unknown);
    });

    test('comparePriority: fewer this-week walks = higher priority', () {
      const fewer = PlannerDog(
        id: 1, name: 'A', kennel: 'A1',
        thisWeekWalks: 0, lastWeekWalks: 0,
      );
      const more = PlannerDog(
        id: 2, name: 'B', kennel: 'A2',
        thisWeekWalks: 3, lastWeekWalks: 0,
      );

      expect(fewer.comparePriority(more), lessThan(0));
      expect(more.comparePriority(fewer), greaterThan(0));
    });

    test('comparePriority: equal this-week, fewer last-week = higher priority', () {
      const fewerLast = PlannerDog(
        id: 1, name: 'A', kennel: 'A1',
        thisWeekWalks: 2, lastWeekWalks: 1,
      );
      const moreLast = PlannerDog(
        id: 2, name: 'B', kennel: 'A2',
        thisWeekWalks: 2, lastWeekWalks: 5,
      );

      expect(fewerLast.comparePriority(moreLast), lessThan(0));
    });

    test('comparePriority: identical walks = 0', () {
      const a = PlannerDog(
        id: 1, name: 'A', kennel: 'A1',
        thisWeekWalks: 2, lastWeekWalks: 3,
      );
      const b = PlannerDog(
        id: 2, name: 'B', kennel: 'A2',
        thisWeekWalks: 2, lastWeekWalks: 3,
      );

      expect(a.comparePriority(b), 0);
    });
  });

  group('DogFamiliarityLevel', () {
    test('has expected values', () {
      expect(DogFamiliarityLevel.values, contains(DogFamiliarityLevel.unknown));
      expect(DogFamiliarityLevel.values, contains(DogFamiliarityLevel.good));
      expect(DogFamiliarityLevel.values, contains(DogFamiliarityLevel.neutral));
    });
  });
}
