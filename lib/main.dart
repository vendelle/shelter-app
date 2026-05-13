import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/debug_logger.dart';
import 'core/firebase/firebase_init.dart';
import 'core/locale/locale_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences first (needed for logging)
  final prefs = await SharedPreferences.getInstance();

  // Log app startup
  await DebugLogger.log('=== APP STARTUP ===');
  await DebugLogger.log('Initializing Firebase...');

  // Always initialize Firebase using the generated firebase_options.dart
  // This approach works across web, iOS, and Android without environment variables
  try {
    await initializeFirebase();
    await DebugLogger.log('Firebase initialized successfully');
  } catch (e) {
    // Log but don't crash if Firebase init fails (e.g., in test environment)
    await DebugLogger.log('Firebase init warning: $e');
    if (kDebugMode) print('Firebase init warning: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const ShelterApp(),
    ),
  );
}
