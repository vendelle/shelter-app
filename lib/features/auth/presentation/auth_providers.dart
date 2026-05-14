import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/debug_logger.dart';
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
    try {
      DebugLogger.log('AppUserNotifier.build() called');
      
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

      // Check current user - popups return immediately, so no redirect handling needed
      DebugLogger.log('Checking FirebaseAuth.instance.currentUser...');
      final firebaseUser = FirebaseAuth.instance.currentUser;
      DebugLogger.log('currentUser: ${firebaseUser?.email}');
      
      if (firebaseUser == null) {
        DebugLogger.log('No current user, returning null');
        return null;
      }

      DebugLogger.log('Found authenticated user: ${firebaseUser.email}');
      final idToken = await firebaseUser.getIdToken();
      if (idToken == null) {
        DebugLogger.log('No ID token, returning null');
        return null;
      }

      final repo = ref.read(authRepositoryProvider);
      try {
        DebugLogger.log('Calling loginWithToken() with backend...');
        final user = await repo.loginWithToken(idToken);
        DebugLogger.log('loginWithToken() succeeded: ${user?.email}');
        return user;
      } on ApiException catch (e) {
        DebugLogger.log('loginWithToken() failed: ${e.statusCode} - ${e.toString()}');
        if (e.statusCode == 401) {
          // Token invalid on backend — sign out
          await FirebaseAuth.instance.signOut();
          return null;
        }
        rethrow;
      }
    } catch (e, st) {
      DebugLogger.log('FATAL ERROR in build(): $e\n$st');
      print('FATAL ERROR: $e\n$st');
      rethrow;
    }
  }

  /// Sign in with Google and register/fetch the backend user.
  Future<AppUser?> signInWithGoogle({int? volunteerId}) async {
    state = const AsyncLoading();

    try {
      DebugLogger.log('Starting Google Sign-In...');
      
      UserCredential credential;

      if (kIsWeb) {
        DebugLogger.log('Web platform: using Firebase signInWithPopup');
        final provider = GoogleAuthProvider();
        try {
          DebugLogger.log('Attempting to show sign-in popup...');
          credential = await FirebaseAuth.instance.signInWithPopup(provider);
          DebugLogger.log('Popup sign-in succeeded: ${credential.user?.email}');
        } on FirebaseAuthException catch (e) {
          if (e.code == 'popup-blocked') {
            DebugLogger.log('Popup was blocked by browser - disabling popup blocker or try again');
            state = AsyncError(
              Exception('Sign-in popup was blocked. Please disable your popup blocker and try again.'),
              StackTrace.current,
            );
          } else {
            DebugLogger.log('Firebase auth error: ${e.code} - ${e.message}');
            state = AsyncError(e, StackTrace.current);
          }
          return null;
        } catch (e, st) {
          DebugLogger.log('ERROR in sign-in popup: $e\nStacktrace: $st');
          state = AsyncError(e, st);
          return null;
        }
      } else {
        DebugLogger.log('Mobile platform: using Google Sign-In SDK');
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) {
          DebugLogger.log('Google Sign-In cancelled by user');
          state = const AsyncData(null);
          return null;
        }
        final googleAuth = await googleUser.authentication;
        if (googleAuth == null) {
          DebugLogger.log('ERROR: googleAuth is null on mobile');
          state = const AsyncData(null);
          return null;
        }
        final oauthCredential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        credential = await FirebaseAuth.instance
            .signInWithCredential(oauthCredential);
      }

      final user = credential.user;
      if (user == null) {
        DebugLogger.log('ERROR: credential.user is null after sign-in');
        state = const AsyncData(null);
        return null;
      }

      final idToken = await user.getIdToken();
      if (idToken == null) {
        DebugLogger.log('Failed to get ID token from Firebase user');
        state = const AsyncData(null);
        return null;
      }

      DebugLogger.log('Got ID token, logging in with backend...');
      final repo = ref.read(authRepositoryProvider);
      final appUser =
          await repo.loginWithToken(idToken, volunteerId: volunteerId);
      DebugLogger.log('Backend login succeeded: ${appUser?.email}');
      state = AsyncData(appUser);
      return appUser;
    } catch (e, st) {
      DebugLogger.log('Sign-in error: $e\n$st');
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
