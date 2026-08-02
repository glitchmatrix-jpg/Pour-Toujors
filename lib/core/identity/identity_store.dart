import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IdentityStore {
  static const _key = 'selected_family_member';

  Future<String?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString(_key)?.trim();
      return value == null || value.isEmpty ? null : value;
    } on Object catch (error, stackTrace) {
      debugPrint('Identity preferences could not be read: $error\n$stackTrace');
      return null;
    }
  }

  Future<void> save(String name) async {
    final normalized = name.trim();
    if (normalized.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, normalized);
    } on Object catch (error, stackTrace) {
      debugPrint('Identity preference could not be saved: $error\n$stackTrace');
    }
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } on Object catch (error, stackTrace) {
      debugPrint('Identity preference could not be cleared: $error\n$stackTrace');
    }
  }
}
