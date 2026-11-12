import 'package:flutter/material.dart';

import 'package:cheapest_go_mobile/features/hotels/components/stay_chrome.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/catalog/travel_catalog.dart';
import 'package:cheapest_go_mobile/shared/stores/saved_store.dart';
import 'package:cheapest_go_mobile/shared/utils/currency.dart';
import 'package:cheapest_go_mobile/shared/utils/money.dart';

/// One stay in the list, as V2's `HotelCard` draws it below its `md` breakpoint. See #39.
///
/// The same stay as the map's rail card and deliberately the same surfaces — V2 mirrors
/// `railCardPalette` here so a stay looks identical whichever view you found it in — but a
/// different arrangement: the picture above, then the name, where it is, its score, and the
/// price beside Book Now.
///
/// The four lines are one stack on an even rhythm. V2's note says not to distribute the free
/// space between them, which would open a gap under the rating the design does not have.
class StayListCard extends StatelessWidget {
    const StayListCard({
        required this.hotel,
        required this.currency,
        required this.onOpen,
        super.key,
    });

    final Hotel hotel;
    final String currency;
    final VoidCallback onOpen;

    @override
    Widget build(BuildContext context) {
        final t = AppLocalizations.of(context)!;
        final skin = StaySkin.of(context);
        final photo = hotel.photos.isEmpty ? null : hotel.photos.first;
        final shown = exchangeRates.convertForDisplay(hotel.fromRate, hotel.currency, currency);
        // Address then area, but only what the line does not already say: a supplier's address
        // usually ends in the city, and appending it again reads "Malate, Manila, Manila".
        final where = <String>[
            for (final part in [hotel.address, hotel.area])
                if (part != null && part.trim().isNotEmpty) part.trim(),
        ].fold<List<String>>(
            [],
            (kept, part) => kept.any((p) => p.toLowerCase().contains(part.toLowerCase()))
                ? kept
                : (kept..add(part)),
        ).join(', ');

        return Material(
            color: skin.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Stack(
                children: [
                    InkWell(
                        onTap: onOpen,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                                SizedBox(
                                    height: 190,
                                    child: ColoredBox(
                                        color: skin.imageBg,
                                        child: photo == null
                                            ? Icon(Icons.apartment_rounded, size: 30, color: skin.muted)
                                            : Image.network(
                                                photo,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, _, _) =>
                                                    Icon(Icons.apartment_rounded, size: 30, color: skin.muted),
                                            ),
                                    ),
                                ),
                                Padding(
                                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                                    child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                            Padding(
                                                // Clear of the bookmark in the corner.
                                                padding: const EdgeInsets.only(right: 56),
                                                child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                        Text(
                                                            hotel.name,
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                            style: TextStyle(
                                                                fontSize: 20,
                                                                height: 1.15,
                                                                fontWeight: FontWeight.w700,
                                                                color: skin.title,
                                                            ),
                                                        ),
                                                        const SizedBox(height: 10),
                                                        Text(
                                                            where.isEmpty ? '—' : where,
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                            style: TextStyle(fontSize: 14, color: skin.muted),
                                                        ),
                                                        const SizedBox(height: 8),
                                                        Text(
                                                            // Out of ten, and said so: V2 prints the
                                                            // scale because a 7.8 out of 5 would be a
                                                            // different stay entirely.
                                                            hotel.score > 0
                                                                ? '${hotel.score.toStringAsFixed(1)} / 10 rating'
                                                                : 'No rating yet',
                                                            style: TextStyle(fontSize: 14, color: skin.muted),
                                                        ),
                                                    ],
                                                ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                                children: [
                                                    Expanded(
                                                        child: Text(
                                                            '${formatMoney(shown.amount, shown.currency)}/ night',
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                            style: TextStyle(fontSize: 17, color: skin.muted),
                                                        ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    _Chip(label: t.hotels_bookNow, onTap: onOpen),
                                                ],
                                            ),
                                        ],
                                    ),
                                ),
                            ],
                        ),
                    ),
                    Positioned(
                        top: 20,
                        right: 24,
                        child: ListenableBuilder(
                            listenable: savedStaysStore,
                            builder: (context, _) {
                                final saved = savedStaysStore.isSaved(hotel.id);
                                return Tooltip(
                                    message: saved ? 'Remove from saved stays' : 'Save this stay',
                                    child: _ChipCircle(
                                        onTap: () => savedStaysStore.toggle(hotel.id),
                                        child: Icon(
                                            saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                            size: 16,
                                            color: Colors.white,
                                        ),
                                    ),
                                );
                            },
                        ),
                    ),
                ],
            ),
        );
    }
}

/// The brand gradient the price chip, the bookmark and Book Now all share.
const _chipGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF2563EB), Color(0xFF06B6D4)],
);

class _Chip extends StatelessWidget {
    const _Chip({required this.label, required this.onTap});

    final String label;
    final VoidCallback onTap;

    @override
    Widget build(BuildContext context) {
        return Material(
            color: Colors.transparent,
            child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(999),
                child: Ink(
                    decoration: BoxDecoration(
                        gradient: _chipGradient,
                        borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                        child: Text(
                            label,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                            ),
                        ),
                    ),
                ),
            ),
        );
    }
}

class _ChipCircle extends StatelessWidget {
    const _ChipCircle({required this.child, required this.onTap});

    final Widget child;
    final VoidCallback onTap;

    @override
    Widget build(BuildContext context) {
        return Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: Ink(
                decoration: const BoxDecoration(gradient: _chipGradient, shape: BoxShape.circle),
                child: InkWell(
                    onTap: onTap,
                    customBorder: const CircleBorder(),
                    child: SizedBox(width: 36, height: 36, child: Center(child: child)),
                ),
            ),
        );
    }
}
