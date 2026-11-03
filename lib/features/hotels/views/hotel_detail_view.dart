import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cheapest_go_mobile/shared/catalog/travel_catalog.dart';
import 'package:cheapest_go_mobile/shared/components/ui_kit.dart';
import 'package:cheapest_go_mobile/shared/stores/saved_store.dart';
import 'package:cheapest_go_mobile/shared/stores/trip_search_store.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/app_colors.dart';
import 'package:cheapest_go_mobile/shared/utils/format.dart';

/// One hotel: highlights, room choice, and the stay total.
class HotelDetailView extends StatefulWidget {
  const HotelDetailView({required this.hotelId, this.catalog = travelCatalog, super.key});

  final String hotelId;
  final TravelCatalog catalog;

  @override
  State<HotelDetailView> createState() => _HotelDetailViewState();
}

class _HotelDetailViewState extends State<HotelDetailView> {
  String? _roomId;
  int _photo = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hotel = widget.catalog.hotel(widget.hotelId);
    if (hotel == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(icon: Icons.hotel_outlined, title: 'Hotel not found', message: 'It may have been removed.'),
      );
    }
    final room = hotel.rooms.firstWhere((r) => r.id == _roomId, orElse: () => hotel.rooms.first);
    final s = tripSearchStore;
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          SizedBox(
            height: 240 + topInset,
            child: Stack(
              fit: StackFit.expand,
              children: [
                PageView(
                  onPageChanged: (i) => setState(() => _photo = i),
                  children: [
                    for (final p in hotel.photos) PhotoPlaceholder(image: p, label: hotel.name, radius: 0, fade: true),
                  ],
                ),
                Positioned(
                  right: 16,
                  bottom: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0x8C020617), borderRadius: BorderRadius.circular(999)),
                    child: Text(
                      '${_photo + 1} / ${hotel.photos.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                Positioned(
                  top: topInset + 12,
                  left: 16,
                  child: CircleIconButton(
                    icon: Icons.chevron_left_rounded,
                    tooltip: 'Back',
                    onPressed: () => context.canPop() ? context.pop() : context.go('/hotels'),
                  ),
                ),
                Positioned(
                  top: topInset + 12,
                  right: 16,
                  child: ListenableBuilder(
                    listenable: savedStaysStore,
                    builder: (context, _) {
                      final saved = savedStaysStore.isSaved(hotel.id);
                      return CircleIconButton(
                        icon: saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: saved ? c.error : null,
                        tooltip: saved ? 'Remove from saved' : 'Save hotel',
                        onPressed: () => savedStaysStore.toggle(hotel.id),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hotel.name, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 6),
                PinLine('${hotel.area} · ${hotel.distanceKm.toStringAsFixed(1)} km from ${hotel.airportCode} ${hotel.distanceFrom}'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    RatingBadge(hotel.score),
                    const SizedBox(width: 8),
                    Text(hotel.scoreLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Text('${hotel.reviews} reviews', style: TextStyle(fontSize: 13, color: c.textMuted)),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in hotel.tags)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(color: c.secondary, borderRadius: BorderRadius.circular(12)),
                        child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.onSecondary)),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                UiLabel('Choose a room · ${formatDateRange(s.checkIn, s.checkOut)} · ${plural(s.nights, 'night')}'),
                const SizedBox(height: 10),
                RadioGroup<String>(
                  groupValue: room.id,
                  onChanged: (id) => setState(() => _roomId = id),
                  child: Column(
                    children: [
                      for (final r in hotel.rooms) ...[
                        _RoomTile(room: r, selected: r.id == room.id, onTap: () => setState(() => _roomId = r.id)),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(formatPeso(room.nightlyRate * s.nights), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  Text('${plural(s.nights, 'night')} · taxes at checkout', style: TextStyle(fontSize: 12, color: c.textMuted)),
                ],
              ),
            ),
            FilledButton(
              onPressed: () => context.push('/checkout?hotel=${hotel.id}&room=${room.id}'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 28)),
              child: const Text('Reserve'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomTile extends StatelessWidget {
  const _RoomTile({required this.room, required this.selected, required this.onTap});

  final Room room;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      onTap: onTap,
      color: selected ? c.secondary.withValues(alpha: 0.5) : null,
      borderColor: selected ? c.accent : null,
      borderWidth: selected ? 2 : 1,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 24, height: 24, child: Radio<String>(value: room.id)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(room.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(room.meta, style: TextStyle(fontSize: 12, color: c.textMuted)),
                const SizedBox(height: 4),
                Text(
                  room.cancellation ?? 'Non-refundable',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: room.refundable ? c.success : c.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              PriceText(room.nightlyRate),
              Text('/night', style: TextStyle(fontSize: 11, color: c.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}
