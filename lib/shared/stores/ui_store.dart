import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cheapest_go_mobile/shared/lib/map_tier.dart';
import 'package:cheapest_go_mobile/shared/utils/currency.dart';

/// Shared UI & Display Settings Store (mirrors `SettingsContext.tsx` & `ui.store.ts`)
class UiSettingsStore extends ChangeNotifier {
  static const String _currencyKey = 'cheapestgo_display_currency';
  static const String _themeModeKey = 'cheapestgo_theme_mode';
  static const String _mapTierKey = 'cheapestgo_map_tier';
  static const String _mapThemeModeKey = 'cheapestgo_map_theme_mode';

  String _displayCurrency = 'USD';
  ThemeMode _themeMode = ThemeMode.system;
  MapTier _mapTier = MapTier.lite;
  MapThemeMode _mapThemeMode = MapThemeMode.dark;
  DeviceCapabilities? _deviceCapabilities;
  No3dReason? _no3dReason;

  String get displayCurrency => _displayCurrency;
  ThemeMode get themeMode => _themeMode;
  MapTier get mapTier => _mapTier;
  MapThemeMode get mapThemeMode => _mapThemeMode;
  DeviceCapabilities? get deviceCapabilities => _deviceCapabilities;
  No3dReason? get no3dReason => _no3dReason;
  bool get is3dSupported => _no3dReason == null;
  String? get no3dReasonDescription =>
      _no3dReason != null ? no3dReasonText(_no3dReason!) : null;

  Future<void> init() async {
    try {
      _deviceCapabilities = await const DeviceCapabilitiesSource().read();
      _no3dReason = MapTierPolicy.why3dUnavailable(_deviceCapabilities!);
    } catch (_) {
      _deviceCapabilities = const DeviceCapabilities(is64Bit: true);
      _no3dReason = null;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCcy = prefs.getString(_currencyKey);
      if (savedCcy != null && savedCcy.isNotEmpty) {
        _displayCurrency = savedCcy;
      }
      final savedTheme = prefs.getString(_themeModeKey);
      if (savedTheme == 'dark') _themeMode = ThemeMode.dark;
      if (savedTheme == 'light') _themeMode = ThemeMode.light;

      final savedMapTheme = prefs.getString(_mapThemeModeKey);
      if (savedMapTheme == 'light') {
        _mapThemeMode = MapThemeMode.light;
      } else if (savedMapTheme == 'dark') {
        _mapThemeMode = MapThemeMode.dark;
      }

      final savedTier = prefs.getString(_mapTierKey);
      if (savedTier == 'standard' && is3dSupported) {
        _mapTier = MapTier.standard;
      } else if (savedTier == 'lite') {
        _mapTier = MapTier.lite;
      } else {
        // Fall back to device ladder decision
        _mapTier = _deviceCapabilities != null
            ? MapTierPolicy.decide(_deviceCapabilities!)
            : (is3dSupported ? MapTier.standard : MapTier.lite);
      }
      notifyListeners();
    } catch (_) {}
    await CurrencyService.refreshExchangeRates();
  }

  Future<void> setDisplayCurrency(String currency) async {
    final normalized = currency.toUpperCase();
    if (_displayCurrency == normalized) return;
    _displayCurrency = normalized;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currencyKey, normalized);
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, mode.name);
    } catch (_) {}
  }

  Future<void> setMapTier(MapTier tier) async {
    if (tier == MapTier.standard && !is3dSupported) return;
    if (_mapTier == tier) return;
    _mapTier = tier;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_mapTierKey, tier.name);
    } catch (_) {}
  }

  Future<void> setMapThemeMode(MapThemeMode mode) async {
    if (_mapThemeMode == mode) return;
    _mapThemeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_mapThemeModeKey, mode.name);
    } catch (_) {}
  }
}

final UiSettingsStore uiSettingsStore = UiSettingsStore();
