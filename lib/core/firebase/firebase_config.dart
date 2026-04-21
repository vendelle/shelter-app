/// Firebase configuration loaded from compile-time environment variables.
///
/// Set these via `--dart-define` when building or running:
/// ```
/// flutter run --dart-define=FIREBASE_API_KEY=...
///              --dart-define=FIREBASE_AUTH_DOMAIN=...
///              --dart-define=FIREBASE_PROJECT_ID=...
///              --dart-define=FIREBASE_MESSAGING_SENDER_ID=...
///              --dart-define=FIREBASE_APP_ID=...
/// ```
///
/// Or set them as Vercel environment variables for the build command.
class FirebaseConfig {
  static const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const messagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const appId = String.fromEnvironment('FIREBASE_APP_ID');

  /// Whether all required Firebase config values are present.
  static bool get isConfigured =>
      apiKey.isNotEmpty &&
      authDomain.isNotEmpty &&
      projectId.isNotEmpty &&
      appId.isNotEmpty;
}
