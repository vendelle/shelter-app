import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../data/auth_service.dart';
import '../data/user_repository.dart';
import '../domain/app_user.dart';
import '../domain/user_account.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return FirebaseAuthService();
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(apiClientProvider));
});

/// The signed-in account, or null when signed out. Follows Google sign-in
/// state; invalidate it to re-fetch after a role change.
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final repo = ref.watch(userRepositoryProvider);
  return ref
      .watch(authServiceProvider)
      .accountChanges()
      .asyncMap((uid) => uid == null ? null : repo.fetchMe());
});

/// What the current visitor may change. Anonymous until the account loads.
final permissionsProvider = Provider<Permissions>((ref) {
  return Permissions(ref.watch(currentUserProvider).valueOrNull);
});

/// Photo URLs of a few current dogs for the sign-in screen (a public
/// endpoint). Empty when they can't be loaded — the screen works without.
final welcomePhotosProvider = FutureProvider<List<String>>((ref) async {
  try {
    final data = await ref
        .read(apiClientProvider)
        .get('/api/dogs', queryParams: {'shelter': 'photos'}) as List;
    return data.cast<String>();
  } catch (_) {
    return const [];
  }
});

/// All accounts and invites (user management, super_admin only).
final userAccountsProvider =
    FutureProvider.autoDispose<List<UserAccount>>((ref) {
  return ref.watch(userRepositoryProvider).getAccounts();
});
