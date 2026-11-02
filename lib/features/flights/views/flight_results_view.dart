import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cheapest_go_mobile/shared/catalog/travel_catalog.dart';
import 'package:cheapest_go_mobile/shared/components/ui_kit.dart';
import 'package:cheapest_go_mobile/shared/stores/trip_search_store.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/app_colors.dart';
import 'package:cheapest_go_mobile/shared/utils/format.dart';

enum _Sort { cheapest, earliest }

/// One-way flights from the search origin into the arrival airport.
class FlightResultsView extends StatefulWidget {
  const FlightResultsView({this.catalog = travelCatalog, super.key});

  final TravelCatalog catalog;

  @override
  State<FlightResultsView> createState() => _FlightResultsViewState();
}

class _FlightResultsViewState extends State<FlightResultsView> {
  _Sort _sort = _Sort.cheapest;
  bool _nonStopOnly = false;
  bool _checkedBagOnly = false;

  List<FlightOffer> _results(String from, String to) {
    final list = widget.catalog.flights(from, to).where((f) {
      if (_nonStopOnly && !f.nonStop) return false;
      if (_checkedBagOnly && !f.baggage.contains('checked')) return false;
      return true;
    }).toList();
    if (_sort == _Sort.earliest) list.sort((a, b) => a.departs.compareTo(b.departs));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = tripSearchStore;
    final results = _results(s.originCode, s.airportCode);
    final cheapest = results.isEmpty ? null : results.map((f) => f.price).reduce((a, b) => a < b ? a : b);

    return Scaffold(
      appBar: AppBar(
        title: Text('${s.originCode} → ${s.airportCode}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(22),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${formatDayDate(s.checkIn)} · one way · ${plural(s.adults, 'passenger')}',
                style: TextStyle(fontSize: 13, color: c.textMuted),
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              spacing: 8,
              children: [
                FilterPill(label: 'Cheapest', selected: _sort == _Sort.cheapest, onTap: () => setState(() => _sort = _Sort.cheapest)),
                FilterPill(label: 'Earliest', selected: _sort == _Sort.earliest, onTap: () => setState(() => _sort = _Sort.earliest)),
                FilterPill(label: 'Non-stop', selected: _nonStopOnly, onTap: () => setState(() => _nonStopOnly = !_nonStopOnly)),
                FilterPill(label: 'Checked bag', selected: _checkedBagOnly, onTap: () => setState(() => _checkedBagOnly = !_checkedBagOnly)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          UiLabel('${plural(results.length, 'flight')} · prices per passenger'),
          const SizedBox(height: 10),
          if (results.isEmpty)
            EmptyState(
              icon: Icons.flight_outlined,
              title: 'No flights match',
              message: s.originCode == s.airportCode
                  ? 'Pick a departure airport different from where you land.'
                  : 'Clear a filter to see more flights.',
            ),
          for (final f in results) ...[
            _FlightCard(
              offer: f,
              cheapest: f.price == cheapest,
              onSelect: () => context.push('/flight-checkout?offer=${f.id}'),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _FlightCard extends StatelessWidget {
  const _FlightCard({required this.offer, required this.cheapest, required this.onSelect});

  final FlightOffer offer;
  final bool cheapest;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final time = Theme.of(context).textTheme.titleLarge;
    return AppCard(
      onTap: onSelect,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: c.secondary, borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.flight_rounded, size: 18, color: c.accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text('${offer.airline} · ${offer.flightNo}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              if (cheapest) const StatusPill('Cheapest'),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Endpoint(time: formatClock(offer.departs), code: offer.origin, style: time),
              Expanded(
                child: Column(
                  children: [
                    Text(offer.durationLabel, style: TextStyle(fontSize: 11, color: c.textMuted)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(child: Divider(color: c.borderStrong)),
                        Icon(Icons.flight_rounded, size: 14, color: c.accent),
                        Expanded(child: Divider(color: c.borderStrong)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      offer.stopsLabel,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: offer.nonStop ? c.success : c.warning),
                    ),
                  ],
                ),
              ),
              _Endpoint(time: formatClock(offer.arrives), code: offer.destination, style: time, end: true),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: c.hairline),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.luggage_outlined, size: 14, color: c.label),
              const SizedBox(width: 4),
              Expanded(child: Text(offer.baggage, style: TextStyle(fontSize: 12, color: c.textMuted))),
              PriceText(offer.price, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}

class _Endpoint extends StatelessWidget {
  const _Endpoint({required this.time, required this.code, required this.style, this.end = false});

  final String time;
  final String code;
  final TextStyle? style;
  final bool end;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: Column(
        crossAxisAlignment: end ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(time, style: style?.copyWith(fontSize: 17)),
          Text(code, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.colors.textMuted)),
        ],
      ),
    );
  }
}
