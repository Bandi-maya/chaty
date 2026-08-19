import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalPreferencesStorage {
  static const String _prefsKey = 'chaty_preferences_v1';
  static const String _sessionKey = 'chaty_stored_user_id';

  static Future<Map<String, dynamic>> loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final content = prefs.getString(_prefsKey);
      if (content != null && content.isNotEmpty) {
        final data = jsonDecode(content);
        if (data is Map<String, dynamic>) {
          return data;
        }
      }
    } catch (e) {
      debugPrint('Error loading preferences: ');
    }
    return {};
  }

  static Future<bool> savePreferences(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final content = jsonEncode(data);
      return await prefs.setString(_prefsKey, content);
    } catch (e) {
      debugPrint('Error saving preferences: ');
      return false;
    }
  }

  static Future<String?> getStoredUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_sessionKey);
    } catch (e) {
      debugPrint('Error loading stored user session: ');
      return null;
    }
  }

  static Future<void> setStoredUserId(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionKey, userId);
    } catch (e) {
      debugPrint('Error saving user session: ');
    }
  }

  static Future<void> saveUserId(String userId) => setStoredUserId(userId);

  static Future<void> clearStoredUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
    } catch (e) {
      debugPrint('Error clearing user session: ');
    }
  }
}
