import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_app/features/planner/domain/volunteer_assignment.dart';
import 'package:shelter_app/features/planner/presentation/widgets/planner_share.dart';

void main() {
  group('columnsForVolunteerCount', () {
    test('maps small counts 1:1', () {
      expect(columnsForVolunteerCount(0), 1);
      expect(columnsForVolunteerCount(1), 1);
      expect(columnsForVolunteerCount(2), 2);
      expect(columnsForVolunteerCount(3), 3);
    });

    test('lays 4 volunteers out as a 2x2 grid', () {
      expect(columnsForVolunteerCount(4), 2);
    });

    test('caps larger counts at 3 columns', () {
      expect(columnsForVolunteerCount(5), 3);
      expect(columnsForVolunteerCount(6), 3);
      expect(columnsForVolunteerCount(9), 3);
    });
  });

  group('formatShareDate', () {
    test('formats Monday in Polish', () {
      final date = DateTime(2026, 4, 20);
      expect(formatShareDate(date, 'pl'), 'Poniedziałek, 20 kwietnia 2026');
    });

    test('formats Sunday in Polish', () {
      final date = DateTime(2026, 4, 19);
      expect(formatShareDate(date, 'pl'), 'Niedziela, 19 kwietnia 2026');
    });

    test('formats Saturday in Polish', () {
      final date = DateTime(2026, 4, 18);
      expect(formatShareDate(date, 'pl'), 'Sobota, 18 kwietnia 2026');
    });

    test('formats January in Polish', () {
      final date = DateTime(2026, 1, 5);
      expect(formatShareDate(date, 'pl'), 'Poniedziałek, 5 stycznia 2026');
    });

    test('formats December in Polish', () {
      final date = DateTime(2025, 12, 31);
      expect(formatShareDate(date, 'pl'), 'Środa, 31 grudnia 2025');
    });

    test('formats Monday in English', () {
      final date = DateTime(2026, 4, 20);
      expect(formatShareDate(date, 'en'), 'Monday, April 20, 2026');
    });

    test('formats Sunday in English', () {
      final date = DateTime(2026, 4, 19);
      expect(formatShareDate(date, 'en'), 'Sunday, April 19, 2026');
    });

    test('defaults to Polish', () {
      final date = DateTime(2026, 4, 19);
      expect(formatShareDate(date), 'Niedziela, 19 kwietnia 2026');
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
            shelterId: '186',
            region: 'D',
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
          const DogEntry(
            dogId: 12,
            dogName: 'Rex',
            kennel: 'C2',
            shelterId: '524',
            region: 'A',
          ),
        ],
      ),
    ];

    Widget buildSubject({
      List<VolunteerAssignment>? assignments,
      DateTime? date,
      int totalDogs = 20,
      Brightness brightness = Brightness.dark,
      bool detailed = false,
      int cols = 2,
      double imageWidth = 700,
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
              detailed: detailed,
              cols: cols,
              imageWidth: imageWidth,
            ),
          ),
        ),
      );
    }

    testWidgets('displays full date header', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('Poniedziałek, 20 kwietnia 2026'), findsOneWidget);
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

    testWidgets('displays all dog names in compact mode', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.textContaining('Burek'), findsOneWidget);
      expect(find.textContaining('Luna'), findsOneWidget);
      expect(find.textContaining('Rex'), findsOneWidget);
    });

    testWidgets('displays dog note', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('shy dog'), findsOneWidget);
    });

    testWidgets('displays summary with counts', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('2 wolo  •  3/20 psów'), findsOneWidget);
    });

    testWidgets('does not display add buttons', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.byIcon(Icons.add_rounded), findsNothing);
      expect(find.byIcon(Icons.person_add_outlined), findsNothing);
    });

    testWidgets('compact mode shows kennel inline', (tester) async {
      await tester.pumpWidget(buildSubject());

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

    group('detailed mode', () {
      testWidgets('shows full dog info on two lines', (tester) async {
        await tester.pumpWidget(buildSubject(detailed: true));

        // Dog names on their own line
        expect(find.text('Luna'), findsOneWidget);
        expect(find.text('Rex'), findsOneWidget);
        // Detail line with shelterId · kennel · region
        expect(find.text('186 · B3 · D'), findsOneWidget);
        expect(find.text('524 · C2 · A'), findsOneWidget);
      });

      testWidgets('still shows notes', (tester) async {
        await tester.pumpWidget(buildSubject(detailed: true));

        expect(find.text('shy dog'), findsOneWidget);
        expect(find.text('10-13; 2 psy'), findsOneWidget);
      });
    });
  });
}
