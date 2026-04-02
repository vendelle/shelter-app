import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_app/features/planner/presentation/widgets/date_navigator.dart';
import 'package:shelter_app/l10n/app_localizations.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(body: child),
  );
}

void main() {
  group('DateNavigator', () {
    testWidgets('displays formatted date', (tester) async {
      await tester.pumpWidget(
        _wrap(
          DateNavigator(
            date: DateTime(2026, 3, 31),
            onDateChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Format: "Tue, Mar 31" (or "Today, Mar 31" if today)
      // March 31, 2026 is a Tuesday
      expect(find.textContaining('Mar 31'), findsOneWidget);
    });

    testWidgets('left arrow goes to previous day', (tester) async {
      DateTime? newDate;
      await tester.pumpWidget(
        _wrap(
          DateNavigator(
            date: DateTime(2026, 3, 31),
            onDateChanged: (d) => newDate = d,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      expect(newDate, DateTime(2026, 3, 30));
    });

    testWidgets('right arrow goes to next day', (tester) async {
      DateTime? newDate;
      await tester.pumpWidget(
        _wrap(
          DateNavigator(
            date: DateTime(2026, 3, 31),
            onDateChanged: (d) => newDate = d,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      expect(newDate, DateTime(2026, 4, 1));
    });

    testWidgets('shows calendar icon', (tester) async {
      await tester.pumpWidget(
        _wrap(
          DateNavigator(
            date: DateTime(2026, 3, 31),
            onDateChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.calendar_today_rounded), findsOneWidget);
    });
  });
}
