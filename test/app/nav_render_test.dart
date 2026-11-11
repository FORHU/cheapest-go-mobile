@Tags(['render'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cheapest_go_mobile/app/router/v2_bottom_nav.dart';
import 'package:cheapest_go_mobile/app/theme/app_theme.dart';

/// Renders the bar so a person can hold it next to V2's. Excluded from `flutter test`; run it
/// with `--tags render`, and `--update-goldens` to refresh.
/// Where a dependency's assets live on this machine. A test cannot read a package's bundled
/// font the way the running app does, and hardcoding the pub cache path would only work here.
String? _packageRoot(String name) {
    final config = File('.dart_tool/package_config.json');
    if (!config.existsSync()) return null;
    final packages = (jsonDecode(config.readAsStringSync())['packages'] as List)
        .cast<Map<String, dynamic>>();
    final match = packages.where((p) => p['name'] == name).firstOrNull;
    if (match == null) return null;
    return Uri.parse(match['rootUri'] as String).toFilePath();
}

Future<void> _loadFonts() async {
    final root = Platform.environment['FLUTTER_ROOT'];
    final icons = File('$root/bin/cache/artifacts/material_fonts/materialicons-regular.otf');
    final lucide = _packageRoot('lucide_icons_flutter');

    for (final entry in {
        'Plus Jakarta Sans': ['assets/fonts/PlusJakartaSans-500.ttf'],
        if (icons.existsSync()) 'MaterialIcons': [icons.path],
        // The family the package declares, so Icon() finds it by the same name.
        if (lucide != null && File('$lucide/assets/lucide.ttf').existsSync())
            'packages/lucide_icons_flutter/Lucide': ['$lucide/assets/lucide.ttf'],
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

    for (final (name, theme) in [('light', AppTheme.light), ('dark', AppTheme.dark)]) {
        testWidgets('bar — $name', (tester) async {
            tester.view.physicalSize = const Size(390 * 3, 140 * 3);
            tester.view.devicePixelRatio = 3;
            addTearDown(tester.view.reset);

            await tester.pumpWidget(MaterialApp(
                theme: theme,
                home: Scaffold(
                    backgroundColor: theme.colorScheme.surface,
                    bottomNavigationBar: V2BottomNav(
                        activeIndex: 0,
                        onHome: () {},
                        onTrips: () {},
                        onSettings: () {},
                    ),
                ),
            ));
            await tester.pumpAndSettle();

            await expectLater(find.byType(V2BottomNav), matchesGoldenFile('renders/nav_$name.png'));
        });
    }
}
