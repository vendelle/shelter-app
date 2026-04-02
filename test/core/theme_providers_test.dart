import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelter_app/core/locale/locale_provider.dart';
import 'package:shelter_app/core/theme/theme_providers.dart';

void main() {
  group('themeModeProvider', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('defaults to system', () {
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.system);
    });

    test('can be changed to dark', () {
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      container.read(themeModeProvider.notifier).cycle();
      expect(container.read(themeModeProvider), ThemeMode.dark);
    });

    test('can be changed to light', () {
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      container.read(themeModeProvider.notifier).cycle(); // system -> dark
      container.read(themeModeProvider.notifier).cycle(); // dark -> light
      expect(container.read(themeModeProvider), ThemeMode.light);
    });

    test('cycles through modes', () {
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.system);

      container.read(themeModeProvider.notifier).cycle();
      expect(container.read(themeModeProvider), ThemeMode.dark);

      container.read(themeModeProvider.notifier).cycle();
      expect(container.read(themeModeProvider), ThemeMode.light);

      container.read(themeModeProvider.notifier).cycle();
      expect(container.read(themeModeProvider), ThemeMode.system);
    });

    test('persists theme mode to SharedPreferences', () {
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      container.read(themeModeProvider.notifier).cycle(); // system -> dark
      expect(prefs.getString('theme_mode'), 'dark');

      container.read(themeModeProvider.notifier).cycle(); // dark -> light
      expect(prefs.getString('theme_mode'), 'light');

      container.read(themeModeProvider.notifier).cycle(); // light -> system
      expect(prefs.getString('theme_mode'), 'system');
    });

    test('loads persisted dark mode from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
      prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.dark);
    });

    test('loads persisted light mode from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
      prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.light);
    });

    test('falls back to system for unknown persisted value', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'garbage'});
      prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.system);
    });
  });
}
