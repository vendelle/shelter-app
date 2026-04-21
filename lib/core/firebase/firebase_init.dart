import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'firebase_config.dart';

/// Initialise Firebase for all platforms.
///
/// On web, the config is read from compile-time `--dart-define` values.
/// On mobile, Firebase auto-discovers config from `google-services.json`
/// (Android) or `GoogleService-Info.plist` (iOS).
Future<void> initializeFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: FirebaseConfig.apiKey,
        authDomain: FirebaseConfig.authDomain,
        projectId: FirebaseConfig.projectId,
        messagingSenderId: FirebaseConfig.messagingSenderId,
        appId: FirebaseConfig.appId,
      ),
    );
  } else {
    // Mobile: relies on google-services.json / GoogleService-Info.plist
    await Firebase.initializeApp();
  }
}
