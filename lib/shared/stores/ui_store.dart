import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cheapest_go_mobile/shared/lib/map_tier.dart';

/// Shared UI & Display Settings Store (mirrors `SettingsContext.tsx` & `ui.store.ts`)
class UiSettingsStore extends ChangeNotifier {
  static const String _currencyKey = 'cheapestgo_display_currency';
  static const String _themeModeKey = 'cheapestgo_theme_mode';
  static const String _mapTierKey = 'cheapestgo_map_tier';

  String _displayCurrency = 'USD';

  /// Light, and not the handset's setting. See [setThemeMode].
  ThemeMode _themeMode = ThemeMode.light;
  MapTier _mapTier = MapTier.lite;
  DeviceCapabilities? _deviceCapabilities;
  No3dReason? _no3dReason;

  String get displayCurrency => _displayCurrency;
  ThemeMode get themeMode => _themeMode;
  MapTier get mapTier => _mapTier;
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
      // Only the two V2 offers. Anyone carrying `system` from an older build lands on light,
      // which is what V2 shows a visitor who has never chosen — no migration step needed.
      final savedTheme = prefs.getString(_themeModeKey);
      if (savedTheme == 'dark') _themeMode = ThemeMode.dark;
      if (savedTheme == 'light') _themeMode = ThemeMode.light;

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

  /// Light or dark, chosen in the app and remembered. Never the handset's setting.
  ///
  /// V2 defaults to light and changes only through its own toggle — its `layout.tsx` applies
  /// `localStorage.theme` before first paint and falls back to light, and nothing in that path
  /// reads `prefers-color-scheme`. A visitor whose browser is dark still gets a light site.
  /// Mobile matches, which is the deliberate part: on Android, following the system setting is
  /// the convention, so a later reader will think this is a bug. It is **Design Parity**
  /// (CONTEXT.md), and `test/shared/theme_default_test.dart` fails if someone restores the
  /// platform behaviour.
  ///
  /// [ThemeMode.system] is ignored rather than honoured. Not asserted: an assert would crash a
  /// debug build and do nothing in release, so the same call would behave two different ways.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == ThemeMode.system) return;
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
}

final UiSettingsStore uiSettingsStore = UiSettingsStore();
