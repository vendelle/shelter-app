import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';

/// Initialise Firebase for all platforms.
///
/// Uses the generated firebase_options.dart file which contains
/// platform-specific configurations.
Future<void> initializeFirebase() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}
