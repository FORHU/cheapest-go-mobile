import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:cheapest_go_mobile/features/legal/components/legal_blocks.dart';
import 'package:cheapest_go_mobile/features/legal/lib/legal_documents.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/app_colors.dart';

/// Terms, Privacy, Cookies and Refund — one screen, four documents. See #44.
///
/// V2 writes these as four 22-line pages that each hand a document name to one `LegalPage`,
/// and this is the same arrangement: the frame is here, the words are in
/// `legal_documents.dart`, and every one of them comes from the mirrored locale files.
///
/// The dates are V2's constants rather than today: a policy's effective date is a fact about
/// the policy, and showing when the page was opened would be a small lie about when the terms
/// last changed.
class LegalView extends StatelessWidget {
    const LegalView({required this.document, super.key});

    final LegalDocument document;

    /// V2's `LEGAL_EFFECTIVE_DATE` and `LEGAL_LAST_UPDATED`, which move when the documents do.
    static const effective = 'May 1, 2025';
    static const lastUpdated = 'April 1, 2025';

    @override
    Widget build(BuildContext context) {
        final t = AppLocalizations.of(context)!;
        final c = context.colors;
        final heading = legalHeading(t, document);

        return Scaffold(
            backgroundColor: c.background,
            appBar: AppBar(
                backgroundColor: c.background,
                surfaceTintColor: Colors.transparent,
                scrolledUnderElevation: 0,
                // Opaque, with a hairline under it, so long copy passing beneath the bar
                // stays separate from the title — see #61.
                bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(1),
                    child: Container(height: 1, color: c.border),
                ),
                leading: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    tooltip: t.common_goBack,
                    onPressed: () => context.canPop() ? context.pop() : context.go('/'),
                ),
                title: Text(heading.title, style: const TextStyle(fontSize: 18)),
            ),
            body: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
                children: [
                    Text(
                        heading.title,
                        style: TextStyle(
                            fontSize: 26,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                            color: c.textPrimary,
                        ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                        heading.subtitle,
                        style: TextStyle(fontSize: 14, height: 1.5, color: c.textMuted),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                        spacing: 16,
                        runSpacing: 4,
                        children: [
                            Text(
                                '${t.legal_layout_effective} $effective',
                                style: TextStyle(fontSize: 11.5, color: c.textSubtle),
                            ),
                            Text(
                                '${t.legal_layout_lastUpdated} $lastUpdated',
                                style: TextStyle(fontSize: 11.5, color: c.textSubtle),
                            ),
                        ],
                    ),
                    const SizedBox(height: 28),
                    for (final section in legalSections(t, document))
                        LegalSectionView(
                            section: section,
                            onFollow: (route) => context.push(route),
                        ),
                ],
            ),
        );
    }
}
