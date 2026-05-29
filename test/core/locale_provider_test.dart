import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelter_app/core/locale/locale_provider.dart';

void main() {
  group('LocaleNotifier', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('defaults to null (device locale) when no preference saved', () {
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(localeProvider), isNull);
    });

    test('loads saved locale from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'app_locale': 'en'});
      prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(localeProvider), const Locale('en'));
    });

    test('loads saved Polish locale from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'app_locale': 'pl'});
      prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(localeProvider), const Locale('pl'));
    });

    test('setLocale updates state and persists to SharedPreferences', () {
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      container.read(localeProvider.notifier).setLocale(const Locale('en'));

      expect(container.read(localeProvider), const Locale('en'));
      expect(prefs.getString('app_locale'), 'en');
    });

    test('toggle switches from pl to en', () async {
      SharedPreferences.setMockInitialValues({'app_locale': 'pl'});
      prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      container.read(localeProvider.notifier).toggle();

      expect(container.read(localeProvider), const Locale('en'));
      expect(prefs.getString('app_locale'), 'en');
    });

    test('toggle switches from en to pl', () async {
      SharedPreferences.setMockInitialValues({'app_locale': 'en'});
      prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      container.read(localeProvider.notifier).toggle();

      expect(container.read(localeProvider), const Locale('pl'));
      expect(prefs.getString('app_locale'), 'pl');
    });

    test('setLocale to pl and then toggle gives en', () {
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      container.read(localeProvider.notifier).setLocale(const Locale('pl'));
      container.read(localeProvider.notifier).toggle();

      expect(container.read(localeProvider), const Locale('en'));
    });
  });

  group('sharedPreferencesProvider', () {
    test('throws when not overridden', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        () => container.read(sharedPreferencesProvider),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}
