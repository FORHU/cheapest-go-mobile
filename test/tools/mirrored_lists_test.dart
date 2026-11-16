import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The lists V2 writes are the lists mobile holds. See #44.
///
/// `sync_design.dart` used to drop every array, on a stated ground that expired: "no screen
/// in this slice needs one". #44's screens are almost entirely lists — the legal documents
/// carry 21 of them holding 92 entries — and a Terms page whose "Pricing and Payments" was a
/// heading with nothing under it is what that exclusion produced.
///
/// A comment is what misled the last reader. This is the check that would have caught it.
///
/// Skipped when V2 is not beside this repo, since that is the normal state of a CI job that
/// has not checked it out — the design-pin workflow does, and runs this.
void main() {
  final v2 = Directory('../cheapestgo-app-v2/src/locales');

  group('mirrored lists', () {
    test('every list entry in V2 reaches the ARB, in every language', () {
      var checked = 0;

      for (final locale in ['en', 'ja', 'ko', 'zh']) {
        final source = File('${v2.path}/$locale.json');
        final arbFile = File('lib/l10n/app_$locale.arb');
        expect(arbFile.existsSync(), isTrue, reason: 'no ARB for $locale');

        final src = jsonDecode(source.readAsStringSync()) as Map<String, dynamic>;
        final arb = jsonDecode(arbFile.readAsStringSync()) as Map<String, dynamic>;

        for (final entry in _listEntries(src, '')) {
          // Rich text is the one exclusion that remains, and it fails loudly elsewhere.
          if (RegExp(r'<[a-zA-Z][^>]*>').hasMatch(entry.value)) continue;
          checked++;
          expect(
            arb[_arbKey(entry.key)],
            entry.value,
            reason: 'ARB $locale is missing or differs at ${entry.key}',
          );
        }
      }

      // Four locales of the same documents; a drop on one side shows as a smaller number.
      expect(checked, greaterThan(300), reason: 'far fewer list entries than expected');
    });

    test('the legal documents carry their bodies, not just their headings', () {
      final arb = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
          as Map<String, dynamic>;

      // The section that was a heading with nothing under it.
      expect(arb['legal_content_terms_pricing_title'], isNotNull);
      expect(arb['legal_content_terms_pricing_items_1_label'], 'Pricing');
      expect(arb['legal_content_terms_pricing_items_5_text'], isNotEmpty);

      // Indexed from 1 and in the document's own order, so a renderer can name them.
      expect(arb['legal_content_terms_pricing_items_0_label'], isNull);
    });
  }, skip: v2.existsSync() ? null : 'V2 is not checked out beside this repo');
}

/// Every string inside an array, with the path `sync_design.dart` gives it.
Iterable<MapEntry<String, String>> _listEntries(Map<String, dynamic> node, String prefix) sync* {
  for (final entry in node.entries) {
    final path = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
    final value = entry.value;

    if (value is List) {
      for (var i = 0; i < value.length; i++) {
        final item = value[i];
        final itemPath = '$path.${i + 1}';
        if (item is Map<String, dynamic>) {
          yield* _listEntries(item, itemPath);
        } else if (item is String) {
          yield MapEntry(itemPath, item);
        }
      }
    } else if (value is Map<String, dynamic>) {
      yield* _listEntries(value, path);
    }
  }
}

String _arbKey(String path) {
  final key = path.replaceAll(RegExp(r'[^A-Za-z0-9]'), '_');
  return RegExp(r'^[0-9]').hasMatch(key) ? 'k$key' : key;
}
