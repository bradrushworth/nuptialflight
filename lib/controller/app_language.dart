import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';

/// Null means follow the device's preferred supported language.
class AppLanguage {
  static const String _prefsKey = 'app_language';
  static final ValueNotifier<Locale?> selected = ValueNotifier<Locale?>(null);
  static int _revision = 0;

  static bool _supports(String? code) => AppLocalizations.supportedLocales.any(
    (locale) => locale.languageCode == code,
  );

  static Future<void> load() async {
    final int revision = _revision;
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_prefsKey);
      if (revision == _revision) {
        selected.value = _supports(code) ? Locale(code!) : null;
      }
    } catch (e) {
      debugPrint('AppLanguage: could not load preference: $e');
    }
  }

  static Future<void> choose(Locale? locale) async {
    assert(locale == null || _supports(locale.languageCode));
    _revision++;
    selected.value = locale;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (locale == null) {
        await prefs.remove(_prefsKey);
      } else {
        await prefs.setString(_prefsKey, locale.languageCode);
      }
    } catch (e) {
      debugPrint('AppLanguage: could not save preference: $e');
    }
  }

  /// Read afresh in a background isolate, where [selected] may not be loaded.
  static Future<Locale?> savedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final code = prefs.getString(_prefsKey);
      return _supports(code) ? Locale(code!) : null;
    } catch (e) {
      debugPrint('AppLanguage: could not read preference: $e');
      return null;
    }
  }
}
