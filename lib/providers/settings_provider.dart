import 'package:flutter/material.dart';

/// Theme mode: Dark, Light, or follow system.
enum AppThemeMode { dark, light, system }

/// Distance unit for travel.
enum DistanceUnit { kilometers, miles }

/// Who can see live-pinned locations on the map.
enum MapVisibility { everyone, friends, nobody }

/// App preferences and settings. Persist via SharedPreferences or Supabase if needed.
class SettingsProvider extends ChangeNotifier {
  AppThemeMode _themeMode = AppThemeMode.dark;
  DistanceUnit _distanceUnit = DistanceUnit.kilometers;
  bool _hapticFeedback = true;
  bool _publicProfile = true;
  MapVisibility _mapVisibility = MapVisibility.friends;
  bool _notifNewPinsFromFriends = true;
  bool _notifSomeoneSavedMyPin = true;
  bool _notifTrendingNearby = true;

  AppThemeMode get themeMode => _themeMode;
  DistanceUnit get distanceUnit => _distanceUnit;
  bool get hapticFeedback => _hapticFeedback;
  bool get publicProfile => _publicProfile;
  MapVisibility get mapVisibility => _mapVisibility;
  bool get notifNewPinsFromFriends => _notifNewPinsFromFriends;
  bool get notifSomeoneSavedMyPin => _notifSomeoneSavedMyPin;
  bool get notifTrendingNearby => _notifTrendingNearby;

  set themeMode(AppThemeMode v) {
    if (_themeMode == v) return;
    _themeMode = v;
    notifyListeners();
  }

  set distanceUnit(DistanceUnit v) {
    if (_distanceUnit == v) return;
    _distanceUnit = v;
    notifyListeners();
  }

  set hapticFeedback(bool v) {
    if (_hapticFeedback == v) return;
    _hapticFeedback = v;
    notifyListeners();
  }

  set publicProfile(bool v) {
    if (_publicProfile == v) return;
    _publicProfile = v;
    notifyListeners();
  }

  set mapVisibility(MapVisibility v) {
    if (_mapVisibility == v) return;
    _mapVisibility = v;
    notifyListeners();
  }

  set notifNewPinsFromFriends(bool v) {
    if (_notifNewPinsFromFriends == v) return;
    _notifNewPinsFromFriends = v;
    notifyListeners();
  }

  set notifSomeoneSavedMyPin(bool v) {
    if (_notifSomeoneSavedMyPin == v) return;
    _notifSomeoneSavedMyPin = v;
    notifyListeners();
  }

  set notifTrendingNearby(bool v) {
    if (_notifTrendingNearby == v) return;
    _notifTrendingNearby = v;
    notifyListeners();
  }

  String get distanceUnitLabel =>
      _distanceUnit == DistanceUnit.kilometers ? 'Kilometers' : 'Miles';

  String get mapVisibilityLabel {
    switch (_mapVisibility) {
      case MapVisibility.everyone:
        return 'Everyone';
      case MapVisibility.friends:
        return 'Friends only';
      case MapVisibility.nobody:
        return 'Nobody';
    }
  }

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
