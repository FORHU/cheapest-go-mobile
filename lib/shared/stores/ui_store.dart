import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cheapest_go_mobile/shared/lib/map_tier.dart';
import 'package:cheapest_go_mobile/shared/account/account_preferences.dart';

/// Shared UI & Display Settings Store (mirrors `SettingsContext.tsx` & `ui.store.ts`)
class UiSettingsStore extends ChangeNotifier {
  static const String _currencyKey = 'cheapestgo_display_currency';
  static const String _themeModeKey = 'cheapestgo_theme_mode';
  static const String _mapTierKey = 'cheapestgo_map_tier';
  static const String _languageKey = 'cheapestgo_language';

  /// The languages V2 is translated into, which are the four this app carries copy for.
  static const List<String> supportedLanguages = ['en', 'ja', 'ko', 'zh'];

  String _displayCurrency = 'USD';

  /// Korean until somebody chooses otherwise.
  ///
  /// This app is AirangGo, whose market is Korea, so Korean is the language it opens in — not
  /// the handset's, which would show a Manila tester English and tell us nothing about how the
  /// app reads to the people it is for.
  ///
  /// The cost lands on the team rather than the traveller: anyone who cannot read Korean sees a
  /// Korean app from the first frame, before any screen explains itself. That is what the
  /// language control in the top bar is for, and why it shows language codes rather than words.
  String _language = 'ko';

  /// Light, and not the handset's setting. See [setThemeMode].
  ThemeMode _themeMode = ThemeMode.light;
  MapTier _mapTier = MapTier.lite;
  DeviceCapabilities? _deviceCapabilities;
  No3dReason? _no3dReason;

  String get displayCurrency => _displayCurrency;
  String get language => _language;
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
      final savedLanguage = prefs.getString(_languageKey);
      if (savedLanguage != null && supportedLanguages.contains(savedLanguage)) {
        _language = savedLanguage;
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

  /// Writes a preference back to the account, best-effort.
  ///
  /// The device copy above is what the app renders from; this is what every other surface
  /// reads. Without it a language chosen on the account screen lived only on the handset: the
  /// account kept whatever onboarding wrote, so the website and anything the server sends —
  /// confirmation emails among them — stayed in the old language with nothing to show why.
  ///
  /// Failure is ignored on purpose. The control also sits on the sign-in screen, where there
  /// is no account yet and this is a guaranteed 401; a traveller changing the language must
  /// not be shown an error for it. The device copy has already been written either way.
  ///
  /// [AccountPreferences.update] reads before it writes: the blob is replaced, not merged, so
  /// sending one key alone would delete every other preference the account holds.
  Future<void> _rememberOnAccount(Map<String, dynamic> changes) async {
    try {
      await accountPreferences.update(changes);
    } catch (_) {}
  }

  /// The language the app renders in, chosen during onboarding or on the account screen.
  ///
  /// Held here as well as against the account because the app has to render in it before any
  /// request completes, and because a signed-out traveller — at the sign-in wall itself — has
  /// no account to read it from. An unknown code is ignored rather than crashing the app into
  /// a locale it has no copy for.
  Future<void> setLanguage(String code) async {
    final normalized = code.trim().toLowerCase();
    if (!supportedLanguages.contains(normalized)) return;
    if (_language == normalized) return;
    _language = normalized;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, normalized);
    } catch (_) {}
    await _rememberOnAccount({'language': normalized});
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
    await _rememberOnAccount({'displayCurrency': normalized});
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
