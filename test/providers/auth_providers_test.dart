import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_app/core/api/api_client.dart';
import 'package:shelter_app/features/auth/data/user_repository.dart';
import 'package:shelter_app/features/auth/domain/app_user.dart';
import 'package:shelter_app/features/auth/presentation/auth_providers.dart';

import '../fakes/fake_auth_service.dart';

class FakeUserRepository extends UserRepository {
  FakeUserRepository() : super(ApiClient(baseUrl: 'https://fake.test'));

  int fetchCalls = 0;

  @override
  Future<AppUser> fetchMe() async {
    fetchCalls++;
    return const AppUser(id: 1, email: 'anna@gmail.com', role: UserRole.volunteer);
  }
}

void main() {
  late FakeAuthService auth;
  late FakeUserRepository repo;
  late ProviderContainer container;

  ProviderContainer build(FakeAuthService service) {
    auth = service;
    repo = FakeUserRepository();
    return ProviderContainer(overrides: [
      authServiceProvider.overrideWithValue(auth),
      userRepositoryProvider.overrideWithValue(repo),
    ]);
  }

  tearDown(() => container.dispose());

  test('is anonymous while signed out', () async {
    container = build(FakeAuthService());
    expect(await container.read(currentUserProvider.future), isNull);
    expect(container.read(permissionsProvider).isSignedIn, isFalse);
    expect(repo.fetchCalls, 0);
  });

  test('loads the account from the API when signed in', () async {
    container = build(FakeAuthService(uid: 'uid-1'));
    final user = await container.read(currentUserProvider.future);
    expect(user?.role, UserRole.volunteer);
    expect(container.read(permissionsProvider).isSignedIn, isTrue);
  });

  test('follows sign-in and sign-out', () async {
    container = build(FakeAuthService());
    final sub = container.listen(currentUserProvider, (_, _) {});
    await container.read(currentUserProvider.future);

    await auth.signInWithGoogle();
    await pumpEventQueue();
    expect(container.read(currentUserProvider).valueOrNull?.email,
        'anna@gmail.com');

    await auth.signOut();
    await pumpEventQueue();
    expect(container.read(currentUserProvider).valueOrNull, isNull);
    sub.close();
  });
}
