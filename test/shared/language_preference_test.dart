import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cheapest_go_mobile/shared/stores/ui_store.dart';

/// Changing the language must never fail, even with no account and no network.
///
/// AirangGo opens in Korean, and the language control sits on the sign-in screen because that
/// is the only screen a signed-out visitor has. Writing the choice back to the account is a
/// 401 there, and in a test there is no server at all — so if that write is ever allowed to
/// throw, the one control that gets a reader out of a language they cannot read is the thing
/// that breaks.
void main() {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('a language change applies with no account and no network', () async {
        final store = UiSettingsStore();
        expect(store.language, 'ko', reason: 'AirangGo opens in Korean');

        await store.setLanguage('en');

        expect(store.language, 'en');
    });

    test('the device remembers it even though the account write cannot land', () async {
        final store = UiSettingsStore();
        await store.setLanguage('ja');

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('cheapestgo_language'), 'ja');
    });

    test('a language the app has no copy for is refused, not rendered', () async {
        final store = UiSettingsStore();
        await store.setLanguage('fr');
        expect(store.language, 'ko', reason: 'unchanged: there is no French copy');
    });

    test('the display currency travels the same path', () async {
        final store = UiSettingsStore();
        await store.setDisplayCurrency('krw');

        expect(store.displayCurrency, 'KRW');
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('cheapestgo_display_currency'), 'KRW');
    });
}
