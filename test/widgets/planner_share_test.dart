import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_app/features/planner/domain/volunteer_assignment.dart';
import 'package:shelter_app/features/planner/presentation/widgets/planner_share.dart';

void main() {
  group('formatShareDate', () {
    test('formats Monday correctly', () {
      // 2026-04-20 is a Monday
      final date = DateTime(2026, 4, 20);
      expect(formatShareDate(date), 'Pon, Kwi 20');
    });

    test('formats Sunday correctly', () {
      // 2026-04-19 is a Sunday
      final date = DateTime(2026, 4, 19);
      expect(formatShareDate(date), 'Niedz, Kwi 19');
    });

    test('formats Saturday correctly', () {
      final date = DateTime(2026, 4, 18);
      expect(formatShareDate(date), 'Sob, Kwi 18');
    });

    test('formats January correctly', () {
      final date = DateTime(2026, 1, 5);
      expect(formatShareDate(date), 'Pon, Sty 5');
    });

    test('formats December correctly', () {
      final date = DateTime(2025, 12, 31);
      expect(formatShareDate(date), 'Śr, Gru 31');
    });
  });

  group('PlannerShareLayout', () {
    final testAssignments = [
      VolunteerAssignment(
        volunteerId: 1,
        volunteerName: 'Anna Kowalska',
        dogs: [
          const DogEntry(dogId: 10, dogName: 'Burek', kennel: 'A1'),
          const DogEntry(
            dogId: 11,
            dogName: 'Luna',
            kennel: 'B3',
            groupIndex: 1,
            note: 'shy dog',
          ),
        ],
        note: '10-13; 2 psy',
      ),
      VolunteerAssignment(
        volunteerId: 2,
        volunteerName: 'Jan Nowak',
        dogs: [
          const DogEntry(dogId: 12, dogName: 'Rex', kennel: 'C2'),
        ],
      ),
    ];

    Widget buildSubject({
      List<VolunteerAssignment>? assignments,
      DateTime? date,
      int totalDogs = 20,
      Brightness brightness = Brightness.dark,
    }) {
      return MaterialApp(
        theme: brightness == Brightness.dark
            ? ThemeData.dark(useMaterial3: true)
            : ThemeData.light(useMaterial3: true),
        home: Scaffold(
          body: SingleChildScrollView(
            child: PlannerShareLayout(
              date: date ?? DateTime(2026, 4, 20),
              assignments: assignments ?? testAssignments,
              totalDogs: totalDogs,
              brightness: brightness,
            ),
          ),
        ),
      );
    }

    testWidgets('displays date header', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('Pon, Kwi 20'), findsOneWidget);
    });

    testWidgets('displays all volunteer names', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('Anna Kowalska'), findsOneWidget);
      expect(find.text('Jan Nowak'), findsOneWidget);
    });

    testWidgets('displays volunteer note', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('10-13; 2 psy'), findsOneWidget);
    });

    testWidgets('displays all dog names', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.textContaining('Burek'), findsOneWidget);
      expect(find.textContaining('Luna'), findsOneWidget);
      expect(find.textContaining('Rex'), findsOneWidget);
    });

    testWidgets('displays dog note', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('shy dog'), findsOneWidget);
    });

    testWidgets('displays summary with volunteer and dog counts',
        (tester) async {
      await tester.pumpWidget(buildSubject());

      // 2 volunteers, 3 dogs assigned, 20 total
      expect(find.text('2 wolo  •  3/20 psów'), findsOneWidget);
    });

    testWidgets('does not display add buttons', (tester) async {
      await tester.pumpWidget(buildSubject());

      // No "+" icon for adding dogs/volunteers
      expect(find.byIcon(Icons.add_rounded), findsNothing);
      expect(find.byIcon(Icons.person_add_outlined), findsNothing);
    });

    testWidgets('displays kennel numbers', (tester) async {
      await tester.pumpWidget(buildSubject());

      // Kennel shown as secondary text alongside dog name
      expect(find.textContaining('A1'), findsOneWidget);
      expect(find.textContaining('B3'), findsOneWidget);
      expect(find.textContaining('C2'), findsOneWidget);
    });

    testWidgets('handles empty assignments', (tester) async {
      await tester.pumpWidget(buildSubject(assignments: []));

      expect(find.text('0 wolo  •  0/20 psów'), findsOneWidget);
    });

    testWidgets('works with light theme', (tester) async {
      await tester
          .pumpWidget(buildSubject(brightness: Brightness.light));

      expect(find.text('Anna Kowalska'), findsOneWidget);
      expect(find.textContaining('Burek'), findsOneWidget);
    });
  });
}
