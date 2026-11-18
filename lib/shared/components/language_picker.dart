import 'package:flutter/material.dart';

import 'package:cheapest_go_mobile/shared/stores/ui_store.dart';

/// Changing the app's language from inside an app that opens in Korean.
///
/// AirangGo defaults to Korean (see `UiSettingsStore._language`), and until this existed the
/// only place the language could be set was the onboarding step a returning traveller never
/// sees again — so anyone who could not read Korean was stuck in it.
///
/// Every option is written in its own script, never translated: a reader looking for English
/// finds "English", and one looking for Korean finds "한국어", without being able to read the
/// other. That is the whole point of the control, so it survives any later copy change.
const Map<String, String> languageNames = {
    'en': 'English',
    'ko': '한국어',
    'ja': '日本語',
    'zh': '中文',
};

String languageLabel(String code) => languageNames[code] ?? code.toUpperCase();

/// The language control as an `AppBar` action.
///
/// It sits on the sign-in screen because that is the first thing the app shows and the only
/// screen a signed-out visitor has: a language control reachable only after signing in is no
/// use to someone who cannot read the sign-in form.
class LanguageAction extends StatelessWidget {
    const LanguageAction({super.key});

    @override
    Widget build(BuildContext context) {
        return AnimatedBuilder(
            animation: uiSettingsStore,
            builder: (context, _) => PopupMenuButton<String>(
                // No tooltip text: a tooltip would be in the language the reader is trying to
                // escape. The globe carries it instead.
                icon: const Icon(Icons.language_rounded),
                position: PopupMenuPosition.under,
                onSelected: uiSettingsStore.setLanguage,
                itemBuilder: (context) => [
                    for (final code in UiSettingsStore.supportedLanguages)
                        PopupMenuItem(
                            value: code,
                            child: Row(
                                children: [
                                    SizedBox(
                                        width: 34,
                                        child: Text(
                                            code.toUpperCase(),
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                                        ),
                                    ),
                                    Text(
                                        languageLabel(code),
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: code == uiSettingsStore.language
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                        ),
                                    ),
                                ],
                            ),
                        ),
                ],
            ),
        );
    }
}
