import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:cheapest_go_mobile/features/hotels/api/checkout_api.dart';
import 'package:cheapest_go_mobile/features/hotels/lib/booking_status.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/app_colors.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/generated/tw_palette.dart';

/// Where a booking is — V2's `/booking/[reference]` (`booking-status-view.tsx`). See #50.
///
/// Reached two ways: from the checkout, when the confirm answered "not settled yet" and the
/// card has been charged, and from a stay in Trips. It asks the server, keeps asking while the
/// answer is "not yet", and never invents a reference: the one it shows is the one in the
/// address, or the one the server answered with.
///
/// V2 also asks a signed-out visitor to sign in first. Mobile has no signed-out visitor — the
/// gate (ADR-0005) holds every route until there is an account — so that branch is not here.
///
/// The one addition is the back arrow. V2's page is a browser tab with a back button of its
/// own; this is a full screen outside the tabs, which needs one.
class BookingStatusView extends StatefulWidget {
    const BookingStatusView({
        required this.reference,
        this.fetch,
        this.pollInterval = const Duration(seconds: 3),
        super.key,
    });

    final String reference;

    /// The status call; the app's [checkoutApi] when not given. Replaced in tests.
    final Future<ConfirmOutcome> Function(String reference)? fetch;
    final Duration pollInterval;

    @override
    State<BookingStatusView> createState() => _BookingStatusViewState();
}

class _BookingStatusViewState extends State<BookingStatusView> {
    late final BookingStatusPoller _status = BookingStatusPoller(
        reference: widget.reference,
        fetch: widget.fetch ?? checkoutApi.bookingStatus,
        interval: widget.pollInterval,
    )..start();

    @override
    void dispose() {
        _status.dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        final t = AppLocalizations.of(context)!;
        final p = _Palette.of(context);

        return Scaffold(
            backgroundColor: p.ground,
            appBar: AppBar(
                backgroundColor: p.ground,
                surfaceTintColor: Colors.transparent,
                scrolledUnderElevation: 0,
                leading: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    tooltip: t.common_goBack,
                    onPressed: () => context.canPop() ? context.pop() : context.go('/trips'),
                ),
            ),
            body: SafeArea(
                top: false,
                child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
                    children: [
                        Center(
                            child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 640),
                                child: ListenableBuilder(
                                    listenable: _status,
                                    builder: (context, _) => _StatusBody(
                                        reference: widget.reference,
                                        status: _status,
                                        palette: p,
                                    ),
                                ),
                            ),
                        ),
                    ],
                ),
            ),
        );
    }
}

class _StatusBody extends StatelessWidget {
    const _StatusBody({required this.reference, required this.status, required this.palette});

    final String reference;
    final BookingStatusPoller status;
    final _Palette palette;

    @override
    Widget build(BuildContext context) {
        final t = AppLocalizations.of(context)!;
        final p = palette;
        final outcome = status.outcome;

        if (status.load == BookingLoad.loading) {
            return _Quiet(t.checkout_bookingPage_loading, palette: p);
        }

        if (status.load == BookingLoad.notFound) {
            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    _Heading(t.checkout_bookingPage_notFound, palette: p),
                    _Quiet(t.checkout_bookingPage_notFoundDescription, palette: p),
                ],
            );
        }

        if (status.load == BookingLoad.error || outcome == null) {
            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    _Quiet(t.checkout_supplierDown_description, palette: p),
                    _GradientButton(label: t.checkout_bookingPage_refresh, onPressed: status.refresh),
                ],
            );
        }

        final settled = outcome;
        switch (settled.state) {
            case ConfirmState.confirmed:
                return Semantics(
                    liveRegion: true,
                    child: Column(
                        children: [
                            Container(
                                width: 72,
                                height: 72,
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
                                child: const Icon(LucideIcons.check, size: 36, color: Colors.white),
                            ),
                            Text(
                                t.checkout_booked,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: p.title),
                            ),
                            _Quiet(t.checkout_success_hotelSuccess, palette: p, center: true),
                            const SizedBox(height: 14),
                            _ReferenceLine(reference: settled.reference, palette: p, center: true),
                            _GradientButton(
                                label: t.checkout_success_viewMyTrips,
                                onPressed: () => context.go('/trips'),
                            ),
                        ],
                    ),
                );

            case ConfirmState.failed:
                return _Panel(
                    palette: p,
                    tone: _danger,
                    icon: LucideIcons.triangleAlert,
                    title: t.checkout_failed_title,
                    children: [
                        _Body(settled.message, palette: p),
                        // Said only when the server said the hold was released. Never inferred.
                        _Body(settled.released ? t.checkout_failed_released : t.checkout_failed_unknown, palette: p),
                        _Actions([
                            _PanelButton(label: t.checkout_failed_tryAgain, palette: p, onPressed: () => context.go('/')),
                        ]),
                    ],
                );

            case ConfirmState.pending:
            case ConfirmState.needsReview:
                final review = settled.state == ConfirmState.needsReview;
                final shown = settled.reference.isNotEmpty ? settled.reference : reference;
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        _Panel(
                            palette: p,
                            tone: review ? _accent : _green,
                            icon: LucideIcons.clock,
                            title: review ? t.checkout_needsReview_title : t.checkout_settling_title,
                            children: [
                                _Body(
                                    review ? t.checkout_needsReview_description : t.checkout_settling_description,
                                    palette: p,
                                ),
                                _Body(t.checkout_settling_doNotPayAgain, palette: p),
                                if (shown.isNotEmpty)
                                    Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: _ReferenceLine(reference: shown, palette: p),
                                    ),
                                _Actions([
                                    _PanelButton(
                                        label: t.checkout_settling_checkTrips,
                                        palette: p,
                                        quiet: true,
                                        onPressed: () => context.go('/trips'),
                                    ),
                                ]),
                            ],
                        ),
                        if (status.exhausted)
                            _GradientButton(label: t.checkout_bookingPage_refresh, onPressed: status.refresh)
                        else
                            _Quiet(t.checkout_bookingPage_stillWorking, palette: p),
                    ],
                );
        }
    }
}

// ─── Colours ──────────────────────────────────────────────────────────────────

/// V2's checkout accent, blue-500, and its stamp green and danger red (`lib/palette.ts`).
const _accent = TwPalette.blue500;
const _green = Color(0xFF2FB67F);
const _danger = Color(0xFFE4685A);

/// The slice of V2's `checkoutPalette` this page paints with, picked by theme.
class _Palette {
    const _Palette({
        required this.ground,
        required this.title,
        required this.soft,
        required this.surface,
        required this.cardLine,
    });

    factory _Palette.of(BuildContext context) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        final c = context.colors;
        return _Palette(
            ground: c.background,
            title: c.textPrimary,
            soft: dark ? TwPalette.slate300 : TwPalette.slate600,
            surface: dark ? TwPalette.slate900 : TwPalette.slate100,
            cardLine: dark ? const Color(0x24FFFFFF) : TwPalette.slate300,
        );
    }

    final Color ground;
    final Color title;
    final Color soft;
    final Color surface;
    final Color cardLine;
}

// ─── Parts ────────────────────────────────────────────────────────────────────

class _Heading extends StatelessWidget {
    const _Heading(this.text, {required this.palette});

    final String text;
    final _Palette palette;

    @override
    Widget build(BuildContext context) => Semantics(
        header: true,
        child: Text(text, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: palette.title)),
    );
}

/// V2's `Quiet`: the page's one size of explanation.
class _Quiet extends StatelessWidget {
    const _Quiet(this.text, {required this.palette, this.center = false});

    final String text;
    final _Palette palette;
    final bool center;

    @override
    Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Text(
            text,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: TextStyle(fontSize: 15, height: 1.5, color: palette.soft),
        ),
    );
}

/// "Booking Reference: CG-…", the reference bold and selectable — the one thing on this page
/// somebody copies.
class _ReferenceLine extends StatelessWidget {
    const _ReferenceLine({required this.reference, required this.palette, this.center = false});

    final String reference;
    final _Palette palette;
    final bool center;

    @override
    Widget build(BuildContext context) {
        final t = AppLocalizations.of(context)!;
        return SelectableText.rich(
            TextSpan(
                style: TextStyle(fontSize: 14, height: 1.5, color: palette.soft),
                children: [
                    TextSpan(text: '${t.checkout_bookingReference}: '),
                    TextSpan(
                        text: reference,
                        style: TextStyle(fontWeight: FontWeight.w700, color: palette.title),
                    ),
                ],
            ),
            textAlign: center ? TextAlign.center : TextAlign.start,
        );
    }
}

/// The page's one action, in the brand gradient — the same fill as the checkout's own.
class _GradientButton extends StatelessWidget {
    const _GradientButton({required this.label, required this.onPressed});

    final String label;
    final VoidCallback onPressed;

    @override
    Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 16),
        child: _Pill(
            label: label,
            onPressed: onPressed,
            gradient: kBrandGradient,
            shadow: _gradientShadow,
            foreground: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        ),
    );
}

/// V2's `BRAND.gradientShadow`: `0 8px 20px -8px rgba(37,99,235,.6)`.
const _gradientShadow = BoxShadow(
    color: Color(0x992563EB),
    offset: Offset(0, 8),
    blurRadius: 20,
    spreadRadius: -8,
);

/// V2's `Panel` from `booking-state-panels.tsx`: a raised plate ringed in its tone, an icon,
/// a title, and what to do next.
class _Panel extends StatelessWidget {
    const _Panel({
        required this.palette,
        required this.tone,
        required this.icon,
        required this.title,
        required this.children,
    });

    final _Palette palette;
    final Color tone;
    final IconData icon;
    final String title;
    final List<Widget> children;

    @override
    Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        container: true,
        child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: tone, width: 1.5),
            ),
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(icon, size: 22, color: tone),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Semantics(
                                    header: true,
                                    child: Text(
                                        title,
                                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: palette.title),
                                    ),
                                ),
                                ...children,
                            ],
                        ),
                    ),
                ],
            ),
        ),
    );
}

class _Body extends StatelessWidget {
    const _Body(this.text, {required this.palette});

    final String text;
    final _Palette palette;

    @override
    Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(text, style: TextStyle(fontSize: 14, height: 1.5, color: palette.soft)),
    );
}

class _Actions extends StatelessWidget {
    const _Actions(this.children);

    final List<Widget> children;

    @override
    Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Wrap(spacing: 10, runSpacing: 10, children: children),
    );
}

/// A panel's button: the way forward in the brand gradient, or a quiet outline beside it.
class _PanelButton extends StatelessWidget {
    const _PanelButton({required this.label, required this.palette, required this.onPressed, this.quiet = false});

    final String label;
    final _Palette palette;
    final VoidCallback onPressed;
    final bool quiet;

    @override
    Widget build(BuildContext context) => _Pill(
        label: label,
        onPressed: onPressed,
        gradient: quiet ? null : kBrandGradient,
        shadow: quiet ? null : _gradientShadow,
        border: quiet ? Border.all(color: palette.cardLine, width: 1.5) : null,
        foreground: quiet ? palette.title : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
    );
}

class _Pill extends StatelessWidget {
    const _Pill({
        required this.label,
        required this.onPressed,
        required this.foreground,
        required this.padding,
        this.gradient,
        this.shadow,
        this.border,
    });

    final String label;
    final VoidCallback onPressed;
    final Color foreground;
    final EdgeInsets padding;
    final Gradient? gradient;
    final BoxShadow? shadow;
    final BoxBorder? border;

    @override
    Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
            gradient: gradient,
            border: border,
            borderRadius: BorderRadius.circular(999),
            boxShadow: shadow == null ? null : [shadow!],
        ),
        child: Material(
            type: MaterialType.transparency,
            child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(999),
                child: ConstrainedBox(
                    // 44 tall at the least, for a thumb; V2's padding alone makes ~41.
                    constraints: const BoxConstraints(minHeight: 44),
                    child: Padding(
                        padding: padding,
                        child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: foreground),
                        ),
                    ),
                ),
            ),
        ),
    );
}
