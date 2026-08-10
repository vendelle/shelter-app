import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_app/features/dog_detail/presentation/widgets/profile_tab.dart';
import 'package:shelter_app/l10n/app_localizations.dart';

Widget _buildTestWidget({
  String dogName = 'Burek',
  String? shelterId,
  String? kennel,
  String? region,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(
      body: ProfileTab(
        dogName: dogName,
        shelterId: shelterId,
        kennel: kennel,
        region: region,
      ),
    ),
  );
}

void main() {
  group('ProfileTab', () {
    testWidgets('shows the shelter website link when shelterId parses',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(shelterId: '573/26'));

      expect(find.text('View on shelter website'), findsOneWidget);
    });

    testWidgets('hides the link when shelterId does not match the expected shape',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(shelterId: 'S010'));

      expect(find.text('View on shelter website'), findsNothing);
    });

    testWidgets('hides the link when shelterId is null', (tester) async {
      await tester.pumpWidget(_buildTestWidget());

      expect(find.text('View on shelter website'), findsNothing);
    });

    testWidgets('still shows name, shelterId text, and chips', (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        shelterId: '573/26',
        kennel: 'A1',
        region: 'D',
      ));

      expect(find.text('Burek'), findsOneWidget);
      expect(find.text('573/26'), findsOneWidget);
      expect(find.text('K: A1'), findsOneWidget);
      expect(find.text('D'), findsOneWidget);
    });
  });
}
