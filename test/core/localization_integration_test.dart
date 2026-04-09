import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:shelter_app/app.dart';
import 'package:shelter_app/core/api/api_client.dart';
import 'package:shelter_app/core/api/api_providers.dart';
import 'package:shelter_app/core/locale/locale_provider.dart';

class FakeApiClient extends ApiClient {
  FakeApiClient() : super(baseUrl: 'https://fake.test');
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('Polish locale', () {
    testWidgets('shows Polish navigation labels when locale is pl',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(FakeApiClient()),
            sharedPreferencesProvider.overrideWithValue(prefs),
            localeProvider.overrideWith((_) => LocaleNotifier(prefs)
              ..setLocale(const Locale('pl'))),
          ],
          child: const ShelterApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Przegląd'), findsOneWidget);
      expect(find.text('Planer'), findsOneWidget);
      expect(find.text('Zarządzaj'), findsOneWidget);
    });
  });

  group('English locale', () {
    testWidgets('shows English navigation labels when locale is en',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(FakeApiClient()),
            sharedPreferencesProvider.overrideWithValue(prefs),
            localeProvider.overrideWith((_) => LocaleNotifier(prefs)
              ..setLocale(const Locale('en'))),
          ],
          child: const ShelterApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Planner'), findsOneWidget);
      expect(find.text('Manage'), findsOneWidget);
    });
  });

  group('Language toggle', () {
    testWidgets('manage screen shows language toggle button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(FakeApiClient()),
            sharedPreferencesProvider.overrideWithValue(prefs),
            localeProvider.overrideWith((_) => LocaleNotifier(prefs)
              ..setLocale(const Locale('pl'))),
          ],
          child: const ShelterApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Manage tab
      await tester.tap(find.text('Zarządzaj'));
      await tester.pumpAndSettle();

      // Should show Polish flag
      expect(find.text('🇵🇱'), findsOneWidget);
    });

    testWidgets('tapping language toggle switches locale', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(FakeApiClient()),
            sharedPreferencesProvider.overrideWithValue(prefs),
            localeProvider.overrideWith((_) => LocaleNotifier(prefs)
              ..setLocale(const Locale('pl'))),
          ],
          child: const ShelterApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Manage tab
      await tester.tap(find.text('Zarządzaj'));
      await tester.pumpAndSettle();

      // Tap language toggle (Polish flag)
      await tester.tap(find.text('🇵🇱'));
      await tester.pumpAndSettle();

      // Should now show English flag and English tabs
      expect(find.text('🇬🇧'), findsOneWidget);
      expect(find.text('Dogs'), findsOneWidget);
      expect(find.text('Volunteers'), findsOneWidget);
    });
  });
}
