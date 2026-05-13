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
    if (kDebugMode) print('AppUserNotifier.build() called');
    
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

    // Check for redirect result from Google Sign-In (web only)
    if (kDebugMode) print('Checking getRedirectResult()...');
    try {
      final result = await FirebaseAuth.instance.getRedirectResult();
      if (kDebugMode) print('getRedirectResult() returned: user=${result.user?.email}, credential=${result.credential}');
      
      if (result.user != null) {
        if (kDebugMode) print('Got redirect result from Google Sign-In: ${result.user!.email}');
        final idToken = await result.user!.getIdToken();
        if (kDebugMode) print('Got ID token: ${idToken?.substring(0, 20)}...');
        
        if (idToken != null) {
          final repo = ref.read(authRepositoryProvider);
          try {
            if (kDebugMode) print('Calling loginWithToken() with backend...');
            final user = await repo.loginWithToken(idToken);
            if (kDebugMode) print('loginWithToken() succeeded: ${user?.email}');
            return user;
          } on ApiException catch (e) {
            if (kDebugMode) print('loginWithToken() failed: ${e.statusCode} - ${e.toString()}');
            if (e.statusCode == 401) {
              await FirebaseAuth.instance.signOut();
              return null;
            }
            rethrow;
          } catch (e) {
            if (kDebugMode) print('loginWithToken() error: $e');
            rethrow;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error checking redirect result: $e');
    }

    if (kDebugMode) print('Checking FirebaseAuth.instance.currentUser...');
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (kDebugMode) print('currentUser: ${firebaseUser?.email}');
    
    if (firebaseUser == null) {
      if (kDebugMode) print('No current user, returning null');
      return null;
    }

    final idToken = await firebaseUser.getIdToken();
    if (idToken == null) {
      if (kDebugMode) print('No ID token, returning null');
      return null;
    }

    final repo = ref.read(authRepositoryProvider);
    try {
      if (kDebugMode) print('Calling loginWithToken() from currentUser...');
      final user = await repo.loginWithToken(idToken);
      if (kDebugMode) print('loginWithToken() succeeded: ${user?.email}');
      return user;
    } on ApiException catch (e) {
      if (kDebugMode) print('loginWithToken() failed: ${e.statusCode} - ${e.toString()}');
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
        if (kDebugMode) print('Web platform: using signInWithRedirect');
        final provider = GoogleAuthProvider();
        try {
          // Use redirect instead of popup to avoid browser blocking
          await FirebaseAuth.instance.signInWithRedirect(provider);
          if (kDebugMode) print('signInWithRedirect initiated');
          // Redirect happens, so this return won't execute
          return null;
        } catch (e) {
          if (kDebugMode) print('signInWithRedirect failed: $e');
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
