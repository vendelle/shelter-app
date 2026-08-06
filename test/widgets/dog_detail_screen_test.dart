import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_app/features/dog_detail/domain/dog_walk_history.dart';
import 'package:shelter_app/features/dog_detail/domain/walk_partner.dart';
import 'package:shelter_app/features/dog_detail/presentation/dog_detail_screen.dart';
import 'package:shelter_app/features/dog_detail/presentation/providers/dog_detail_providers.dart';
import 'package:shelter_app/l10n/app_localizations.dart';

Widget _buildTestWidget(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      // NoSplash avoids a shader-loading crash on tester.tap() in this test
      // environment (unrelated to app behavior — ink_sparkle.frag can't be
      // decoded by the test runner's Skia build).
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('pl'),
      home: child,
    ),
  );
}

void main() {
  group('DogDetailScreen', () {
    testWidgets('shows dog name and shelter ID inline on profile tab',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        const DogDetailScreen(
          dogId: 1,
          dogName: 'Burek',
          shelterId: 'S-123',
          kennel: '4A',
          region: 'Dolna',
        ),
        overrides: [
          walkPartnersProvider(1)
              .overrideWith((ref) => Future.value(<WalkPartner>[])),
          dogWalkHistoryProvider(1)
              .overrideWith((ref) => Future.value(<DogWalkHistory>[])),
        ],
      ));
      await tester.pumpAndSettle();

      // Buddies is the default tab; switch to Profile.
      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();

      // Dog name displayed (in AppBar + profile tab header)
      expect(find.text('Burek'), findsNWidgets(2));
      // Shelter ID displayed inline (not as chip)
      expect(find.text('S-123'), findsOneWidget);
      // Kennel shown as chip
      expect(find.text('K: 4A'), findsOneWidget);
      // Region shown as chip
      expect(find.text('Dolna'), findsOneWidget);
    });

    testWidgets('hides shelter ID when null', (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        const DogDetailScreen(
          dogId: 2,
          dogName: 'Azor',
        ),
        overrides: [
          walkPartnersProvider(2)
              .overrideWith((ref) => Future.value(<WalkPartner>[])),
          dogWalkHistoryProvider(2)
              .overrideWith((ref) => Future.value(<DogWalkHistory>[])),
        ],
      ));
      await tester.pumpAndSettle();

      // Buddies is the default tab; switch to Profile.
      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();

      expect(find.text('Azor'), findsNWidgets(2));
      // No chips when no kennel/region
      expect(find.byType(Chip), findsNothing);
    });

    testWidgets('opens on the buddies tab by default', (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        const DogDetailScreen(
          dogId: 7,
          dogName: 'Sadełko',
        ),
        overrides: [
          walkPartnersProvider(7)
              .overrideWith((ref) => Future.value(<WalkPartner>[])),
          dogWalkHistoryProvider(7)
              .overrideWith((ref) => Future.value(<DogWalkHistory>[])),
        ],
      ));
      await tester.pumpAndSettle();

      final tabController = DefaultTabController.of(
        tester.element(find.byType(TabBarView)),
      );
      expect(tabController.index, 1);
    });

    testWidgets('shows tab labels from l10n', (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        const DogDetailScreen(
          dogId: 3,
          dogName: 'Rex',
        ),
        overrides: [
          walkPartnersProvider(3)
              .overrideWith((ref) => Future.value(<WalkPartner>[])),
          dogWalkHistoryProvider(3)
              .overrideWith((ref) => Future.value(<DogWalkHistory>[])),
        ],
      ));
      await tester.pumpAndSettle();

      // Polish l10n tab labels, all visible at once in the TabBar.
      expect(find.text('Profil'), findsOneWidget);
      expect(find.text('Psiumple'), findsOneWidget);
      expect(find.text('Spacery'), findsOneWidget);
    });

    testWidgets('shows empty state for walk partners on relationships tab',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        const DogDetailScreen(
          dogId: 4,
          dogName: 'Figa',
        ),
        overrides: [
          walkPartnersProvider(4)
              .overrideWith((ref) => Future.value(<WalkPartner>[])),
          dogWalkHistoryProvider(4)
              .overrideWith((ref) => Future.value(<DogWalkHistory>[])),
        ],
      ));
      await tester.pumpAndSettle();

      // Buddies is the default tab.
      expect(find.text('Brak partnerów spacerowych'), findsOneWidget);

      // Walks is the third tab; switch to it.
      await tester.tap(find.text('Spacery'));
      await tester.pumpAndSettle();
      expect(find.text('Brak spacerów'), findsOneWidget);
    });

    testWidgets('help button on relationships tab opens the level legend',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        const DogDetailScreen(
          dogId: 6,
          dogName: 'Kicia',
        ),
        overrides: [
          walkPartnersProvider(6)
              .overrideWith((ref) => Future.value(<WalkPartner>[])),
          dogWalkHistoryProvider(6)
              .overrideWith((ref) => Future.value(<DogWalkHistory>[])),
        ],
      ));
      await tester.pumpAndSettle();

      // Buddies is the default tab.
      await tester.tap(find.byIcon(Icons.help_outline_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Poziomy relacji'), findsOneWidget);
    });

    testWidgets('caps walk history to the last 20 walks', (tester) async {
      final walks = List.generate(
        25,
        (i) => DogWalkHistory(walkDate: '2026-01-${(i + 1).toString().padLeft(2, '0')}'),
      );
      await tester.pumpWidget(_buildTestWidget(
        const DogDetailScreen(
          dogId: 5,
          dogName: 'Luna',
        ),
        overrides: [
          walkPartnersProvider(5)
              .overrideWith((ref) => Future.value(<WalkPartner>[])),
          dogWalkHistoryProvider(5).overrideWith((ref) => Future.value(walks)),
        ],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Spacery'));
      await tester.pumpAndSettle();

      expect(find.text('Ostatnie 20 spacerów'), findsOneWidget);
      // Only the first 20 entries of the (API-sorted) list are rendered.
      expect(find.text('01.01'), findsOneWidget);
      expect(find.text('20.01'), findsOneWidget);
      expect(find.text('21.01'), findsNothing);
      expect(find.text('25.01'), findsNothing);
    });
  });
}
