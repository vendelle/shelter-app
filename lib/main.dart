import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/firebase/firebase_config.dart';
import 'core/firebase/firebase_init.dart';
import 'core/locale/locale_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (FirebaseConfig.isConfigured) {
    await initializeFirebase();
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
