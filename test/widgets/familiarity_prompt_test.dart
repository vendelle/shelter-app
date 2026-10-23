import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_app/features/auth/domain/app_user.dart';
import 'package:shelter_app/features/dog_detail/presentation/providers/dog_detail_providers.dart';
import 'package:shelter_app/features/manage/presentation/providers/manage_providers.dart';
import 'package:shelter_app/features/manage/presentation/widgets/familiarity_prompt.dart';
import 'package:shelter_app/features/planner/domain/planner_dog.dart';
import 'package:shelter_app/features/shared/domain/dog.dart';
import 'package:shelter_app/features/shared/domain/volunteer.dart';
import 'package:shelter_app/l10n/app_localizations.dart';

import '../fakes/fake_auth_service.dart';

const _anna = Volunteer(id: 7, firstName: 'Anna', lastName: 'Kowalska');
const _burek = Dog(id: 1, name: 'Burek', shelterId: '1/26', kennel: '412');
const _luna = Dog(id: 2, name: 'Luna', shelterId: '2/26', kennel: '430');
const _old = Dog(
  id: 3,
  name: 'Stary',
  shelterId: '3/20',
  kennel: '101',
  archived: true,
);

AppUser _user({int? volunteerId = 7}) => AppUser(
  id: 1,
  email: 'anna@gmail.com',
  volunteerId: volunteerId,
  role: UserRole.volunteer,
);

void main() {
  Future<void> pumpPrompt(
    WidgetTester tester, {
    AppUser? user,
    Map<int, DogFamiliarityLevel> ratings = const {},
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...signedInAs(user ?? _user()),
          managedDogsProvider.overrideWith(
            (ref) async => [_burek, _luna, _old],
          ),
          managedVolunteersProvider.overrideWith((ref) async => [_anna]),
          familiarityProvider.overrideWith((ref, id) async => ratings),
          dogPhotoUrlsProvider.overrideWith((ref) async => const {}),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const FamiliarityPrompt(child: Scaffold(body: Text('home'))),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('asks for the missing ratings, with a legend and no kennels', (
    tester,
  ) async {
    await pumpPrompt(tester, ratings: {1: DogFamiliarityLevel.good});

    expect(
      find.text('Mark which dogs you walk'),
      findsOneWidget,
    );
    expect(find.text('I walk them with no problem'), findsOneWidget);
    expect(
      find.text("Sometimes hard, but I'll walk them if I have to"),
      findsOneWidget,
    );
    expect(find.text("I don't walk this dog"), findsOneWidget);
    expect(find.text('Not rated'), findsOneWidget);
    expect(find.text('Burek'), findsOneWidget);
    expect(find.text('Luna'), findsOneWidget);
    expect(find.text('Stary'), findsNothing);
    expect(find.textContaining('Kennel'), findsNothing);
  });

  testWidgets('stays quiet when every active dog is rated', (tester) async {
    await pumpPrompt(
      tester,
      ratings: {1: DogFamiliarityLevel.good, 2: DogFamiliarityLevel.never},
    );

    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('stays quiet when the account is not linked to a volunteer', (
    tester,
  ) async {
    await pumpPrompt(tester, user: _user(volunteerId: null));

    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('asks only once per app start', (tester) async {
    await pumpPrompt(tester);
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });
}
