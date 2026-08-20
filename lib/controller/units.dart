import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User-selectable measurement units. OpenWeatherMap is always queried in
/// metric; conversion to imperial happens at display time only, so the model
/// inputs (which were trained on metric values) are unaffected.
class Units {
  static const String _prefsKey = 'use_imperial_units';

  /// True = show Fahrenheit / mph. Listeners rebuild when toggled.
  static final ValueNotifier<bool> imperial = ValueNotifier<bool>(false);

  /// Loads the persisted preference. Safe to call more than once.
  static Future<void> load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      imperial.value = prefs.getBool(_prefsKey) ?? false;
    } catch (e) {
      // Plugin unavailable (tests, some platforms): keep the metric default.
      debugPrint('Units: could not load preference: $e');
    }
  }

  static Future<void> toggle() async {
    imperial.value = !imperial.value;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, imperial.value);
    } catch (e) {
      debugPrint('Units: could not save preference: $e');
    }
  }

  /// "27.2°C" / "81.0°F"; with [withUnit] false, just "27°".
  static String temp(num celsius, {int decimals = 1, bool withUnit = true}) {
    final double value =
        imperial.value ? celsius * 9 / 5 + 32 : celsius.toDouble();
    final String number = value.toStringAsFixed(decimals);
    if (!withUnit) return '$number°';
    return imperial.value ? '$number°F' : '$number°C';
  }

  /// "4.9 m/s" / "11.0 mph". Non-breaking space keeps value and unit together.
  static String speed(num metresPerSecond, {int decimals = 1}) {
    final double value = imperial.value
        ? metresPerSecond * 2.23694
        : metresPerSecond.toDouble();
    final String unit = imperial.value ? 'mph' : 'm/s';
    return '${value.toStringAsFixed(decimals)}\u{00A0}$unit';
  }
}
