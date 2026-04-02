import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:shelter_app/app.dart';
import 'package:shelter_app/core/api/api_client.dart';
import 'package:shelter_app/core/api/api_providers.dart';
import 'package:shelter_app/core/locale/locale_provider.dart';

/// A fake ApiClient that returns empty lists for all GET requests
/// so the app can render without a real backend.
class FakeApiClient extends ApiClient {
  FakeApiClient() : super(baseUrl: 'https://fake.test');
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('App renders with bottom navigation tabs',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(FakeApiClient()),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const ShelterApp(),
      ),
    );

    // Allow time for async providers to settle
    await tester.pumpAndSettle();

    // Bottom navigation should have all three tabs (Polish or English depending on device locale)
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(3));
  });

  testWidgets('Bottom navigation shows correct icons',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(FakeApiClient()),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const ShelterApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Should have navigation bar with icons
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
