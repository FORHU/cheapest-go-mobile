import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/components/ui_kit.dart';
import 'package:cheapest_go_mobile/shared/saved/device_saves_notice.dart';
import 'package:cheapest_go_mobile/shared/saved/saved_trip.dart';
import 'package:cheapest_go_mobile/shared/saved/saved_trips_store.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/app_colors.dart';
import 'package:cheapest_go_mobile/shared/utils/money.dart';

/// The shortlist, in Account. See #43.
///
/// **Drawn from the rows themselves**, which carry the name, the price and the picture. It
/// used to resolve each saved id through the catalogue, and `ApiTravelCatalog.hotel` reads a
/// cache that searches fill — so after a fresh launch it resolved nothing and this list
/// silently rendered empty. See ADR-0004.
class SavedStaysCard extends StatefulWidget {
    const SavedStaysCard({super.key});

    @override
    State<SavedStaysCard> createState() => _SavedStaysCardState();
}

class _SavedStaysCardState extends State<SavedStaysCard> {
    /// Stays saved on this device under the old scheme, counted once so the loss can be
    /// stated rather than discovered. See `device_saves_notice.dart`.
    int _strandedOnDevice = 0;

    @override
    void initState() {
        super.initState();
        if (!savedTripsStore.loaded) savedTripsStore.refresh();
        deviceSavesNotice.pending().then((count) {
            if (mounted && count > 0) setState(() => _strandedOnDevice = count);
        });
    }

    void _dismissNotice() {
        deviceSavesNotice.acknowledge();
        setState(() => _strandedOnDevice = 0);
    }

    @override
    Widget build(BuildContext context) {
        final t = AppLocalizations.of(context)!;

        return ListenableBuilder(
            listenable: savedTripsStore,
            builder: (context, _) {
                final trips = savedTripsStore.trips;

                return Column(
                    children: [
                        if (_strandedOnDevice > 0) ...[
                            _DeviceSavesNotice(count: _strandedOnDevice, onDismiss: _dismissNotice),
                            const SizedBox(height: 10),
                        ],
                        if (trips.isEmpty)
                            _Empty(hint: t.account_savedTrips_hint)
                        else
                            for (final trip in trips)
                                Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _SavedRow(
                                        trip: trip,
                                        removeLabel: t.account_savedTrips_remove,
                                    ),
                                ),
                    ],
                );
            },
        );
    }
}

/// Said once, to somebody who had stays saved before they were kept with the account.
class _DeviceSavesNotice extends StatelessWidget {
    const _DeviceSavesNotice({required this.count, required this.onDismiss});

    final int count;
    final VoidCallback onDismiss;

    @override
    Widget build(BuildContext context) {
        final c = context.colors;
        return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: c.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Text(
                        count == 1
                            ? 'One stay was saved on this device'
                            : '$count stays were saved on this device',
                        style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: c.textPrimary,
                        ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                        'Saved stays now live with your account, so they follow you to the web '
                        'and to a new phone. These older ones stayed here and need saving '
                        'again.',
                        style: TextStyle(fontSize: 12.5, height: 1.45, color: c.textMuted),
                    ),
                    const SizedBox(height: 8),
                    Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(onPressed: onDismiss, child: Text(AppLocalizations.of(context)!.tip_done)),
                    ),
                ],
            ),
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
    const _SavedRow({required this.trip, required this.removeLabel});

    final SavedTrip trip;
    final String removeLabel;

    @override
    Widget build(BuildContext context) {
        final c = context.colors;
        final route = trip.route;

        return AppCard(
            padding: const EdgeInsets.all(10),
            onTap: route == null ? null : () => context.push(route),
            child: Row(
                children: [
                    PhotoPlaceholder(
                        image: trip.imageUrl ?? '',
                        label: trip.title,
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
                                    trip.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                ),
                                if (trip.subtitle != null) ...[
                                    const SizedBox(height: 3),
                                    PinLine(trip.subtitle!),
                                ],
                                if (trip.price != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                        // The price as it was when this was saved — a rate
                                        // lapses, and this is a shortlist, not a quote.
                                        '${formatMoney(trip.price!, trip.currency)} ${AppLocalizations.of(context)!.hotels_perNight}',
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: c.accent,
                                        ),
                                    ),
                                ],
                            ],
                        ),
                    ),
                    _RemoveButton(trip: trip, label: removeLabel),
                ],
            ),
        );
    }
}

class _RemoveButton extends StatelessWidget {
    const _RemoveButton({required this.trip, required this.label});

    final SavedTrip trip;
    final String label;

    @override
    Widget build(BuildContext context) {
        final c = context.colors;
        final hotelId = trip.hotelId;
        final busy = hotelId != null && savedTripsStore.isBusy(hotelId);

        return IconButton(
            tooltip: label,
            onPressed: busy || hotelId == null
                ? null
                : () => savedTripsStore.toggleHotel(hotelId: hotelId, title: trip.title),
            icon: busy
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: c.textMuted),
                )
                : Icon(Icons.favorite_rounded, color: c.error),
        );
    }
}
