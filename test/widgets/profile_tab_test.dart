import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_app/features/auth/domain/app_user.dart';
import 'package:shelter_app/features/dog_detail/domain/shelter_profile.dart';
import 'package:shelter_app/features/dog_detail/presentation/providers/dog_detail_providers.dart';
import 'package:shelter_app/features/dog_detail/presentation/widgets/profile_tab.dart';
import 'package:shelter_app/l10n/app_localizations.dart';

import '../fakes/fake_auth_service.dart';
import '../fakes/fake_dog_detail_repository.dart';

const _admin = AppUser(id: 3, email: 'admin@test.pl', role: UserRole.admin);

ShelterProfile _profile({
  DateTime? fetchedAt,
  bool found = true,
  LocationSuggestion? suggestion,
  bool refreshFailed = false,
}) {
  return ShelterProfile(
    dogId: 12,
    kennel: '412',
    region: 'R12',
    url: 'https://napaluchu.waw.pl/animal/0573-26p/',
    found: found,
    status: 'Do adopcji',
    sex: 'Samiec',
    birthDate: DateTime(2020, 12, 19),
    weightKg: 24.5,
    neutered: true,
    arrivalDate: DateTime(2026, 6, 20),
    arrivalReason: 'zwrot z adopcji',
    location: '430 R12 (domek)',
    description: 'Amigo to mądry pies.',
    fetchedAt: fetchedAt ?? DateTime.now(),
    locationSuggestion: suggestion,
    refreshFailed: refreshFailed,
  );
}

void main() {
  late FakeDogDetailRepository repo;

  Future<void> pumpTab(WidgetTester tester, ShelterProfile profile,
      {AppUser user = testVolunteer, ShelterProfile? afterRefresh}) async {
    repo = FakeDogDetailRepository(profile: profile, afterRefresh: afterRefresh);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        ...signedInAs(user),
        dogDetailRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        locale: const Locale('pl'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: ProfileTab(
            dogId: 12,
            dogName: 'Amigo',
            shelterId: '573/26',
            kennel: '412',
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('shows what the shelter website says', (tester) async {
    await pumpTab(tester, _profile());

    expect(find.text('Ze strony schroniska'), findsOneWidget);
    expect(find.text('Do adopcji'), findsOneWidget);
    expect(find.text('24,5 kg'), findsOneWidget);
    expect(find.text('20.06.2026 · zwrot z adopcji'), findsOneWidget);
    expect(find.text('430 R12 (domek)'), findsOneWidget);
    expect(find.text('Amigo to mądry pies.'), findsOneWidget);
    expect(find.text('Zobacz na stronie schroniska'), findsOneWidget);
    expect(find.text('odświeżono przed chwilą'), findsOneWidget);
  });

  testWidgets('says when the website has no such dog', (tester) async {
    await pumpTab(tester, _profile(found: false));

    expect(find.text('Strona schroniska nie ma psa o numerze 573/26.'),
        findsOneWidget);
    expect(find.text('Do adopcji'), findsNothing);
  });

  group('Odśwież teraz', () {
    Finder refreshButton() =>
        find.widgetWithText(TextButton, 'Odśwież teraz');

    testWidgets('is disabled right after a refresh', (tester) async {
      await pumpTab(tester, _profile());
      expect(tester.widget<TextButton>(refreshButton()).onPressed, isNull);
    });

    testWidgets('fetches again once the cooldown has passed', (tester) async {
      await pumpTab(
        tester,
        _profile(fetchedAt: DateTime.now().subtract(const Duration(hours: 2))),
        afterRefresh: _profile(),
      );
      expect(find.text('odświeżono 2 godz. temu'), findsOneWidget);

      await tester.tap(refreshButton());
      await tester.pumpAndSettle();

      expect(repo.refreshCalls, 1);
      expect(find.text('odświeżono przed chwilą'), findsOneWidget);
    });

    testWidgets('explains when the website is down', (tester) async {
      await pumpTab(
        tester,
        _profile(fetchedAt: DateTime.now().subtract(const Duration(hours: 2))),
        afterRefresh: _profile(
          fetchedAt: DateTime.now().subtract(const Duration(hours: 2)),
          refreshFailed: true,
        ),
      );

      await tester.tap(refreshButton());
      await tester.pumpAndSettle();

      expect(find.textContaining('Strona schroniska nie odpowiada'),
          findsOneWidget);
    });
  });

  group('kennel suggestion', () {
    final suggested = _profile(
      suggestion: const LocationSuggestion(kennel: '430', region: 'R12'),
    );

    testWidgets('lets an admin accept the website kennel', (tester) async {
      await pumpTab(tester, suggested, user: _admin);

      expect(find.text('Na stronie: 430 R12 (domek)'), findsOneWidget);
      expect(find.text('U nas: 412 R12'), findsOneWidget);

      await tester.tap(find.text('Przyjmij'));
      await tester.pumpAndSettle();

      expect(repo.resolved, [true]);
      expect(find.text('Na stronie: 430 R12 (domek)'), findsNothing);
      expect(find.text('K: 430'), findsOneWidget);
    });

    testWidgets('lets an admin ignore it', (tester) async {
      await pumpTab(tester, suggested, user: _admin);

      await tester.tap(find.text('Ignoruj'));
      await tester.pumpAndSettle();

      expect(repo.resolved, [false]);
      expect(find.text('K: 412'), findsOneWidget);
    });

    testWidgets('is not shown to volunteers', (tester) async {
      await pumpTab(tester, suggested);
      expect(find.text('Przyjmij'), findsNothing);
    });
  });
}
