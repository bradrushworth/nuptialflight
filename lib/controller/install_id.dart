import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Anonymous, per-install identifier.
///
/// Unlike a hardware/device id, this is a random v4 UUID that is generated
/// exactly once on first use and then persisted in [SharedPreferences]. It
/// carries no personally identifying information and is reset if the user
/// clears app data or reinstalls. It lets us group crowd-sourced flight
/// reports by install (e.g. to de-duplicate bursts and detect abusive
/// reporting) without tracking the actual device or user.
class InstallId {
  static const String _prefsKey = 'install_id';

  static String? _cached;

  /// Returns the anonymous install id, generating and persisting one on the
  /// first call. Safe to call repeatedly; the value is cached in memory.
  static Future<String> get() async {
    if (_cached != null) return _cached!;

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      String? id = prefs.getString(_prefsKey);
      if (id == null || id.isEmpty) {
        id = const Uuid().v4();
        await prefs.setString(_prefsKey, id);
      }
      _cached = id;
      return id;
    } catch (e) {
      // If shared_preferences is unavailable (e.g. in a test harness without
      // the plugin), fall back to an ephemeral id so callers never crash.
      debugPrint('InstallId: falling back to ephemeral id: \$e');
      _cached ??= const Uuid().v4();
      return _cached!;
    }
  }
}