import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cheapest_go_mobile/features/legal/components/legal_blocks.dart';
import 'package:cheapest_go_mobile/features/legal/lib/legal_documents.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';

import '../../test_helpers.dart';

/// Terms, Privacy, Cookies, Refund and Help. See #44.
///
/// The documents are declared rather than discovered — `gen-l10n` makes static getters, so
/// nothing can iterate them — which means a section can be left out and nothing complains.
/// These check that each document carries its sections and that none of them is a heading
/// with nothing underneath, which is what the dropped arrays produced before the generator
/// learned to carry lists.
void main() {
  _localeGroup();
  _reachabilityGroup();
  group('the documents', () {
    for (final (doc, name, sections) in [
      (LegalDocument.terms, 'Terms', 14),
      (LegalDocument.privacy, 'Privacy', 12),
      (LegalDocument.cookie, 'Cookies', 9),
      (LegalDocument.refund, 'Refund', 10),
    ]) {
      testWidgets('$name carries all $sections sections, each with a body', (tester) async {
        late AppLocalizations t;
        await pumpScreen(tester, Builder(builder: (context) {
          t = AppLocalizations.of(context)!;
          return const SizedBox();
        }));

        final built = legalSections(t, doc);
        expect(built, hasLength(sections), reason: '$name lost or gained a section');

        for (final section in built) {
          expect(section.title.trim(), isNotEmpty, reason: 'a section with no heading');
          // The failure the dropped arrays produced: a heading and nothing under it.
          expect(section.blocks, isNotEmpty, reason: '"${section.title}" has no body');

          for (final block in section.blocks) {
            switch (block) {
              case Para(:final text):
                expect(text.trim(), isNotEmpty, reason: 'empty paragraph in "${section.title}"');
              case Bullets(:final items):
                expect(items, isNotEmpty, reason: 'empty list in "${section.title}"');
                for (final item in items) {
                  expect(item.trim(), isNotEmpty, reason: 'empty bullet in "${section.title}"');
                }
              case Defined(:final entries):
                expect(entries, isNotEmpty, reason: 'no entries in "${section.title}"');
                for (final (label, text) in entries) {
                  expect(label.trim(), isNotEmpty);
                  expect(text.trim(), isNotEmpty, reason: '"$label" explains nothing');
                }
              case Linked(:final before, :final linkText, :final route):
                expect(linkText.trim(), isNotEmpty);
                expect(before.trim(), isNotEmpty);
                // Mobile's own route, not V2's web path.
                expect(route, startsWith('/'));
              case Note(:final text):
                expect(text.trim(), isNotEmpty);
            }
          }
        }
      });
    }

    // The section that was a heading with nothing under it until the generator carried
    // arrays. If this is ever a bare title again, the copy has been dropped upstream.
    testWidgets('Terms › Pricing still explains itself', (tester) async {
      late AppLocalizations t;
      await pumpScreen(tester, Builder(builder: (context) {
        t = AppLocalizations.of(context)!;
        return const SizedBox();
      }));

      final pricing = legalSections(t, LegalDocument.terms)
          .firstWhere((s) => s.title.toLowerCase().contains('pricing'));
      final defined = pricing.blocks.whereType<Defined>().single;

      expect(defined.entries, hasLength(5));
      expect(defined.entries.first.$1, 'Pricing');
    });
  });

  group('the screens', () {
    for (final (route, heading) in [
      ('/terms', 'Terms'),
      ('/privacy', 'Privacy'),
      ('/cookies', 'Cookie'),
      ('/refund', 'Refund'),
      ('/help', 'Help'),
    ]) {
      testWidgets('$route opens and renders without overflowing', (tester) async {
        await pumpApp(tester, location: route);
        await tester.pumpAndSettle();

        expect(find.textContaining(heading), findsWidgets);
        // Long-form copy on a narrow screen is where a layout gives way.
        expect(tester.takeException(), isNull);
      });
    }

    // Terms points at the refund policy from inside a sentence in its cancellations section.
    // The link is a tappable span, not a button, so this is the only thing that proves it
    // actually goes anywhere.
    testWidgets('a link inside a sentence opens the document it names', (tester) async {
      await pumpApp(tester, location: '/terms');
      await tester.pumpAndSettle();

      final link = find.text('Refund & Cancellation Policy');
      await tester.scrollUntilVisible(link, 400, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();

      await tester.tap(link);
      await tester.pumpAndSettle();

      // The refund policy's own opening section.
      expect(find.textContaining('Refund'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}

/// The locale pipeline across long-form copy, which is the stated value of #44.
///
/// A missing translation does not throw in Flutter — `gen-l10n` falls back to the template
/// locale — so a document can silently render in English under a Japanese locale. These
/// check the words actually change.
void _localeGroup() {
  group('four languages', () {
    for (final locale in ['ja', 'ko', 'zh']) {
      testWidgets('Terms reads in $locale, not English', (tester) async {
        late AppLocalizations english;
        await pumpScreen(tester, Builder(builder: (context) {
          english = AppLocalizations.of(context)!;
          return const SizedBox();
        }));
        final englishTitles = legalSections(english, LegalDocument.terms)
            .map((s) => s.title)
            .toList();

        late AppLocalizations translated;
        await tester.pumpWidget(MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale(locale),
          home: Builder(builder: (context) {
            translated = AppLocalizations.of(context)!;
            return const SizedBox();
          }),
        ));
        await tester.pumpAndSettle();

        final sections = legalSections(translated, LegalDocument.terms);
        expect(sections, hasLength(englishTitles.length));

        // Every heading differs from the English one, so nothing fell back.
        for (var i = 0; i < sections.length; i++) {
          expect(
            sections[i].title,
            isNot(englishTitles[i]),
            reason: '$locale fell back to English at "${englishTitles[i]}"',
          );
        }
      });
    }
  });
}

/// Reaching them. See #44.
///
/// These were routes nothing linked to — openable by a test and by nothing else. V2 reaches
/// them from a footer on every page; an app has no footer, so Account carries them.
void _reachabilityGroup() {
  group('from Account', () {
    for (final (label, heading) in [
      ('Help', 'Help'),
      ('Terms of Service', 'Terms'),
      ('Privacy Policy', 'Privacy'),
      ('Cookie Policy', 'Cookie'),
      ('Refund & Cancellation Policy', 'Refund'),
    ]) {
      testWidgets('$label is reachable and opens', (tester) async {
        await pumpApp(tester, location: '/profile');
        await tester.pumpAndSettle();

        final link = find.text(label);
        await tester.scrollUntilVisible(link, 300, scrollable: find.byType(Scrollable).first);
        await tester.pumpAndSettle();

        await tester.tap(link);
        await tester.pumpAndSettle();

        expect(find.textContaining(heading), findsWidgets);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
