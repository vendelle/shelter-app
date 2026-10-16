import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_app/features/auth/data/auth_service.dart';
import 'package:shelter_app/features/auth/domain/app_user.dart';
import 'package:shelter_app/features/auth/presentation/auth_providers.dart';
import 'package:shelter_app/features/auth/presentation/widgets/account_button.dart';
import 'package:shelter_app/l10n/app_localizations.dart';

import '../fakes/fake_auth_service.dart';

void main() {
  late FakeAuthService auth;

  Future<void> pumpButton(WidgetTester tester, {AppUser? user}) async {
    auth = FakeAuthService(uid: user == null ? null : 'uid');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(auth),
          currentUserProvider.overrideWith((ref) => Stream.value(user)),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(appBar: AppBar(actions: const [AccountButton()])),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AccountButton));
    await tester.pumpAndSettle();
  }

  testWidgets('signed out: offers Google sign-in', (tester) async {
    await pumpButton(tester);

    await tester.tap(find.text('Sign in with Google'));
    await tester.pumpAndSettle();

    expect(auth.signInCalls, 1);
  });

  testWidgets('explains a blocked popup', (tester) async {
    await pumpButton(tester);
    auth.signInError = const SignInException(SignInFailure.popupBlocked);

    await tester.tap(find.text('Sign in with Google'));
    await tester.pumpAndSettle();

    expect(find.textContaining('blocked the Google sign-in window'),
        findsOneWidget);
  });

  testWidgets('pending account: explains the wait and can sign out',
      (tester) async {
    await pumpButton(
      tester,
      user: const AppUser(
        id: 1,
        email: 'anna@gmail.com',
        displayName: 'Anna K',
        role: UserRole.pending,
      ),
    );

    expect(find.text('Anna K'), findsOneWidget);
    expect(find.text('Access: Waiting for approval'), findsOneWidget);
    expect(find.textContaining('waiting for an admin'), findsOneWidget);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(await auth.idToken(), isNull);
  });
}
