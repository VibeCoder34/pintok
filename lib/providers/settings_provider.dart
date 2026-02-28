import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme mode: Dark, Light, or follow system.
enum AppThemeMode { dark, light, system }

/// Distance unit for travel.
enum DistanceUnit { kilometers, miles }

/// App preferences and settings. Persist via SharedPreferences or Supabase if needed.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider() {
    _loadFromStorage();
  }

  static const _keyThemeMode = 'settings_theme_mode';
  static const _keyDistanceUnit = 'settings_distance_unit';
  static const _keyHaptic = 'settings_haptic';
  static const _keyNotifNewPins = 'settings_notif_new_pins';
  static const _keyNotifSavedMyPin = 'settings_notif_saved_my_pin';
  static const _keyNotifTrending = 'settings_notif_trending';

  AppThemeMode _themeMode = AppThemeMode.dark;
  DistanceUnit _distanceUnit = DistanceUnit.kilometers;
  bool _hapticFeedback = true;
  bool _notifNewPinsFromFriends = true;
  bool _notifSomeoneSavedMyPin = true;
  bool _notifTrendingNearby = true;

  AppThemeMode get themeMode => _themeMode;
  DistanceUnit get distanceUnit => _distanceUnit;
  bool get hapticFeedback => _hapticFeedback;
  bool get notifNewPinsFromFriends => _notifNewPinsFromFriends;
  bool get notifSomeoneSavedMyPin => _notifSomeoneSavedMyPin;
  bool get notifTrendingNearby => _notifTrendingNearby;

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();

    final themeIndex = prefs.getInt(_keyThemeMode);
    if (themeIndex != null &&
        themeIndex >= 0 &&
        themeIndex < AppThemeMode.values.length) {
      _themeMode = AppThemeMode.values[themeIndex];
    }

    final distanceIndex = prefs.getInt(_keyDistanceUnit);
    if (distanceIndex != null &&
        distanceIndex >= 0 &&
        distanceIndex < DistanceUnit.values.length) {
      _distanceUnit = DistanceUnit.values[distanceIndex];
    }

    _hapticFeedback = prefs.getBool(_keyHaptic) ?? _hapticFeedback;

    _notifNewPinsFromFriends =
        prefs.getBool(_keyNotifNewPins) ?? _notifNewPinsFromFriends;
    _notifSomeoneSavedMyPin =
        prefs.getBool(_keyNotifSavedMyPin) ?? _notifSomeoneSavedMyPin;
    _notifTrendingNearby =
        prefs.getBool(_keyNotifTrending) ?? _notifTrendingNearby;

    notifyListeners();
  }

  Future<void> _saveInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  set themeMode(AppThemeMode v) {
    if (_themeMode == v) return;
    _themeMode = v;
    _saveInt(_keyThemeMode, v.index);
    notifyListeners();
  }

  set distanceUnit(DistanceUnit v) {
    if (_distanceUnit == v) return;
    _distanceUnit = v;
    _saveInt(_keyDistanceUnit, v.index);
    notifyListeners();
  }

  set hapticFeedback(bool v) {
    if (_hapticFeedback == v) return;
    _hapticFeedback = v;
    _saveBool(_keyHaptic, v);
    notifyListeners();
  }

  set notifNewPinsFromFriends(bool v) {
    if (_notifNewPinsFromFriends == v) return;
    _notifNewPinsFromFriends = v;
    _saveBool(_keyNotifNewPins, v);
    notifyListeners();
  }

  set notifSomeoneSavedMyPin(bool v) {
    if (_notifSomeoneSavedMyPin == v) return;
    _notifSomeoneSavedMyPin = v;
    _saveBool(_keyNotifSavedMyPin, v);
    notifyListeners();
  }

  set notifTrendingNearby(bool v) {
    if (_notifTrendingNearby == v) return;
    _notifTrendingNearby = v;
    _saveBool(_keyNotifTrending, v);
    notifyListeners();
  }

  String get distanceUnitLabel =>
      _distanceUnit == DistanceUnit.kilometers ? 'Kilometers' : 'Miles';

  String get themeModeLabel {
    switch (_themeMode) {
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.system:
        return 'System';
    }
  }
}

