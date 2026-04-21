import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_providers.dart';
import '../data/auth_repository.dart';
import '../domain/app_user.dart';

// ---------------------------------------------------------------------------
// Firebase auth state (raw stream from Firebase)
// ---------------------------------------------------------------------------

final firebaseAuthProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// ---------------------------------------------------------------------------
// Auth repository
// ---------------------------------------------------------------------------

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(apiClient: ref.watch(apiClientProvider));
});

// ---------------------------------------------------------------------------
// App user (backend user record, fetched after Firebase auth)
// ---------------------------------------------------------------------------

final appUserProvider =
    AsyncNotifierProvider<AppUserNotifier, AppUser?>(AppUserNotifier.new);

class AppUserNotifier extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return null;

    final idToken = await firebaseUser.getIdToken();
    if (idToken == null) return null;

    final repo = ref.read(authRepositoryProvider);
    try {
      return await repo.loginWithToken(idToken);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        // Token invalid on backend — sign out
        await FirebaseAuth.instance.signOut();
        return null;
      }
      rethrow;
    }
  }

  /// Sign in with Google and register/fetch the backend user.
  Future<AppUser?> signInWithGoogle({int? volunteerId}) async {
    state = const AsyncLoading();

    try {
      UserCredential credential;

      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        credential =
            await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) {
          state = const AsyncData(null);
          return null; // User cancelled
        }
        final googleAuth = await googleUser.authentication;
        final oauthCredential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        credential = await FirebaseAuth.instance
            .signInWithCredential(oauthCredential);
      }

      final idToken = await credential.user?.getIdToken();
      if (idToken == null) {
        state = const AsyncData(null);
        return null;
      }

      final repo = ref.read(authRepositoryProvider);
      final user =
          await repo.loginWithToken(idToken, volunteerId: volunteerId);
      state = AsyncData(user);
      return user;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  /// Sign out from Firebase and clear the backend user.
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!kIsWeb) {
      await GoogleSignIn().signOut();
    }
    state = const AsyncData(null);
  }

  /// Refresh the user from the backend (e.g. after role change).
  Future<void> refresh() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      state = const AsyncData(null);
      return;
    }

    final idToken = await firebaseUser.getIdToken(true);
    if (idToken == null) {
      state = const AsyncData(null);
      return;
    }

    final repo = ref.read(authRepositoryProvider);
    final user = await repo.loginWithToken(idToken);
    state = AsyncData(user);
  }
}
