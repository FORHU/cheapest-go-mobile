import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cheapest_go_mobile/shared/stores/ui_store.dart';

/// The theme follows V2, not Android. See #37 and **Design Parity** in CONTEXT.md.
///
/// This is the test most likely to be "fixed" by someone who thinks it is wrong, because on
/// Android following the system setting is the convention and ignoring it looks like an
/// oversight. It is not: V2 applies a saved theme before first paint and falls back to light,
/// and never consults `prefers-color-scheme`, so a visitor with a dark browser still gets a
/// light site. Mobile does the same, and the two products agree about what a person sees.
///
/// If this needs to change, change it on the web first.
void main() {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('starts light, whatever the handset is set to', () {
        expect(UiSettingsStore().themeMode, ThemeMode.light);
    });

    test('never resolves to the system setting', () async {
        final store = UiSettingsStore();

        // The call is refused rather than honoured, so a caller cannot opt in by accident.
        await store.setThemeMode(ThemeMode.system);

        expect(store.themeMode, ThemeMode.light);
        expect(store.themeMode, isNot(ThemeMode.system));
    });

    test('remembers a choice across launches', () async {
        final first = UiSettingsStore();
        await first.setThemeMode(ThemeMode.dark);
        expect(first.themeMode, ThemeMode.dark);

        final relaunched = UiSettingsStore();
        await relaunched.init();
        expect(relaunched.themeMode, ThemeMode.dark, reason: 'the choice outlives the process');
    });

    test('a theme saved as "system" by an older build lands on light', () async {
        SharedPreferences.setMockInitialValues({'cheapestgo_theme_mode': 'system'});

        final store = UiSettingsStore();
        await store.init();

        expect(store.themeMode, ThemeMode.light,
            reason: 'what V2 shows someone who has never chosen');
    });
}
