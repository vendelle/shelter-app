import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_app/features/auth/domain/app_user.dart';
import 'package:shelter_app/features/auth/presentation/auth_providers.dart';
import 'package:shelter_app/features/auth/presentation/widgets/auth_gate.dart';
import 'package:shelter_app/features/auth/presentation/widgets/welcome_screen.dart';
import 'package:shelter_app/features/shared/presentation/shelter_image.dart';
import 'package:shelter_app/l10n/app_localizations.dart';

import '../fakes/fake_auth_service.dart';

void main() {
  Future<void> pumpGate(
    WidgetTester tester,
    AppUser? user, {
    List<String> photos = const [],
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(FakeAuthService()),
          currentUserProvider.overrideWith((ref) => Stream.value(user)),
          welcomePhotosProvider.overrideWith((ref) async => photos),
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

  testWidgets('signed out: the welcome screen with dog photos', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpGate(tester, null, photos: ['https://images.example/1.jpg']);
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.text('Asowa Psiappka'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
    // One photo; the other 11 tiles show a paw.
    expect(
      tester.widget<ShelterImage>(find.byType(ShelterImage)).url,
      'https://images.example/1.jpg',
    );
    expect(find.text('the app'), findsNothing);
  });

  testWidgets('signed out on a phone: a shorter button label that fits',
      (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpGate(tester, null);
    expect(find.text('Sign in'), findsOneWidget);
    expect(tester.takeException(), isNull);
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
