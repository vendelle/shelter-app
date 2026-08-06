import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_app/features/manage/presentation/providers/manage_providers.dart';
import 'package:shelter_app/features/planner/domain/planner_dog.dart';
import 'package:shelter_app/features/volunteer_detail/domain/volunteer_profile.dart';
import 'package:shelter_app/features/volunteer_detail/presentation/providers/volunteer_detail_providers.dart';
import 'package:shelter_app/features/volunteer_detail/presentation/volunteer_detail_screen.dart';
import 'package:shelter_app/l10n/app_localizations.dart';

Widget _buildTestWidget(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('pl'),
      home: child,
    ),
  );
}

VolunteerProfile _profile({
  bool archived = false,
  List<VolunteerVisit> visits = const [],
  List<VolunteerDogWalkCount> dogs = const [],
}) {
  return VolunteerProfile.fromJson({
    'volunteer': {
      'id': 1,
      'first_name': 'Anna',
      'last_name': 'Kowalska',
      'archived': archived,
      'role': 'senior',
    },
    'visits': visits
        .map((v) => {'walk_date': v.walkDate, 'walk_count': v.walkCount})
        .toList(),
    'dogs': dogs
        .map((d) => {
              'dog_id': d.dogId,
              'dog_name': d.dogName,
              'walk_count': d.walkCount,
            })
        .toList(),
  });
}

void main() {
  group('VolunteerDetailScreen', () {
    testWidgets('shows volunteer name and role status pill',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        const VolunteerDetailScreen(volunteerId: 1),
        overrides: [
          volunteerProfileProvider(1)
              .overrideWith((ref) => Future.value(_profile())),
          familiarityProvider(1).overrideWith(
              (ref) => Future.value(<int, DogFamiliarityLevel>{})),
        ],
      ));
      await tester.pumpAndSettle();

      // Name appears in the app bar and the header.
      expect(find.text('Anna Kowalska'), findsNWidgets(2));
      expect(find.text('Wolontariusz'), findsOneWidget);
      expect(find.text('Zarchiwizowany'), findsNothing);
    });

    testWidgets('shows the archived badge when archived', (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        const VolunteerDetailScreen(volunteerId: 1),
        overrides: [
          volunteerProfileProvider(1)
              .overrideWith((ref) => Future.value(_profile(archived: true))),
          familiarityProvider(1).overrideWith(
              (ref) => Future.value(<int, DogFamiliarityLevel>{})),
        ],
      ));
      await tester.pumpAndSettle();

      // Role pill is still shown alongside "Archived", not replaced by it.
      expect(find.text('Wolontariusz'), findsOneWidget);
      expect(find.text('Zarchiwizowany'), findsOneWidget);
    });

    testWidgets('shows dog pills and empty visits state', (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        const VolunteerDetailScreen(volunteerId: 1),
        overrides: [
          volunteerProfileProvider(1).overrideWith((ref) => Future.value(
                _profile(dogs: const [
                  VolunteerDogWalkCount(
                      dogId: 1, dogName: 'Rex', walkCount: 12),
                  VolunteerDogWalkCount(
                      dogId: 2, dogName: 'Cody', walkCount: 0),
                ]),
              )),
          familiarityProvider(1).overrideWith(
              (ref) => Future.value(<int, DogFamiliarityLevel>{})),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Rex'), findsOneWidget);
      expect(find.text('Cody'), findsOneWidget);
      expect(find.text('Brak wizyt w ostatnich 6 miesiącach'), findsOneWidget);

      // Color-swatch legend explains what each bucket means.
      expect(find.text('0'), findsOneWidget);
      expect(find.text('1-2'), findsOneWidget);
      expect(find.text('3-5'), findsOneWidget);
      expect(find.text('5-10'), findsOneWidget);
      expect(find.text('10+'), findsOneWidget);
    });

    testWidgets(
        'tapping a dog pill shows a tooltip above it with the exact walk '
        'count, correctly matched to that dog', (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        const VolunteerDetailScreen(volunteerId: 1),
        overrides: [
          volunteerProfileProvider(1).overrideWith((ref) => Future.value(
                _profile(dogs: const [
                  VolunteerDogWalkCount(
                      dogId: 1, dogName: 'Rex', walkCount: 7),
                  VolunteerDogWalkCount(
                      dogId: 2, dogName: 'Luna', walkCount: 2),
                ]),
              )),
          familiarityProvider(1).overrideWith(
              (ref) => Future.value(<int, DogFamiliarityLevel>{})),
        ],
      ));
      await tester.pumpAndSettle();

      // No tooltip visible before tapping.
      expect(find.textContaining('Rex:'), findsNothing);
      expect(find.textContaining('Luna:'), findsNothing);

      await tester.tap(find.text('Rex'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Tapping Rex's pill shows Rex's count, not Luna's.
      expect(find.textContaining('Rex: 7'), findsOneWidget);
      expect(find.textContaining('Luna:'), findsNothing);

      await tester.tap(find.text('Luna'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Switching to Luna's pill shows Luna's count, not a stale Rex one.
      expect(find.textContaining('Luna: 2'), findsOneWidget);
    });

    testWidgets('groups visits by month with per-month visit counts and '
        'weekday next to each date', (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        const VolunteerDetailScreen(volunteerId: 1),
        overrides: [
          volunteerProfileProvider(1).overrideWith((ref) => Future.value(
                _profile(visits: const [
                  VolunteerVisit(walkDate: '2026-08-04', walkCount: 2),
                  VolunteerVisit(walkDate: '2026-08-01', walkCount: 2),
                  VolunteerVisit(walkDate: '2026-07-22', walkCount: 2),
                ]),
              )),
          familiarityProvider(1).overrideWith(
              (ref) => Future.value(<int, DogFamiliarityLevel>{})),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Sie 2026'), findsOneWidget);
      expect(find.textContaining('Lip 2026'), findsOneWidget);
      expect(find.text('04.08'), findsOneWidget);
      expect(find.text('01.08'), findsOneWidget);
      expect(find.text('22.07'), findsOneWidget);

      // Month header shows visit count (2 visits in August), not walk
      // count (which would be 4).
      expect(find.text('2 wizyty'), findsOneWidget);
      expect(find.text('1 wizyta'), findsOneWidget);

      // Day of week next to each date: 04.08.2026 = Tue, 01.08.2026 = Sat,
      // 22.07.2026 = Wed.
      expect(find.text('Wt'), findsOneWidget);
      expect(find.text('Sob'), findsOneWidget);
      expect(find.text('Śr'), findsOneWidget);
    });
  });
}
