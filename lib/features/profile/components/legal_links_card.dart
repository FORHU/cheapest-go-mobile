import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/app_colors.dart';

/// Help, the four legal documents and About, from Account. See #44.
///
/// V2 reaches these from a footer on every page. An app has no footer, and the account
/// screen is where the same material sits on a phone — so these six live here rather than
/// being routes only a deep link could open.
///
/// Every label is a mirrored message, and the page titles are used rather than the browser
/// titles: those end in "— CheapestGo", which reads as a repetition in a list inside the app.
class LegalLinksCard extends StatelessWidget {
    const LegalLinksCard({super.key});

    @override
    Widget build(BuildContext context) {
        final t = AppLocalizations.of(context)!;
        final c = context.colors;

        // Help first: somebody opening this group usually has a problem, not a curiosity.
        final links = <(String, String, IconData)>[
            (t.help_pageTitle, '/help', Icons.help_outline_rounded),
            (t.legal_termsOfService_pageTitle, '/terms', Icons.description_outlined),
            (t.legal_privacyPolicy_pageTitle, '/privacy', Icons.lock_outline_rounded),
            (t.legal_cookiePolicy_pageTitle, '/cookies', Icons.cookie_outlined),
            (t.legal_refundPolicy_pageTitle, '/refund', Icons.receipt_long_outlined),
            (t.footer_aboutUs, '/about', Icons.info_outline_rounded),
        ];

        // Material, not a DecoratedBox: a ListTile paints its ink on the nearest Material
        // ancestor, so a coloured box between the two swallows the ripple.
        return Material(
            color: c.surface,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
                side: BorderSide(color: c.border),
                borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
                children: [
                    for (final (index, (label, route, icon)) in links.indexed) ...[
                        if (index > 0) Divider(height: 1, indent: 52, color: c.border),
                        ListTile(
                            onTap: () => context.push(route),
                            leading: Icon(icon, size: 20, color: c.textMuted),
                            title: Text(
                                label,
                                style: TextStyle(fontSize: 14, color: c.textPrimary),
                            ),
                            trailing: Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: c.textSubtle,
                            ),
                        ),
                    ],
                ],
            ),
        );
    }
}
