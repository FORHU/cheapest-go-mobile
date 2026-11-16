import 'package:flutter/material.dart';

import 'package:cheapest_go_mobile/shared/theme/tokens/app_colors.dart';

/// The pieces a legal document is written in. See #44.
///
/// V2 reads its sections straight out of the locale data, shaping each block by whichever
/// fields it happens to carry — `heading` or `label`, `body` or `text`. Mobile cannot do
/// that: `gen-l10n` turns the ARB into static getters, so nothing can iterate them and every
/// section has to be named. The blocks below are the same vocabulary, declared rather than
/// discovered.

/// One block of a section.
sealed class LegalBlock {
    const LegalBlock();
}

/// A paragraph.
class Para extends LegalBlock {
    const Para(this.text);
    final String text;
}

/// A bulleted list.
class Bullets extends LegalBlock {
    const Bullets(this.items);
    final List<String> items;
}

/// Entries that lead with a term — "Pricing", "Currency" — then explain it. V2 writes these
/// as `{label, text}` and renders the label in bold above its own line.
class Defined extends LegalBlock {
    const Defined(this.entries);
    final List<(String, String)> entries;
}

/// A sentence with a link inside it. The two halves are separate messages in V2, because a
/// translator has to be able to move the link within the sentence.
class Linked extends LegalBlock {
    const Linked({required this.before, required this.linkText, required this.route, this.after = ''});
    final String before;
    final String linkText;

    /// Where it goes in *this* app. V2's hrefs are web paths.
    final String route;
    final String after;
}

/// A quieter aside under a section — V2's `note`.
class Note extends LegalBlock {
    const Note(this.text);
    final String text;
}

/// A heading and the blocks beneath it.
class LegalSection {
    const LegalSection(this.title, this.blocks);
    final String title;
    final List<LegalBlock> blocks;
}

// ─── Drawing them ─────────────────────────────────────────────────────────────

class LegalSectionView extends StatelessWidget {
    const LegalSectionView({required this.section, required this.onFollow, super.key});

    final LegalSection section;
    final ValueChanged<String> onFollow;

    @override
    Widget build(BuildContext context) {
        final c = context.colors;

        return Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Text(
                        section.title,
                        style: TextStyle(
                            fontSize: 19,
                            height: 1.3,
                            fontWeight: FontWeight.w700,
                            color: c.textPrimary,
                        ),
                    ),
                    const SizedBox(height: 10),
                    for (final block in section.blocks) _BlockView(block: block, onFollow: onFollow),
                ],
            ),
        );
    }
}

class _BlockView extends StatelessWidget {
    const _BlockView({required this.block, required this.onFollow});

    final LegalBlock block;
    final ValueChanged<String> onFollow;

    @override
    Widget build(BuildContext context) {
        final c = context.colors;
        final body = TextStyle(fontSize: 14, height: 1.65, color: c.textSecondary);

        return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: switch (block) {
                Para(:final text) => Text(text, style: body),

                Bullets(:final items) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        for (final item in items)
                            Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                        Padding(
                                            padding: const EdgeInsets.only(top: 7, right: 10),
                                            child: Container(
                                                width: 4,
                                                height: 4,
                                                decoration: BoxDecoration(
                                                    color: c.textSubtle,
                                                    shape: BoxShape.circle,
                                                ),
                                            ),
                                        ),
                                        Expanded(child: Text(item, style: body)),
                                    ],
                                ),
                            ),
                    ],
                ),

                Defined(:final entries) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        for (final (label, text) in entries)
                            Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                        Text(
                                            label,
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: c.textPrimary,
                                            ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(text, style: body),
                                    ],
                                ),
                            ),
                    ],
                ),

                // The link sits inside the sentence, where the translation put it.
                Linked(:final before, :final linkText, :final route, :final after) => Text.rich(
                    TextSpan(
                        style: body,
                        children: [
                            TextSpan(text: before),
                            WidgetSpan(
                                alignment: PlaceholderAlignment.baseline,
                                baseline: TextBaseline.alphabetic,
                                child: GestureDetector(
                                    onTap: () => onFollow(route),
                                    child: Text(
                                        linkText,
                                        style: body.copyWith(
                                            color: c.accent,
                                            decoration: TextDecoration.underline,
                                            decorationColor: c.accent,
                                        ),
                                    ),
                                ),
                            ),
                            TextSpan(text: after),
                        ],
                    ),
                ),

                Note(:final text) => Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: c.surfaceMuted,
                        borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                        text,
                        style: TextStyle(fontSize: 13, height: 1.55, color: c.textMuted),
                    ),
                ),
            },
        );
    }
}
