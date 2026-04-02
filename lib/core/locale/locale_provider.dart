import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLocaleKey = 'app_locale';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override in main.dart');
});

final localeProvider =
    StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocaleNotifier(prefs);
});

class LocaleNotifier extends StateNotifier<Locale?> {
  LocaleNotifier(this._prefs) : super(_loadLocale(_prefs));

  final SharedPreferences _prefs;

  static Locale? _loadLocale(SharedPreferences prefs) {
    final code = prefs.getString(_kLocaleKey);
    if (code != null) return Locale(code);
    // null means "use device locale" (which is the default)
    return null;
  }

  void setLocale(Locale locale) {
    state = locale;
    _prefs.setString(_kLocaleKey, locale.languageCode);
  }

  void toggle() {
    final current = state?.languageCode ??
        PlatformDispatcher.instance.locale.languageCode;
    if (current == 'pl') {
      setLocale(const Locale('en'));
    } else {
      setLocale(const Locale('pl'));
    }
  }
}
