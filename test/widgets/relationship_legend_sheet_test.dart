import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_app/features/dog_detail/presentation/widgets/relationship_legend_sheet.dart';
import 'package:shelter_app/l10n/app_localizations.dart';

Widget _buildTestWidget() {
  return MaterialApp(
    theme: ThemeData(splashFactory: NoSplash.splashFactory),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('pl'),
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => showRelationshipLegend(context),
            child: const Text('open legend'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('RelationshipLegendSheet', () {
    testWidgets('shows title, every level badge + description, and the contact note',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.tap(find.text('open legend'));
      await tester.pumpAndSettle();

      expect(find.text('Poziomy relacji'), findsOneWidget);

      // All six levels, their short badges and their full descriptions.
      expect(find.text('Wybieg'), findsOneWidget);
      expect(find.textContaining('mogą swobodnie dzielić wybieg'), findsOneWidget);

      expect(find.text('Kontakt+'), findsOneWidget);
      expect(find.textContaining('nie mają żadnych (poważnych) spięć'), findsOneWidget);

      expect(find.text('Kontakt-'), findsOneWidget);
      expect(find.textContaining('trzeba moderować interakcję'), findsOneWidget);

      expect(find.text('Równo+'), findsOneWidget);
      expect(find.textContaining('nie próbowaliśmy jeszcze iść w kontakcie'), findsOneWidget);

      expect(find.text('Równo-'), findsOneWidget);
      expect(find.textContaining('widzimy przyszłość w pracy nad tą relacją'), findsOneWidget);

      expect(find.text('Nie'), findsOneWidget);
      expect(find.textContaining('nie parujemy ich'), findsOneWidget);

      // The contact note sits below the fold; scroll the sheet to reach it.
      await tester.dragUntilVisible(
        find.textContaining('W kontakcie:'),
        find.byType(Scrollable),
        const Offset(0, -100),
      );
      expect(find.textContaining('W kontakcie:'), findsOneWidget);
    });

    testWidgets('closes via the close button', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.tap(find.text('open legend'));
      await tester.pumpAndSettle();
      expect(find.text('Poziomy relacji'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Poziomy relacji'), findsNothing);
    });
  });
}
