/// Demo mode detection for recruiter showcase environment.
/// Set via compile-time --dart-define=FLUTTER_DEMO_MODE=true
const bool isDemoMode = String.fromEnvironment('FLUTTER_DEMO_MODE') == 'true';
