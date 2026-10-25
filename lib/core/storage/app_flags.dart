import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Non-secret, per-install flags (`shared_preferences`, unlike the JWT in
/// `TokenStorage`). Cleared when the app is uninstalled or its data cleared.
class AppFlags {
  static const _introSeenKey = 'intro_seen';

  final SharedPreferencesAsync _prefs;

  AppFlags([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  /// True once the splash intro animation has played to the end once.
  /// A storage failure counts as "not seen": playing the intro again is
  /// harmless, skipping it is not something to do by accident.
  Future<bool> introSeen() async {
    try {
      return await _prefs.getBool(_introSeenKey) ?? false;
    } catch (e) {
      // e.g. MissingPluginException: the app wasn't fully rebuilt after
      // adding shared_preferences (hot restart doesn't add native code).
      debugPrint('AppFlags: could not read $_introSeenKey: $e');
      return false;
    }
  }

  Future<void> markIntroSeen() => _prefs.setBool(_introSeenKey, true);
}
