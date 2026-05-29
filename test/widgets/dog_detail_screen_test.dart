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
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('pl'),
      home: child,
    ),
  );
}

void main() {
  group('DogDetailScreen', () {
    testWidgets('shows dog name and shelter ID inline', (tester) async {
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

      // Dog name displayed (in AppBar + header)
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

      expect(find.text('Azor'), findsNWidgets(2));
      // No chips when no kennel/region
      expect(find.byType(Chip), findsNothing);
    });

    testWidgets('shows section titles from l10n', (tester) async {
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

      // Polish l10n titles
      expect(find.text('Ziomki'), findsOneWidget);
      expect(find.text('Historia spacerów'), findsOneWidget);
    });

    testWidgets('shows empty state for walk partners', (tester) async {
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

      expect(find.text('Brak partnerów spacerowych'), findsOneWidget);
      expect(find.text('Brak spacerów'), findsOneWidget);
    });
  });
}
