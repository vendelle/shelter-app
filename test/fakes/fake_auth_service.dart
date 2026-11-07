import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_app/features/auth/data/auth_service.dart';
import 'package:shelter_app/features/auth/domain/app_user.dart';
import 'package:shelter_app/features/auth/presentation/auth_providers.dart';

const testVolunteer =
    AppUser(id: 1, email: 'anna@gmail.com', role: UserRole.volunteer);

/// Provider overrides for pumping the whole app as a signed-in [user] —
/// otherwise the AuthGate shows only the sign-in screen.
List<Override> signedInAs(AppUser user) => [
      authServiceProvider.overrideWithValue(FakeAuthService(uid: 'uid')),
      currentUserProvider.overrideWith((ref) => Stream.value(user)),
    ];

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
