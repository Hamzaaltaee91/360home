// Settings Service
//
// Persists user preferences (language, notifications, dark mode) locally
// using [SharedPreferences] and exposes them as a [ChangeNotifier] so the
// UI can react to changes.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  SettingsService._();

  static final SettingsService _instance = SettingsService._();

  factory SettingsService() => _instance;

  static const String _languageKey = 'settings_language';
  static const String _notificationsKey = 'settings_notifications_enabled';
  static const String _darkModeKey = 'settings_dark_mode';

  static const String defaultLanguage = 'ar';

  SharedPreferences? _prefs;

  String _language = defaultLanguage;
  bool _notificationsEnabled = true;
  bool _darkMode = false;

  String get language => _language;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get darkMode => _darkMode;

  ThemeMode get themeMode => _darkMode ? ThemeMode.dark : ThemeMode.light;

  /// Loads persisted preferences. Safe to call multiple times.
  Future<void> load() async {
    _prefs ??= await SharedPreferences.getInstance();

    _language = _prefs!.getString(_languageKey) ?? defaultLanguage;
    _notificationsEnabled = _prefs!.getBool(_notificationsKey) ?? true;
    _darkMode = _prefs!.getBool(_darkModeKey) ?? false;

    notifyListeners();
  }

  Future<void> setLanguage(String language) async {
    if (_language == language) return;
    _language = language;
    notifyListeners();
    await _prefs?.setString(_languageKey, language);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    if (_notificationsEnabled == enabled) return;
    _notificationsEnabled = enabled;
    notifyListeners();
    await _prefs?.setBool(_notificationsKey, enabled);
  }

  Future<void> setDarkMode(bool enabled) async {
    if (_darkMode == enabled) return;
    _darkMode = enabled;
    notifyListeners();
    await _prefs?.setBool(_darkModeKey, enabled);
  }
}
