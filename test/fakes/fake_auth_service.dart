import 'dart:async';

import 'package:shelter_app/features/auth/data/auth_service.dart';

/// In-memory [AuthService]: starts signed in as [uid] (or signed out).
class FakeAuthService implements AuthService {
  FakeAuthService({String? uid}) : _uid = uid;

  String? _uid;
  final _changes = StreamController<String?>.broadcast();

  int signInCalls = 0;

  /// What the next [signInWithGoogle] does: sign in as this uid, or throw.
  String signInAs = 'uid-signed-in';
  SignInException? signInError;

  /// Like Firebase's authStateChanges: current state first, then changes.
  @override
  Stream<String?> accountChanges() => Stream.multi((listener) {
        listener.add(_uid);
        final sub = _changes.stream.listen(listener.add);
        listener.onCancel = sub.cancel;
      });

  @override
  Future<String?> idToken() async => _uid == null ? null : 'token-$_uid';

  @override
  Future<bool> signInWithGoogle() async {
    signInCalls++;
    final error = signInError;
    if (error != null) throw error;
    _set(signInAs);
    return true;
  }

  @override
  Future<void> signOut() async => _set(null);

  void _set(String? uid) {
    _uid = uid;
    _changes.add(uid);
  }
}
