import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_app/features/auth/domain/app_user.dart';
import 'package:shelter_app/features/dog_detail/presentation/providers/dog_detail_providers.dart';
import 'package:shelter_app/features/manage/presentation/providers/manage_providers.dart';
import 'package:shelter_app/features/manage/presentation/widgets/dogs_tab.dart';
import 'package:shelter_app/features/shared/domain/dog.dart';
import 'package:shelter_app/l10n/app_localizations.dart';

import '../fakes/fake_auth_service.dart';

const _admin = AppUser(id: 3, email: 'admin@test.pl', role: UserRole.admin);

void main() {
  Future<void> pumpTab(WidgetTester tester, AppUser user) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        ...signedInAs(user),
        managedDogsProvider.overrideWith((ref) async => const [
              Dog(id: 1, name: 'Amigo', shelterId: '573/26', kennel: '412'),
              Dog(id: 2, name: 'Burek', shelterId: '1/26', kennel: '118'),
            ]),
        locationSuggestionDogIdsProvider.overrideWith((ref) async => {1}),
      ],
      child: MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        locale: const Locale('pl'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: DogsTab()),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('admins can filter to dogs with another kennel on the website',
      (tester) async {
    await pumpTab(tester, _admin);
    expect(find.text('Burek'), findsOneWidget);

    await tester.tap(find.text('Inny boks na stronie (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Amigo'), findsOneWidget);
    expect(find.text('Burek'), findsNothing);
  });

  testWidgets('volunteers do not see the filter', (tester) async {
    await pumpTab(tester, testVolunteer);
    expect(find.textContaining('Inny boks na stronie'), findsNothing);
  });
}
