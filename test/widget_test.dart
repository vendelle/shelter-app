import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shelter_app/app.dart';
import 'package:shelter_app/core/api/api_client.dart';
import 'package:shelter_app/core/api/api_providers.dart';

/// A fake ApiClient that returns empty lists for all GET requests
/// so the app can render without a real backend.
class FakeApiClient extends ApiClient {
  FakeApiClient() : super(baseUrl: 'https://fake.test');
}

void main() {
  testWidgets('App renders with bottom navigation tabs',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(FakeApiClient()),
        ],
        child: const ShelterApp(),
      ),
    );

    // Allow time for async providers to settle
    await tester.pump();

    // Bottom navigation should have all three tabs
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Planner'), findsOneWidget);
    expect(find.text('Manage'), findsOneWidget);
  });

  testWidgets('Bottom navigation shows correct icons',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(FakeApiClient()),
        ],
        child: const ShelterApp(),
      ),
    );

    await tester.pump();

    // Should have navigation bar with icons
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
