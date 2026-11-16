import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/app_colors.dart';

/// Help — the questions people ask most, and how to reach a person. See #44.
///
/// The five questions are in V2's order, which it takes from `QUICK_QUESTIONS` and shares
/// with the support widget: most-asked first, so the page and the widget agree about what
/// people actually ask. That order is a fact about the questions, not a layout choice, which
/// is why it is spelled out here rather than sorted.
///
/// Read without signing in, as V2's is: somebody whose booking has gone wrong may not be able
/// to get into their account, and that is exactly when they need this page.
class HelpView extends StatelessWidget {
    const HelpView({super.key});

    @override
    Widget build(BuildContext context) {
        final t = AppLocalizations.of(context)!;
        final c = context.colors;

        final questions = <(String, String)>[
            (t.help_sections_confirmation_title, t.help_sections_confirmation_body),
            (t.help_sections_refunds_title, t.help_sections_refunds_body),
            (t.help_sections_changes_title, t.help_sections_changes_body),
            (t.help_sections_priceGap_title, t.help_sections_priceGap_body),
            (t.help_sections_payment_title, t.help_sections_payment_body),
        ];

        return Scaffold(
            backgroundColor: c.background,
            appBar: AppBar(
                backgroundColor: c.background,
                surfaceTintColor: Colors.transparent,
                scrolledUnderElevation: 0,
                bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(1),
                    child: Container(height: 1, color: c.border),
                ),
                leading: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    tooltip: t.common_goBack,
                    onPressed: () => context.canPop() ? context.pop() : context.go('/'),
                ),
                title: Text(t.help_pageTitle, style: const TextStyle(fontSize: 18)),
            ),
            body: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
                children: [
                    Text(
                        t.help_pageTitle,
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: c.textPrimary,
                        ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                        t.help_pageSubtitle,
                        style: TextStyle(fontSize: 14, height: 1.5, color: c.textMuted),
                    ),
                    const SizedBox(height: 32),

                    for (final (title, body) in questions) ...[
                        Text(
                            title,
                            style: TextStyle(
                                fontSize: 17,
                                height: 1.3,
                                fontWeight: FontWeight.w700,
                                color: c.textPrimary,
                            ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                            body,
                            style: TextStyle(fontSize: 14, height: 1.65, color: c.textSecondary),
                        ),
                        const SizedBox(height: 28),
                    ],

                    // The refund answer carries a link of its own, which V2 writes as a
                    // separate message so a translator can word it.
                    Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                            onPressed: () => context.push('/refund'),
                            child: Text(t.help_sections_refunds_link),
                        ),
                    ),
                    const SizedBox(height: 12),

                    Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                            border: Border.all(color: c.border),
                            borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text(
                                    t.help_chatCta,
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: c.textPrimary,
                                    ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                    t.help_chatNote,
                                    style: TextStyle(fontSize: 13, height: 1.55, color: c.textMuted),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                    t.help_contactHeading,
                                    style: TextStyle(fontSize: 13, color: c.textSecondary),
                                ),
                            ],
                        ),
                    ),
                ],
            ),
        );
    }
}
