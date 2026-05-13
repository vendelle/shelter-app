import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/firebase/firebase_init.dart';
import 'core/locale/locale_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Always initialize Firebase using the generated firebase_options.dart
  // This approach works across web, iOS, and Android without environment variables
  try {
    await initializeFirebase();
  } catch (e) {
    // Log but don't crash if Firebase init fails (e.g., in test environment)
    if (kDebugMode) print('Firebase init warning: $e');
  }

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const ShelterApp(),
    ),
  );
}
