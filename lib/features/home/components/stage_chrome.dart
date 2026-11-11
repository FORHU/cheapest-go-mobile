import 'package:flutter/material.dart';

import 'package:cheapest_go_mobile/shared/theme/tokens/generated/tw_palette.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/generated/tw_scale.dart';

/// The Stage's own chrome: glass panels and gradient buttons, as V2 draws them over the
/// showcase photograph. See #38.
///
/// None of this takes the app theme. The Stage is always on the photograph, so its surfaces
/// are translucent dark and its type is light whichever theme the rest of the app is in —
/// which is also true on V2, where the landing looks the same in light mode.

/// Blue to cyan, V2's `BRAND_STOPS`. The one gradient in the product, used for the thing the
/// visitor is meant to press.
const brandGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF2563EB), Color(0xFF06B6D4)],
);

/// A translucent panel with a hairline, blurred so the photograph behind it reads as depth
/// rather than noise under the text.
class GlassPanel extends StatelessWidget {
    const GlassPanel({
        required this.child,
        this.padding,
        this.radius,
        this.highlighted = false,
        super.key,
    });

    final Widget child;
    final EdgeInsetsGeometry? padding;
    final double? radius;

    /// The chosen one of a set: a brighter edge and a blue cast, as V2 marks a selection.
    final bool highlighted;

    @override
    Widget build(BuildContext context) {
        final corner = BorderRadius.circular(radius ?? TwRadius.n2xl);

        // Translucency and a hairline, not a BackdropFilter. The blur version mispainted:
        // inside a scrolling list, a backdrop filter samples a layer that has already moved,
        // and the result was the tabs, the step trail and the question drawn on top of one
        // another. The photograph behind is dark enough that the blur was doing little that
        // the tint does not, and this costs nothing per frame.
        return Container(
            padding: padding ?? EdgeInsets.all(TwSpace.of(4)),
            decoration: BoxDecoration(
                color: highlighted ? const Color(0x332563EB) : const Color(0x730B1222),
                borderRadius: corner,
                border: Border.all(
                    color: highlighted ? const Color(0x802563EB) : const Color(0x26FFFFFF),
                ),
            ),
            child: child,
        );
    }
}

/// The button that moves the search on. Gradient, pill, white type, arrow trailing.
class GradientPill extends StatelessWidget {
    const GradientPill({
        required this.label,
        required this.onPressed,
        this.icon,
        this.trailingIcon,
        super.key,
    });

    final String label;
    final VoidCallback? onPressed;
    final IconData? icon;
    final IconData? trailingIcon;

    @override
    Widget build(BuildContext context) {
        final enabled = onPressed != null;
        return Opacity(
            opacity: enabled ? 1 : 0.45,
            child: Material(
                color: Colors.transparent,
                child: InkWell(
                    onTap: onPressed,
                    borderRadius: BorderRadius.circular(999),
                    child: Ink(
                        decoration: BoxDecoration(
                            gradient: brandGradient,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: const [
                                // V2: 0 6px 18px -6px rgba(37,99,235,.65)
                                BoxShadow(
                                    color: Color(0xA62563EB),
                                    blurRadius: 18,
                                    spreadRadius: -6,
                                    offset: Offset(0, 6),
                                ),
                            ],
                        ),
                        child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: TwSpace.of(5),
                                vertical: TwSpace.of(3),
                            ),
                            child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                    if (icon != null) ...[
                                        Icon(icon, size: 16, color: Colors.white),
                                        SizedBox(width: TwSpace.of(2)),
                                    ],
                                    Text(
                                        label,
                                        style: TextStyle(
                                            fontSize: TwText.sm.size,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                        ),
                                    ),
                                    if (trailingIcon != null) ...[
                                        SizedBox(width: TwSpace.of(2)),
                                        Icon(trailingIcon, size: 16, color: Colors.white),
                                    ],
                                ],
                            ),
                        ),
                    ),
                ),
            ),
        );
    }
}

/// Going back is not the thing to press, so it is glass rather than gradient.
class GlassPill extends StatelessWidget {
    const GlassPill({required this.label, required this.onPressed, this.icon, super.key});

    final String label;
    final VoidCallback onPressed;
    final IconData? icon;

    @override
    Widget build(BuildContext context) {
        return Material(
            color: Colors.transparent,
            child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: TwSpace.of(4),
                        vertical: TwSpace.of(3),
                    ),
                    decoration: BoxDecoration(
                        color: const Color(0x3D0B1222),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0x26FFFFFF)),
                    ),
                    child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                            if (icon != null) ...[
                                Icon(icon, size: 16, color: Colors.white),
                                SizedBox(width: TwSpace.of(2)),
                            ],
                            Text(
                                label,
                                style: TextStyle(
                                    fontSize: TwText.sm.size,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                ),
                            ),
                        ],
                    ),
                ),
            ),
        );
    }
}

/// A small round button, blue-filled: the calendar's arrows and the counters' plus and minus.
class RoundBlueButton extends StatelessWidget {
    const RoundBlueButton({
        required this.icon,
        required this.onPressed,
        required this.tooltip,
        super.key,
    });

    final IconData icon;
    final VoidCallback? onPressed;
    final String tooltip;

    @override
    Widget build(BuildContext context) {
        return Tooltip(
            message: tooltip,
            child: Material(
                color: onPressed == null ? const Color(0x332563EB) : TwPalette.blue600,
                shape: const CircleBorder(),
                child: InkWell(
                    onTap: onPressed,
                    customBorder: const CircleBorder(),
                    child: SizedBox(
                        width: 32,
                        height: 32,
                        child: Icon(icon, size: 18, color: Colors.white),
                    ),
                ),
            ),
        );
    }
}

/// The note under the button — what was chosen, or that a step can be skipped.
class StageNote extends StatelessWidget {
    const StageNote(this.text, {super.key});

    final String text;

    @override
    Widget build(BuildContext context) {
        return Text(
            text,
            style: TextStyle(fontSize: TwText.xs.size, color: Colors.white60),
        );
    }
}
