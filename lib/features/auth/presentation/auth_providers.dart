import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/demo_mode.dart';
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
    // Demo mode: auto-login as demo user
    if (isDemoMode) {
      try {
        final repo = ref.read(authRepositoryProvider);
        return await repo.getDemoUser();
      } catch (_) {
        // If demo endpoint fails, continue as guest
        return null;
      }
    }

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
      if (kDebugMode) print('Starting Google Sign-In...');
      
      UserCredential credential;

      if (kIsWeb) {
        if (kDebugMode) print('Web platform: using signInWithPopup');
        final provider = GoogleAuthProvider();
        try {
          credential =
              await FirebaseAuth.instance.signInWithPopup(provider);
          if (kDebugMode) print('signInWithPopup succeeded');
        } catch (e) {
          if (kDebugMode) print('signInWithPopup failed: $e');
          rethrow;
        }
      } else {
        if (kDebugMode) print('Mobile platform: using GoogleSignIn');
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
        if (kDebugMode) print('Failed to get ID token');
        state = const AsyncData(null);
        return null;
      }

      if (kDebugMode) print('Got ID token, logging in with backend...');
      final repo = ref.read(authRepositoryProvider);
      final user =
          await repo.loginWithToken(idToken, volunteerId: volunteerId);
      if (kDebugMode) print('Backend login succeeded: ${user?.email}');
      state = AsyncData(user);
      return user;
    } catch (e, st) {
      if (kDebugMode) print('Sign-in error: $e\n$st');
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
