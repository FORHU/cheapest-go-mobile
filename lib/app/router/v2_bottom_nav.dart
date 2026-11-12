import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:cheapest_go_mobile/shared/theme/tokens/chrome_skin.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/generated/tw_scale.dart';

/// V2's bottom bar, as it appears on a phone. See #36 and `CONTEXT.md` (**Design Parity**).
///
/// Three slots, icons only: Home, Trips, and a gear that opens the account surface as a sheet
/// rather than navigating anywhere. The glyphs are lucide at the size and stroke V2 draws them,
/// which is why this app carries the lucide package at all — Material has no 1.5-stroke
/// outline style, and mixing weights reads as an oversight rather than a choice.
///
/// What this replaced: four labelled tabs plus a centre globe into the native map. V2 has no
/// map, so the globe has no counterpart to inherit and `lib/features/map` is now unreachable
/// but kept — see ADR-0001 before deleting it.
class V2BottomNav extends StatelessWidget {
    const V2BottomNav({
        required this.activeIndex,
        required this.onHome,
        required this.onTrips,
        required this.onSettings,
        this.settingsOpen = false,
        super.key,
    });

    /// 0 Home, 1 Trips, 2 the settings sheet.
    final int activeIndex;
    final VoidCallback onHome;
    final VoidCallback onTrips;
    final VoidCallback onSettings;
    final bool settingsOpen;

    /// 68 logical pixels, above the home indicator. V2 states it in pixels, not in spacing
    /// steps, so it is written here the same way rather than dressed up as `TwSpace.of(17)`.
    static const barHeight = 68.0;

    @override
    Widget build(BuildContext context) {
        final skin = Theme.of(context).brightness == Brightness.dark
            ? ChromeSkin.dark
            : ChromeSkin.light;

        final slots = <_Slot>[
            _Slot(icon: LucideIcons.house, label: 'Home', onTap: onHome),
            _Slot(icon: LucideIcons.list, label: 'Trips', onTap: onTrips),
            _Slot(icon: LucideIcons.settings2, label: 'Settings', onTap: onSettings, expanded: settingsOpen),
        ];

        return Container(
            decoration: BoxDecoration(
                color: skin.bar,
                // Top and shoulders only: the bar is docked, so it has no bottom edge to draw.
                border: Border(
                    top: BorderSide(color: skin.border),
                    left: BorderSide(color: skin.border),
                    right: BorderSide(color: skin.border),
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                    // Upward only, matching V2's dockShadow.
                    BoxShadow(color: skin.dockShadow, blurRadius: 30, offset: const Offset(0, -10)),
                ],
            ),
            // The bar's own colour runs down under the home indicator.
            padding: EdgeInsets.only(bottom: MediaQuery.viewPaddingOf(context).bottom),
            child: SafeArea(
                top: false,
                bottom: false,
                child: SizedBox(
                    height: barHeight,
                    child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: TwSpace.of(2)),
                        child: Row(
                            children: [
                                for (var i = 0; i < slots.length; i++) ...[
                                    if (i > 0)
                                        // A hairline between slots, not a full-height rule.
                                        Container(width: 1, height: TwSpace.of(4), color: skin.divider),
                                    Expanded(
                                        child: _NavSlot(
                                            slot: slots[i],
                                            active: i == activeIndex,
                                            skin: skin,
                                        ),
                                    ),
                                ],
                            ],
                        ),
                    ),
                ),
            ),
        );
    }
}

class _Slot {
    const _Slot({
        required this.icon,
        required this.label,
        required this.onTap,
        this.expanded,
    });

    final IconData icon;

    /// Not drawn. V2 shows icons only and puts the name on the slot for screen readers; the
    /// same reasoning applies here, where it becomes the semantics label.
    final String label;
    final VoidCallback onTap;

    /// Set only on the settings slot, which toggles a sheet rather than going anywhere.
    final bool? expanded;
}

class _NavSlot extends StatefulWidget {
    const _NavSlot({required this.slot, required this.active, required this.skin});

    final _Slot slot;
    final bool active;
    final ChromeSkin skin;

    @override
    State<_NavSlot> createState() => _NavSlotState();
}

class _NavSlotState extends State<_NavSlot> {
    bool _pressed = false;

    @override
    Widget build(BuildContext context) {
        // V2 shrinks the glyph to 90% while held, and leaves it alone for anyone who has asked
        // for less motion. Flutter exposes that as disableAnimations.
        final reduceMotion = MediaQuery.disableAnimationsOf(context);
        final scale = _pressed && !reduceMotion ? 0.9 : 1.0;

        return Semantics(
            button: true,
            selected: widget.active,
            expanded: widget.slot.expanded,
            label: widget.slot.label,
            child: InkWell(
                onTap: widget.slot.onTap,
                onHighlightChanged: (v) => setState(() => _pressed = v),
                borderRadius: BorderRadius.circular(TwRadius.n2xl),
                // The tap target is the whole third, not the glyph inside it.
                child: SizedBox.expand(
                    child: Center(
                        child: AnimatedScale(
                            scale: scale,
                            duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
                            child: Icon(
                                widget.slot.icon,
                                size: 22,
                                // Inactive slots stay at full strength rather than dimming;
                                // only the active one changes colour.
                                color: widget.active ? widget.skin.active : widget.skin.icon,
                            ),
                        ),
                    ),
                ),
            ),
        );
    }
}
