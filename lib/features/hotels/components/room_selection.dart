import 'package:flutter/material.dart';

import 'package:cheapest_go_mobile/features/hotels/components/stay_chrome.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/catalog/travel_catalog.dart';
import 'package:cheapest_go_mobile/shared/utils/currency.dart';
import 'package:cheapest_go_mobile/shared/utils/money.dart';

/// The rooms, and the terms each is sold on. See #40, and ADR-0007 in the web repo.
///
/// **A card is a Room; the rows inside it are Offers.** A Room is the thing a traveller
/// sleeps in — one physical product, whatever it costs — and its Offers differ in board,
/// refundability, the cancellation deadline and the bed. Drawing one card per price instead
/// produces two cards a reader cannot tell apart, which is what happened to a Seoul property
/// on 2026-11-04 and was reported as a rendering fault.
///
/// Nothing here decides which lines are one Room or which Offers are the same promise:
/// api-v2 does that once for both products (its ADR 0005) and this draws what it sends.
class RoomSelection extends StatelessWidget {
    const RoomSelection({
        required this.rooms,
        required this.currency,
        required this.selectedOfferId,
        required this.onSelect,
        this.fallbackPhoto,
        super.key,
    });

    final List<Room> rooms;
    final String currency;

    /// The Offer a traveller has picked, which is what checkout is made against.
    final String? selectedOfferId;
    final ValueChanged<Offer> onSelect;

    /// The hotel's own photograph, shown on a room carrying none of its own. V2 passes the
    /// same thing as `galleryFallback`: a supplier that owns its content sends no room
    /// galleries at all, and an empty grey box says less than the building does.
    final String? fallbackPhoto;

    @override
    Widget build(BuildContext context) {
        final skin = StaySkin.of(context);
        final t = AppLocalizations.of(context)!;

        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Text(
                        t.property_rooms_availableRooms(rooms.length),
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: skin.title),
                    ),
                ),
                for (final room in rooms) ...[
                    _RoomCard(
                        room: room,
                        currency: currency,
                        selectedOfferId: selectedOfferId,
                        onSelect: onSelect,
                        fallbackPhoto: fallbackPhoto,
                    ),
                    const SizedBox(height: 14),
                ],
            ],
        );
    }
}

class _RoomCard extends StatelessWidget {
    const _RoomCard({
        required this.room,
        required this.currency,
        required this.selectedOfferId,
        required this.onSelect,
        required this.fallbackPhoto,
    });

    final Room room;
    final String currency;
    final String? selectedOfferId;
    final ValueChanged<Offer> onSelect;
    final String? fallbackPhoto;

    @override
    Widget build(BuildContext context) {
        final skin = StaySkin.of(context);
        final photos = room.images.isNotEmpty
            ? room.images
            : [?fallbackPhoto];
        final offers = room.buyableOffers;

        return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
                color: skin.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: skin.hairline),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                    if (photos.isNotEmpty) _RoomPhotos(photos: photos, skin: skin),
                    Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                        child: Text(
                            room.name,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: skin.title),
                        ),
                    ),
                    for (final (i, offer) in offers.indexed)
                        _OfferRow(
                            offer: offer,
                            currency: currency,
                            selected: offer.offerId == selectedOfferId,
                            first: i == 0,
                            onTap: () => onSelect(offer),
                        ),
                ],
            ),
        );
    }
}

/// One Offer: what it promises, and what it costs.
///
/// Every attribute that can differ within a Room is printed, because whichever of them varies
/// is the reason there is more than one row. Two rows reading "Room only" at different prices
/// tell the traveller there is a difference and refuse to say what it is.
class _OfferRow extends StatelessWidget {
    const _OfferRow({
        required this.offer,
        required this.currency,
        required this.selected,
        required this.first,
        required this.onTap,
    });

    final Offer offer;
    final String currency;
    final bool selected;
    final bool first;
    final VoidCallback onTap;

    @override
    Widget build(BuildContext context) {
        final skin = StaySkin.of(context);
        final shown = exchangeRates.convertForDisplay(offer.nightlyRate, offer.currency, currency);
        final t = AppLocalizations.of(context)!;

        return InkWell(
            onTap: onTap,
            child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: BoxDecoration(
                    color: selected ? const Color(0x142563EB) : null,
                    border: Border(top: BorderSide(color: first ? Colors.transparent : skin.hairline)),
                ),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Icon(
                            selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                            size: 20,
                            color: selected ? const Color(0xFF2563EB) : skin.muted,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Text(
                                        offer.boardName,
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: skin.title,
                                        ),
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: [
                                            _Chip(
                                                label: offer.refundable
                                                    ? t.property_rooms_freeCancellation
                                                    : t.property_rooms_filterNonRefundable,
                                                good: offer.refundable,
                                                skin: skin,
                                            ),
                                            if (offer.bed != null) _Chip(label: offer.bed!, skin: skin),
                                            for (final term in offer.terms) _Chip(label: term, skin: skin),
                                        ],
                                    ),
                                    if (offer.refundable && offer.cancellationDeadline != null) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                            // The date the promise expires, which is the
                                            // difference between two otherwise equal Offers.
                                            'Free until ${_day(offer.cancellationDeadline!)}',
                                            style: TextStyle(fontSize: 11.5, color: skin.muted),
                                        ),
                                    ],
                                ],
                            ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                                Text(
                                    formatMoney(shown.amount, shown.currency),
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: skin.title,
                                    ),
                                ),
                                Text(
                                    t.property_rooms_perNight,
                                    style: TextStyle(fontSize: 11, color: skin.muted),
                                ),
                            ],
                        ),
                    ],
                ),
            ),
        );
    }

    static String _day(DateTime at) {
        const months = [
            'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
        ];
        final local = at.toLocal();
        return '${months[local.month - 1]} ${local.day}';
    }
}

class _Chip extends StatelessWidget {
    const _Chip({required this.label, required this.skin, this.good = false});

    final String label;
    final StaySkin skin;

    /// Free cancellation reads as the good news it is; everything else is neutral.
    final bool good;

    @override
    Widget build(BuildContext context) {
        return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: good ? const Color(0x1F2FB67F) : skin.imageBg,
                borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
                label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: good ? const Color(0xFF2FB67F) : skin.muted,
                ),
            ),
        );
    }
}

/// A room's photographs: swipeable in the card, full-screen on a tap.
///
/// V2 opens its room photos in a dialog with a thumbnail strip and a lightbox. On a phone the
/// card itself is the strip — a swipe is the gesture already in the thumb — and a tap opens the
/// same pictures full width.
class _RoomPhotos extends StatefulWidget {
    const _RoomPhotos({required this.photos, required this.skin});

    final List<String> photos;
    final StaySkin skin;

    @override
    State<_RoomPhotos> createState() => _RoomPhotosState();
}

class _RoomPhotosState extends State<_RoomPhotos> {
    final _pages = PageController();
    int _at = 0;

    @override
    void dispose() {
        _pages.dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        final t = AppLocalizations.of(context)!;

        return SizedBox(
            height: 160,
            child: Stack(
                fit: StackFit.expand,
                children: [
                    PageView.builder(
                        controller: _pages,
                        itemCount: widget.photos.length,
                        onPageChanged: (i) => setState(() => _at = i),
                        itemBuilder: (context, i) => GestureDetector(
                            onTap: () => _openGallery(context, i),
                            child: Image.network(
                                widget.photos[i],
                                fit: BoxFit.cover,
                                // A photograph that will not load leaves the building's glyph, as V2
                                // does — an empty grey panel reads as a broken card.
                                errorBuilder: (_, _, _) => ColoredBox(
                                    color: widget.skin.imageBg,
                                    child: Icon(Icons.apartment_rounded, size: 26, color: widget.skin.muted),
                                ),
                            ),
                        ),
                    ),
                    if (widget.photos.length > 1)
                        Positioned(
                            right: 10,
                            bottom: 10,
                            child: Semantics(
                                label: t.property_rooms_viewRoomPhotos,
                                child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: const Color(0x99000000),
                                        borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                        '${_at + 1}/${widget.photos.length}',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                        ),
                                    ),
                                ),
                            ),
                        ),
                ],
            ),
        );
    }

    void _openGallery(BuildContext context, int start) {
        Navigator.of(context).push(
            MaterialPageRoute<void>(
                fullscreenDialog: true,
                builder: (context) => _RoomGallery(photos: widget.photos, start: start),
            ),
        );
    }
}

/// The room's pictures, one at a time, over black — the lightbox V2 opens from its strip.
class _RoomGallery extends StatelessWidget {
    const _RoomGallery({required this.photos, required this.start});

    final List<String> photos;
    final int start;

    @override
    Widget build(BuildContext context) {
        final t = AppLocalizations.of(context)!;

        return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                title: Text(t.property_rooms_viewRoomPhotos, style: const TextStyle(fontSize: 15)),
            ),
            body: PageView.builder(
                controller: PageController(initialPage: start),
                itemCount: photos.length,
                itemBuilder: (context, i) => InteractiveViewer(
                    child: Center(
                        child: Image.network(
                            photos[i],
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Icon(Icons.image_not_supported_rounded, color: Colors.white24),
                        ),
                    ),
                ),
            ),
        );
    }
}
