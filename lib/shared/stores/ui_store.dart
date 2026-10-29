import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cheapest_go_mobile/shared/utils/currency.dart';

/// Shared UI & Display Settings Store (mirrors `SettingsContext.tsx` & `ui.store.ts`)
class UiSettingsStore extends ChangeNotifier {
  static const String _currencyKey = 'cheapestgo_display_currency';
  static const String _themeModeKey = 'cheapestgo_theme_mode';

  String _displayCurrency = 'USD';
  ThemeMode _themeMode = ThemeMode.system;

  String get displayCurrency => _displayCurrency;
  ThemeMode get themeMode => _themeMode;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCcy = prefs.getString(_currencyKey);
      if (savedCcy != null && savedCcy.isNotEmpty) {
        _displayCurrency = savedCcy;
      }
      final savedTheme = prefs.getString(_themeModeKey);
      if (savedTheme == 'dark') _themeMode = ThemeMode.dark;
      if (savedTheme == 'light') _themeMode = ThemeMode.light;
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
}

final UiSettingsStore uiSettingsStore = UiSettingsStore();
