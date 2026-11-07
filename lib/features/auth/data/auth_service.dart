import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Why a Google sign-in attempt didn't go through.
enum SignInFailure {
  /// The browser blocked the Google popup.
  popupBlocked,

  /// This site's domain isn't in Firebase Auth's authorized domains.
  unauthorizedDomain,
  network,
  unknown,
}

class SignInException implements Exception {
  const SignInException(this.failure, [this.code]);

  final SignInFailure failure;

  /// The underlying Firebase error code, for diagnostics.
  final String? code;

  @override
  String toString() => 'SignInException($failure, $code)';
}

/// Google sign-in, behind an interface so tests don't need Firebase.
abstract class AuthService {
  /// Emits whenever the signed-in Google account changes (null = signed out),
  /// starting with the current state.
  Stream<String?> accountChanges();

  /// A fresh Firebase ID token for API calls, or null when signed out.
  Future<String?> idToken();

  /// Returns false if the person closed the Google window.
  /// Throws [SignInException] on any other failure.
  Future<bool> signInWithGoogle();

  Future<void> signOut();
}

class FirebaseAuthService implements AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  @override
  Stream<String?> accountChanges() =>
      _auth.authStateChanges().map((user) => user?.uid);

  @override
  Future<String?> idToken() async => _auth.currentUser?.getIdToken();

  @override
  Future<bool> signInWithGoogle() async {
    // Always show the account chooser — shared family devices are common.
    final provider = GoogleAuthProvider()
      ..setCustomParameters({'prompt': 'select_account'});
    try {
      if (kIsWeb) {
        await _auth.signInWithPopup(provider);
      } else {
        await _auth.signInWithProvider(provider);
      }
      return true;
    } on FirebaseAuthException catch (e) {
      if (_cancelCodes.contains(e.code)) return false;
      throw SignInException(_failureFor(e.code), e.code);
    }
  }

  static const _cancelCodes = {
    'popup-closed-by-user',
    'cancelled-popup-request',
    'web-context-cancelled',
  };

  static SignInFailure _failureFor(String code) {
    return switch (code) {
      'popup-blocked' => SignInFailure.popupBlocked,
      'unauthorized-domain' => SignInFailure.unauthorizedDomain,
      'network-request-failed' => SignInFailure.network,
      _ => SignInFailure.unknown,
    };
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
