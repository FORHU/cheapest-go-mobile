@Tags(['render'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cheapest_go_mobile/app/theme/app_theme.dart';
import 'package:cheapest_go_mobile/features/about/views/about_view.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';

/// Renders the screen to a PNG so a person can look at it beside V2.
///
/// Not a golden in the usual sense — nothing here fails on a pixel change, because Design
/// Parity is judged by recognition. Run with `--update-goldens` to refresh the images.
Future<void> _loadFonts() async {
    // MaterialIcons comes from the SDK rather than this repo; without it every glyph is a box.
    // FLUTTER_ROOT is set for the test process, which beats guessing from the executable path:
    // that is flutter_tester, not dart, and sits somewhere else entirely under the cache.
    final root = Platform.environment['FLUTTER_ROOT'];
    final icons = File('$root/bin/cache/artifacts/material_fonts/materialicons-regular.otf');

    for (final entry in {
        'Plus Jakarta Sans': [
            'assets/fonts/PlusJakartaSans-400.ttf',
            'assets/fonts/PlusJakartaSans-500.ttf',
            'assets/fonts/PlusJakartaSans-600.ttf',
            'assets/fonts/PlusJakartaSans-700.ttf',
            'assets/fonts/PlusJakartaSans-800.ttf',
        ],
        if (icons.existsSync()) 'MaterialIcons': [icons.path],
    }.entries) {
        final loader = FontLoader(entry.key);
        for (final path in entry.value) {
            loader.addFont(
                File(path).readAsBytes().then((b) => ByteData.view(Uint8List.fromList(b).buffer)),
            );
        }
        await loader.load();
    }
}

void main() {
    setUpAll(_loadFonts);

    for (final (name, brightness) in [('light', Brightness.light), ('dark', Brightness.dark)]) {
        testWidgets('about — $name', (tester) async {
            tester.view.physicalSize = const Size(390 * 3, 2400 * 3);
            tester.view.devicePixelRatio = 3;
            addTearDown(tester.view.reset);

            // The app's own theme, not a bare ThemeData: body text inherits its family from
            // there, exactly as V2's does from `body`. Rendering without it says nothing
            // about what a traveller sees.
            await tester.pumpWidget(MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                locale: const Locale('en'),
                theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
                home: const AboutView(),
            ));
            await tester.pumpAndSettle();

            await expectLater(
                find.byType(AboutView),
                matchesGoldenFile('renders/about_$name.png'),
            );
        });
    }
}
