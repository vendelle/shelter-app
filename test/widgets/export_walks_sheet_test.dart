import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_app/features/overview/presentation/widgets/export_walks_sheet.dart';
import 'package:shelter_app/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Widget buildTestWidget({ExportWalksSheet sheet = const ExportWalksSheet()}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => sheet,
            );
          },
          child: const Text('Open Export'),
        ),
      ),
    ),
  );
}

void main() {
  group('ExportWalksSheet', () {
    testWidgets('renders title and date pickers', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.tap(find.text('Open Export'));
      await tester.pumpAndSettle();

      expect(find.text('Export walks'), findsOneWidget);
      expect(find.text('From'), findsOneWidget);
      expect(find.text('To'), findsOneWidget);
      expect(find.text('Download CSV'), findsOneWidget);
    });

    testWidgets('shows download icon', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.tap(find.text('Open Export'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.download_rounded), findsOneWidget);
    });

    testWidgets('shows calendar icons for date pickers', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.tap(find.text('Open Export'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.calendar_today), findsNWidgets(2));
    });

    testWidgets('from date defaults to 3 months ago', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.tap(find.text('Open Export'));
      await tester.pumpAndSettle();

      final now = DateTime.now();
      final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
      final expectedFrom =
          '${threeMonthsAgo.day.toString().padLeft(2, '0')}.${threeMonthsAgo.month.toString().padLeft(2, '0')}.${threeMonthsAgo.year}';

      expect(find.text(expectedFrom), findsOneWidget);
    });

    testWidgets('to date defaults to today', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.tap(find.text('Open Export'));
      await tester.pumpAndSettle();

      final now = DateTime.now();
      final expectedTo =
          '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';

      expect(find.text(expectedTo), findsOneWidget);
    });

    testWidgets('tapping from date opens date picker', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.tap(find.text('Open Export'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('From'));
      await tester.pumpAndSettle();

      // DatePicker dialog should appear
      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('tapping to date opens date picker', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.tap(find.text('Open Export'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('To'));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('tapping CSV button builds expected URL and closes on success', (
      tester,
    ) async {
      String? capturedUrl;
      await tester.pumpWidget(
        buildTestWidget(
          sheet: ExportWalksSheet(
            downloadCsv: (url) async {
              capturedUrl = url;
            },
          ),
        ),
      );
      await tester.tap(find.text('Open Export'));
      await tester.pumpAndSettle();

      final now = DateTime.now();
      final from = DateTime(now.year, now.month - 3, now.day);
      final expectedFrom =
          '${from.year}-${from.month.toString().padLeft(2, '0')}-${from.day.toString().padLeft(2, '0')}';
      final expectedTo =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      await tester.tap(find.text('Download CSV'));
      await tester.pumpAndSettle();

      expect(
        capturedUrl,
        'https://shelter-app-plum.vercel.app/api/walks?format=csv&from=$expectedFrom&to=$expectedTo',
      );
      expect(find.text('Export walks'), findsNothing);
    });

    testWidgets('shows snackbar when CSV download fails', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          sheet: ExportWalksSheet(
            downloadCsv: (_) async {
              throw Exception('download failed');
            },
          ),
        ),
      );
      await tester.tap(find.text('Open Export'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Download CSV'));
      await tester.pumpAndSettle();

      expect(find.text('Export failed'), findsOneWidget);
      expect(find.text('Export walks'), findsOneWidget);
    });
  });
}
