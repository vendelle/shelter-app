import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_app/features/auth/domain/app_user.dart';
import 'package:shelter_app/features/auth/presentation/auth_providers.dart';
import 'package:shelter_app/features/auth/presentation/widgets/auth_gate.dart';
import 'package:shelter_app/l10n/app_localizations.dart';

import '../fakes/fake_auth_service.dart';

void main() {
  Future<void> pumpGate(WidgetTester tester, AppUser? user) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(FakeAuthService()),
          currentUserProvider.overrideWith((ref) => Stream.value(user)),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => AuthGate(child: child!),
          home: const Text('the app'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  AppUser user(UserRole role) =>
      AppUser(id: 1, email: 'anna@gmail.com', role: role);

  testWidgets('signed out: only the sign-in panel', (tester) async {
    await pumpGate(tester, null);
    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(find.text('the app'), findsNothing);
  });

  testWidgets('pending: explains the wait, app stays hidden', (tester) async {
    await pumpGate(tester, user(UserRole.pending));
    expect(find.textContaining('waiting for an admin'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
    expect(find.text('the app'), findsNothing);
  });

  testWidgets('volunteer: shows the app', (tester) async {
    await pumpGate(tester, user(UserRole.volunteer));
    expect(find.text('the app'), findsOneWidget);
  });

  testWidgets('exporter: only the CSV export, app stays hidden', (tester) async {
    await pumpGate(tester, user(UserRole.exporter));
    expect(find.text('Download CSV'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
    expect(find.text('the app'), findsNothing);
  });
}
