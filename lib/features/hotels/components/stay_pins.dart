import 'package:flutter/material.dart';

import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';

/// The markers on the search map, as V2 draws them. See `ClusterPin.tsx` and `HotelPin.tsx`.
///
/// A cluster is a hotel marker that happens to stand for more than one, so the two share a
/// shape: the same pill, radius and shadow, with the thumbnail replaced by a count. They are
/// meant to read as one kind of object on the map, not two.

/// Blue to cyan, the brand gradient — the same pair the landing's buttons use.
const _pinGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF2563EB), Color(0xFF06B6D4)],
);

const double _thumb = 34;

class _PinSkin {
    const _PinSkin({required this.bg, required this.fg, required this.line});

    final Color bg;
    final Color fg;
    final Color line;

    static _PinSkin of(BuildContext context) =>
        Theme.of(context).brightness == Brightness.dark
            ? const _PinSkin(bg: Color(0xFF1A1A1A), fg: Color(0xFFF8FAFC), line: Color(0x1FFFFFFF))
            : const _PinSkin(bg: Color(0xFFFFFFFF), fg: Color(0xFF0F172A), line: Color(0x14000000));
}

/// Several stays too close together to draw apart at this zoom.
///
/// While availability is still coming back the pin says it is checking rather than naming a
/// price: a search paints what is in the catalog first and learns what can be booked second,
/// and "89 hotels" that resolves to two is the map having promised what the search had not
/// yet found out.
class ClusterPin extends StatelessWidget {
    const ClusterPin({
        required this.count,
        required this.priceLabel,
        this.active = false,
        super.key,
    });

    final int count;

    /// Cheapest of them, already formatted. Empty while the prices are still being checked.
    final String priceLabel;
    final bool active;

    @override
    Widget build(BuildContext context) {
        final t = AppLocalizations.of(context)!;
        final skin = _PinSkin.of(context);
        final checking = priceLabel.isEmpty;

        return _PinShell(
            active: active,
            skin: skin,
            leading: Container(
                width: _thumb,
                height: _thumb,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    gradient: _pinGradient,
                    shape: BoxShape.circle,
                    border: Border.all(color: skin.line),
                ),
                child: Text(
                    count > 999 ? '999+' : '$count',
                    style: TextStyle(
                        // Three digits fit by shrinking the type rather than by growing the
                        // pin, which would shift every marker beside it.
                        fontSize: count > 99 ? 11 : count > 9 ? 13 : 15,
                        height: 1,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                    ),
                ),
            ),
            lines: [
                Opacity(
                    opacity: 0.62,
                    child: Text(
                        checking ? t.search_v2_clusterChecking(count) : t.search_v2_clusterHotels(count),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: skin.fg),
                    ),
                ),
                if (!checking)
                    Text(
                        t.search_v2_clusterFrom(priceLabel),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: skin.fg),
                    ),
            ],
        );
    }
}

/// One stay: its picture and its nightly rate.
class HotelPin extends StatelessWidget {
    const HotelPin({
        required this.name,
        required this.priceLabel,
        this.photo,
        this.active = false,
        super.key,
    });

    final String name;
    final String priceLabel;
    final String? photo;
    final bool active;

    @override
    Widget build(BuildContext context) {
        final skin = _PinSkin.of(context);

        return _PinShell(
            active: active,
            skin: skin,
            leading: ClipOval(
                child: SizedBox(
                    width: _thumb,
                    height: _thumb,
                    child: photo == null
                        ? DecoratedBox(
                            decoration: const BoxDecoration(gradient: _pinGradient),
                            child: const Icon(Icons.apartment_rounded, size: 16, color: Colors.white),
                        )
                        : Image.network(
                            photo!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => DecoratedBox(
                                decoration: const BoxDecoration(gradient: _pinGradient),
                                child: const Icon(Icons.apartment_rounded, size: 16, color: Colors.white),
                            ),
                        ),
                ),
            ),
            lines: [
                Text(
                    priceLabel,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: skin.fg),
                ),
            ],
        );
    }
}

/// The pill both pins are drawn in, so a cluster and a stay are the same object at two
/// readings rather than two kinds of marker.
class _PinShell extends StatelessWidget {
    const _PinShell({required this.leading, required this.lines, required this.active, required this.skin});

    final Widget leading;
    final List<Widget> lines;
    final bool active;
    final _PinSkin skin;

    @override
    Widget build(BuildContext context) {
        return AnimatedScale(
            scale: active ? 1.15 : 1,
            alignment: Alignment.bottomCenter,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            child: Container(
                padding: const EdgeInsets.fromLTRB(4, 4, 14, 4),
                decoration: BoxDecoration(
                    color: skin.bg,
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                        BoxShadow(
                            color: active ? const Color(0x57000000) : const Color(0x38000000),
                            blurRadius: active ? 18 : 9,
                            offset: Offset(0, active ? 6 : 2),
                        ),
                    ],
                ),
                child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        leading,
                        const SizedBox(width: 8),
                        Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: lines,
                        ),
                    ],
                ),
            ),
        );
    }
}
