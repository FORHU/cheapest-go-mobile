import 'package:flutter/material.dart';

import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/generated/tw_palette.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/generated/tw_scale.dart';

/// V2's `/about` at its mobile breakpoint.
///
/// The first screen built under the parity rules, and the reason it is this one: a static page
/// carries no state, no network and no supplier, so what it proves is the plumbing — that
/// colours come from the mirrored tokens, that every string comes from V2's own translations,
/// and that the result reads as the same screen. See docs/adr/0002.
///
/// Nothing here chooses a colour or a size. Every value is a token; where V2 writes
/// `text-slate-400`, this writes `TwPalette.slate400`, and the two mean the same thing because
/// both come from the same `globals.css` at the pinned commit.
class AboutView extends StatelessWidget {
    const AboutView({super.key});

    @override
    Widget build(BuildContext context) {
        // Non-null wherever the app's delegates are installed, which is everywhere below
        // MaterialApp. Flutter 3.47 dropped the option that made this getter non-nullable.
        final t = AppLocalizations.of(context)!;
        final dark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
            backgroundColor: dark ? TwPalette.slate950 : Colors.white,
            body: SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                        _Hero(t: t),
                        Padding(
                            // px-4 py-14
                            padding: EdgeInsets.symmetric(
                                horizontal: TwSpace.of(4),
                                vertical: TwSpace.of(14),
                            ),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _spaced([
                                    _Mission(t: t, dark: dark),
                                    _WhatWeDo(t: t, dark: dark),
                                    _Values(t: t, dark: dark),
                                    _Partners(t: t, dark: dark),
                                    _CompanyAndCta(t: t, dark: dark),
                                ], gap: TwSpace.of(20)),  // space-y-20
                            ),
                        ),
                    ],
                ),
            ),
        );
    }
}

/// `space-y-N`: a gap between children, not around them.
List<Widget> _spaced(List<Widget> children, {required double gap}) {
    final out = <Widget>[];
    for (var i = 0; i < children.length; i++) {
        if (i > 0) out.add(SizedBox(height: gap));
        out.add(children[i]);
    }
    return out;
}

/// `leading-relaxed`, which Tailwind sets to 1.625 regardless of the size it sits on.
const _relaxed = 1.625;

class _Hero extends StatelessWidget {
    const _Hero({required this.t});

    final AppLocalizations t;

    @override
    Widget build(BuildContext context) {
        return Container(
            width: double.infinity,
            // bg-obsidian, border-b border-white/5, px-4 py-16
            decoration: const BoxDecoration(
                color: TwPalette.obsidian,
                border: Border(bottom: BorderSide(color: Color(0x0DFFFFFF))),
            ),
            padding: EdgeInsets.symmetric(
                horizontal: TwSpace.of(4),
                vertical: TwSpace.of(16),
            ),
            child: Column(
                children: [
                    Text(
                        t.about_heroLabel,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: TwFonts.display,
                            fontSize: TwText.xs.size,
                            height: TwText.xs.height,
                            fontWeight: FontWeight.w600,
                            // tracking-widest is 0.1em
                            letterSpacing: TwText.xs.size * 0.1,
                            color: TwPalette.obsidianAccent,
                        ).copyWith(textBaseline: TextBaseline.alphabetic),
                    ),
                    SizedBox(height: TwSpace.of(4)),
                    Text(
                        t.about_heroTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: TwFonts.display,
                            fontSize: TwText.n3xl.size,
                            height: TwText.n3xl.height,
                            fontWeight: FontWeight.w800,
                            // tracking-tight is -0.025em
                            letterSpacing: TwText.n3xl.size * -0.025,
                            color: Colors.white,
                        ),
                    ),
                    SizedBox(height: TwSpace.of(5)),
                    Text(
                        t.about_heroBody,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: TwText.base.size,
                            height: _relaxed,
                            color: TwPalette.slate400,
                        ),
                    ),
                ],
            ),
        );
    }
}

/// `text-2xl font-bold ... font-display`, the heading every section below opens with.
class _SectionHeading extends StatelessWidget {
    const _SectionHeading(this.text, {required this.dark});

    final String text;
    final bool dark;

    @override
    Widget build(BuildContext context) {
        return Text(
            text,
            style: TextStyle(
                fontFamily: TwFonts.display,
                fontSize: TwText.n2xl.size,
                height: TwText.n2xl.height,
                fontWeight: FontWeight.w700,
                color: dark ? Colors.white : TwPalette.slate900,
            ),
        );
    }
}

class _Mission extends StatelessWidget {
    const _Mission({required this.t, required this.dark});

    final AppLocalizations t;
    final bool dark;

    @override
    Widget build(BuildContext context) {
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                _SectionHeading(t.about_missionTitle, dark: dark),
                SizedBox(height: TwSpace.of(4)),
                Text(
                    t.about_missionBody,
                    style: TextStyle(
                        fontSize: TwText.base.size,
                        height: _relaxed,
                        color: dark ? TwPalette.slate300 : TwPalette.slate600,
                    ),
                ),
            ],
        );
    }
}

/// The bordered, rounded panel both card sections are built from.
class _Panel extends StatelessWidget {
    const _Panel({required this.child, required this.dark});

    final Widget child;
    final bool dark;

    @override
    Widget build(BuildContext context) {
        return Container(
            width: double.infinity,
            padding: EdgeInsets.all(TwSpace.of(6)),
            decoration: BoxDecoration(
                // bg-white dark:bg-slate-900, border-slate-200 dark:border-white/10
                color: dark ? TwPalette.slate900 : Colors.white,
                border: Border.all(
                    color: dark ? const Color(0x1AFFFFFF) : TwPalette.slate200,
                ),
                borderRadius: BorderRadius.circular(TwRadius.n2xl),
            ),
            child: child,
        );
    }
}

/// `size-11 rounded-xl bg-blue-50 dark:bg-blue-500/10` with a 20px glyph inside.
class _IconTile extends StatelessWidget {
    const _IconTile(this.icon, {required this.dark});

    final IconData icon;
    final bool dark;

    @override
    Widget build(BuildContext context) {
        return Container(
            width: TwSpace.of(11),
            height: TwSpace.of(11),
            decoration: BoxDecoration(
                color: dark ? const Color(0x1A3B82F6) : TwPalette.blue50,
                borderRadius: BorderRadius.circular(TwRadius.xl),
            ),
            child: Icon(
                icon,
                size: TwSpace.of(5),
                color: dark ? TwPalette.blue400 : TwPalette.blue600,
            ),
        );
    }
}

class _WhatWeDo extends StatelessWidget {
    const _WhatWeDo({required this.t, required this.dark});

    final AppLocalizations t;
    final bool dark;

    @override
    Widget build(BuildContext context) {
        final cards = [
            (Icons.flight_takeoff, t.about_flightsTitle, t.about_flightsBody),
            (Icons.king_bed_outlined, t.about_hotelsTitle, t.about_hotelsBody),
            (Icons.inventory_2_outlined, t.about_dealsTitle, t.about_dealsBody),
        ];

        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                _SectionHeading(t.about_whatWeDoTitle, dark: dark),
                SizedBox(height: TwSpace.of(8)),
                // One column at this width; V2's `sm:grid-cols-3` is a tablet and up.
                ..._spaced([
                    for (final (icon, title, body) in cards)
                        _Panel(
                            dark: dark,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    _IconTile(icon, dark: dark),
                                    SizedBox(height: TwSpace.of(4)),
                                    Text(
                                        title,
                                        style: TextStyle(
                                            fontSize: TwText.base.size,
                                            height: TwText.base.height,
                                            fontWeight: FontWeight.w700,
                                            color: dark ? Colors.white : TwPalette.slate900,
                                        ),
                                    ),
                                    SizedBox(height: TwSpace.of(1.5)),
                                    Text(
                                        body,
                                        style: TextStyle(
                                            fontSize: TwText.sm.size,
                                            height: _relaxed,
                                            color: dark ? TwPalette.slate400 : TwPalette.slate500,
                                        ),
                                    ),
                                ],
                            ),
                        ),
                ], gap: TwSpace.of(5)),
            ],
        );
    }
}

class _Values extends StatelessWidget {
    const _Values({required this.t, required this.dark});

    final AppLocalizations t;
    final bool dark;

    @override
    Widget build(BuildContext context) {
        final rows = [
            (Icons.percent, t.about_transparentTitle, t.about_transparentBody),
            (Icons.verified_user_outlined, t.about_secureTitle, t.about_secureBody),
            (Icons.public, t.about_builtTitle, t.about_builtBody),
        ];

        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                _SectionHeading(t.about_valuesTitle, dark: dark),
                SizedBox(height: TwSpace.of(8)),
                ..._spaced([
                    for (final (icon, title, body) in rows)
                        _Panel(
                            dark: dark,
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    _IconTile(icon, dark: dark),
                                    SizedBox(width: TwSpace.of(4)),
                                    Expanded(
                                        child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                                Text(
                                                    title,
                                                    style: TextStyle(
                                                        fontSize: TwText.base.size,
                                                        height: TwText.base.height,
                                                        fontWeight: FontWeight.w700,
                                                        color: dark ? Colors.white : TwPalette.slate900,
                                                    ),
                                                ),
                                                SizedBox(height: TwSpace.of(1)),
                                                Text(
                                                    body,
                                                    style: TextStyle(
                                                        fontSize: TwText.sm.size,
                                                        height: _relaxed,
                                                        color: dark ? TwPalette.slate400 : TwPalette.slate600,
                                                    ),
                                                ),
                                            ],
                                        ),
                                    ),
                                ],
                            ),
                        ),
                ], gap: TwSpace.of(4)),
            ],
        );
    }
}

class _Partners extends StatelessWidget {
    const _Partners({required this.t, required this.dark});

    final AppLocalizations t;
    final bool dark;

    /// Not translated on V2 either — they are company names.
    static const _partners = ['Duffel', 'TravelgateX', 'Stripe'];

    @override
    Widget build(BuildContext context) {
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                _SectionHeading(t.about_partnersTitle, dark: dark),
                SizedBox(height: TwSpace.of(3)),
                Text(
                    t.about_partnersBody,
                    style: TextStyle(
                        fontSize: TwText.base.size,
                        height: _relaxed,
                        color: dark ? TwPalette.slate400 : TwPalette.slate600,
                    ),
                ),
                SizedBox(height: TwSpace.of(6)),
                Wrap(
                    spacing: TwSpace.of(2.5),
                    runSpacing: TwSpace.of(2.5),
                    children: [
                        for (final name in _partners)
                            Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: TwSpace.of(4),
                                    vertical: TwSpace.of(2),
                                ),
                                decoration: BoxDecoration(
                                    color: dark ? TwPalette.slate900 : Colors.white,
                                    border: Border.all(
                                        color: dark ? const Color(0x1AFFFFFF) : TwPalette.slate200,
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                    name,
                                    style: TextStyle(
                                        fontSize: TwText.sm.size,
                                        height: TwText.sm.height,
                                        fontWeight: FontWeight.w500,
                                        color: dark ? TwPalette.slate300 : TwPalette.slate700,
                                    ),
                                ),
                            ),
                    ],
                ),
            ],
        );
    }
}

class _CompanyAndCta extends StatelessWidget {
    const _CompanyAndCta({required this.t, required this.dark});

    final AppLocalizations t;
    final bool dark;

    @override
    Widget build(BuildContext context) {
        final hairline = dark ? const Color(0x1AFFFFFF) : TwPalette.slate200;

        return Container(
            padding: EdgeInsets.all(TwSpace.of(6)),
            decoration: BoxDecoration(
                // bg-slate-50 dark:bg-white/5
                color: dark ? const Color(0x0DFFFFFF) : TwPalette.slate50,
                border: Border.all(color: hairline),
                borderRadius: BorderRadius.circular(TwRadius.n2xl),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Text(
                        t.about_whoTitle,
                        style: TextStyle(
                            fontFamily: TwFonts.display,
                            fontSize: TwText.xl.size,
                            height: TwText.xl.height,
                            fontWeight: FontWeight.w700,
                            color: dark ? Colors.white : TwPalette.slate900,
                        ),
                    ),
                    SizedBox(height: TwSpace.of(4)),
                    Text(
                        t.about_whoBody,
                        style: TextStyle(
                            fontSize: TwText.sm.size,
                            height: _relaxed,
                            color: dark ? TwPalette.slate400 : TwPalette.slate600,
                        ),
                    ),
                    SizedBox(height: TwSpace.of(6)),

                    // `flex-col` at this width; the row arrangement is V2's `sm:` and up.
                    _CtaButton(
                        label: t.about_contactUs,
                        icon: Icons.mail_outline,
                        filled: true,
                        dark: dark,
                    ),
                    SizedBox(height: TwSpace.of(3)),
                    _CtaButton(
                        label: t.about_startExploring,
                        trailingIcon: Icons.arrow_forward,
                        filled: false,
                        dark: dark,
                    ),

                    SizedBox(height: TwSpace.of(6)),
                    Container(
                        padding: EdgeInsets.only(top: TwSpace.of(6)),
                        decoration: BoxDecoration(
                            border: Border(top: BorderSide(color: hairline)),
                        ),
                        child: Wrap(
                            spacing: TwSpace.of(5),
                            runSpacing: TwSpace.of(2),
                            children: [
                                for (final label in [t.about_terms, t.about_privacy, t.about_refund])
                                    Text(
                                        label,
                                        style: TextStyle(
                                            fontSize: TwText.xs.size,
                                            height: TwText.xs.height,
                                            color: dark ? TwPalette.slate400 : TwPalette.slate500,
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

class _CtaButton extends StatelessWidget {
    const _CtaButton({
        required this.label,
        required this.filled,
        required this.dark,
        this.icon,
        this.trailingIcon,
    });

    final String label;
    final bool filled;
    final bool dark;
    final IconData? icon;
    final IconData? trailingIcon;

    @override
    Widget build(BuildContext context) {
        final foreground = filled
            ? Colors.white
            : (dark ? TwPalette.slate200 : TwPalette.slate700);

        return Container(
            padding: EdgeInsets.symmetric(
                horizontal: TwSpace.of(5),
                vertical: TwSpace.of(3),
            ),
            decoration: BoxDecoration(
                color: filled ? TwPalette.blue600 : null,
                border: filled
                    ? null
                    : Border.all(color: dark ? const Color(0x1AFFFFFF) : TwPalette.slate200),
                borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    if (icon != null) ...[
                        Icon(icon, size: TwSpace.of(4), color: foreground),
                        SizedBox(width: TwSpace.of(2)),
                    ],
                    Text(
                        label,
                        style: TextStyle(
                            fontSize: TwText.sm.size,
                            height: TwText.sm.height,
                            fontWeight: FontWeight.w500,
                            color: foreground,
                        ),
                    ),
                    if (trailingIcon != null) ...[
                        SizedBox(width: TwSpace.of(2)),
                        Icon(trailingIcon, size: TwSpace.of(4), color: foreground),
                    ],
                ],
            ),
        );
    }
}
