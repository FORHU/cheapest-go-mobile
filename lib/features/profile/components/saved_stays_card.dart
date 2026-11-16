import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:cheapest_go_mobile/shared/catalog/travel_catalog.dart';
import 'package:cheapest_go_mobile/shared/components/ui_kit.dart';
import 'package:cheapest_go_mobile/shared/stores/saved_store.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/app_colors.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';

/// The stays marked with a heart, in Account. See #42.
///
/// Moved here from the Trips screen, where it was a third tab: V2 keeps Saved Trips under
/// Account, and My Bookings lists only what has actually been booked. The two answer
/// different questions and a shortlist among reservations reads as one.
///
/// Still held on the device. The real **Saved Trip** lives against the account on the server
/// and shows up on the web too (CONTEXT.md); wiring `/saved-trips` is its own ticket.
class SavedStaysCard extends StatelessWidget {
    const SavedStaysCard({this.catalog = travelCatalog, super.key});

    final TravelCatalog catalog;

    @override
    Widget build(BuildContext context) {
        final t = AppLocalizations.of(context)!;

        return ListenableBuilder(
            listenable: savedStaysStore,
            builder: (context, _) {
                final hotels = [
                    for (final id in savedStaysStore.ids) ?catalog.hotel(id),
                ];

                if (hotels.isEmpty) {
                    return _Empty(hint: t.account_savedTrips_hint);
                }

                return Column(
                    children: [
                        for (final h in hotels)
                            Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _SavedRow(hotel: h, removeLabel: t.account_savedTrips_remove),
                            ),
                    ],
                );
            },
        );
    }
}

class _Empty extends StatelessWidget {
    const _Empty({required this.hint});

    final String hint;

    @override
    Widget build(BuildContext context) {
        final c = context.colors;
        return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: c.surface,
                border: Border.all(color: c.border),
                borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
                children: [
                    Icon(Icons.favorite_border_rounded, size: 18, color: c.textMuted),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(hint, style: TextStyle(fontSize: 13, color: c.textMuted)),
                    ),
                ],
            ),
        );
    }
}

class _SavedRow extends StatelessWidget {
    const _SavedRow({required this.hotel, required this.removeLabel});

    final Hotel hotel;
    final String removeLabel;

    @override
    Widget build(BuildContext context) {
        final c = context.colors;
        return AppCard(
            padding: const EdgeInsets.all(10),
            onTap: () => context.push('/hotel/${hotel.id}'),
            child: Row(
                children: [
                    PhotoPlaceholder(
                        image: hotel.cover,
                        label: hotel.name,
                        width: 64,
                        height: 64,
                        radius: 10,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text(
                                    hotel.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 3),
                                PinLine('${hotel.airportCode} · ${hotel.distanceLabel}'),
                                const SizedBox(height: 4),
                                PriceText(hotel.fromRate, suffix: '/night', size: 14),
                            ],
                        ),
                    ),
                    IconButton(
                        tooltip: removeLabel,
                        onPressed: () => savedStaysStore.toggle(hotel.id),
                        icon: Icon(Icons.favorite_rounded, color: c.error),
                    ),
                ],
            ),
        );
    }
}
