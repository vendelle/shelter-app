import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_app/features/planner/domain/volunteer_assignment.dart';
import 'package:shelter_app/features/planner/presentation/widgets/assignment_card.dart';

void main() {
  group('VolunteerColumn', () {
    late VolunteerAssignment assignment;

    setUp(() {
      assignment = VolunteerAssignment(
        volunteerId: 1,
        volunteerName: 'Anna Kowalska',
        dogs: [
          const DogEntry(dogId: 10, dogName: 'Burek', kennel: 'A1'),
          const DogEntry(
            dogId: 11,
            dogName: 'Luna',
            kennel: 'A2',
            groupIndex: 1,
            note: 'shy dog',
          ),
        ],
        note: '10-13 only',
      );
    });

    Widget buildSubject({VolunteerAssignment? overrideAssignment}) {
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: VolunteerColumn(
              assignment: overrideAssignment ?? assignment,
              onAddDog: () {},
              onRemoveDog: (_) {},
              onRemoveVolunteer: () {},
              onTapDog: (_) {},
              onEditVolunteerNote: () {},
              onReorderDogs: (_, _2) {},
            ),
          ),
        ),
      );
    }

    testWidgets('displays volunteer name', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('Anna Kowalska'), findsOneWidget);
    });

    testWidgets('displays volunteer note', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('10-13 only'), findsOneWidget);
    });

    testWidgets('hides note when null', (tester) async {
      final noNote = VolunteerAssignment(
        volunteerId: 1,
        volunteerName: 'Anna Kowalska',
        dogs: [const DogEntry(dogId: 10, dogName: 'Burek')],
      );
      await tester.pumpWidget(buildSubject(overrideAssignment: noNote));

      // The note text should not be present
      expect(find.text('10-13 only'), findsNothing);
    });

    testWidgets('displays all dog names', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.textContaining('Burek'), findsOneWidget);
      expect(find.textContaining('Luna'), findsOneWidget);
    });

    testWidgets('displays dog kennel labels', (tester) async {
      await tester.pumpWidget(buildSubject());

      // Kennel is shown as part of Text.rich with a space
      expect(find.textContaining('A1'), findsOneWidget);
      expect(find.textContaining('A2'), findsOneWidget);
    });

    testWidgets('displays dog note when present', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('shy dog'), findsOneWidget);
    });

    testWidgets('shows add button', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    });

    testWidgets('calls onAddDog when add button tapped', (tester) async {
      var addDogCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VolunteerColumn(
                assignment: assignment,
                onAddDog: () => addDogCalled = true,
                onRemoveDog: (_) {},
                onRemoveVolunteer: () {},
                onTapDog: (_) {},
                onEditVolunteerNote: () {},
                onReorderDogs: (_, _2) {},
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.add_rounded));
      expect(addDogCalled, isTrue);
    });

    testWidgets('calls onEditVolunteerNote when header tapped', (tester) async {
      var editNoteCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VolunteerColumn(
                assignment: assignment,
                onAddDog: () {},
                onRemoveDog: (_) {},
                onRemoveVolunteer: () {},
                onTapDog: (_) {},
                onEditVolunteerNote: () => editNoteCalled = true,
                onReorderDogs: (_, _2) {},
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Anna Kowalska'));
      expect(editNoteCalled, isTrue);
    });

    testWidgets('renders with empty dogs list', (tester) async {
      final empty = VolunteerAssignment(
        volunteerId: 1,
        volunteerName: 'Anna',
      );
      await tester.pumpWidget(buildSubject(overrideAssignment: empty));

      expect(find.text('Anna'), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    });
  });

  group('VolunteerColumn overview mode', () {
    late VolunteerAssignment assignment;

    setUp(() {
      assignment = VolunteerAssignment(
        volunteerId: 1,
        volunteerName: 'Anna Kowalska',
        dogs: [
          const DogEntry(dogId: 10, dogName: 'Burek', kennel: 'A1'),
          const DogEntry(
            dogId: 11,
            dogName: 'Luna',
            kennel: 'A2',
            groupIndex: 1,
            note: 'shy dog',
          ),
        ],
        note: '10-13 only',
      );
    });

    Widget buildOverview({VolunteerAssignment? overrideAssignment}) {
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: VolunteerColumn(
              assignment: overrideAssignment ?? assignment,
              overview: true,
              onAddDog: () {},
              onRemoveDog: (_) {},
              onRemoveVolunteer: () {},
              onTapDog: (_) {},
              onEditVolunteerNote: () {},
              onReorderDogs: (_, _2) {},
            ),
          ),
        ),
      );
    }

    testWidgets('hides add dog button', (tester) async {
      await tester.pumpWidget(buildOverview());

      expect(find.byIcon(Icons.add_rounded), findsNothing);
    });

    testWidgets('still displays volunteer name and note', (tester) async {
      await tester.pumpWidget(buildOverview());

      expect(find.text('Anna Kowalska'), findsOneWidget);
      expect(find.text('10-13 only'), findsOneWidget);
    });

    testWidgets('still displays dog names and notes', (tester) async {
      await tester.pumpWidget(buildOverview());

      expect(find.textContaining('Burek'), findsOneWidget);
      expect(find.textContaining('Luna'), findsOneWidget);
      expect(find.text('shy dog'), findsOneWidget);
    });

    testWidgets('does not have Dismissible widgets', (tester) async {
      await tester.pumpWidget(buildOverview());

      expect(find.byType(Dismissible), findsNothing);
    });

    testWidgets('header tap does not trigger onEditVolunteerNote',
        (tester) async {
      var editNoteCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VolunteerColumn(
                assignment: assignment,
                overview: true,
                onAddDog: () {},
                onRemoveDog: (_) {},
                onRemoveVolunteer: () {},
                onTapDog: (_) {},
                onEditVolunteerNote: () => editNoteCalled = true,
                onReorderDogs: (_, _2) {},
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Anna Kowalska'));
      expect(editNoteCalled, isFalse);
    });
  });
}
