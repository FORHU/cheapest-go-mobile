import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cheapest_go_mobile/features/flights/contracts/flights_contract.dart';
import 'package:cheapest_go_mobile/features/flights/stores/flights_store.dart';
import 'package:cheapest_go_mobile/shared/components/skeleton.dart';
import 'package:cheapest_go_mobile/shared/stores/ui_store.dart';
import 'package:cheapest_go_mobile/shared/utils/currency.dart';

class FlightsView extends StatefulWidget {
  const FlightsView({super.key});

  @override
  State<FlightsView> createState() => _FlightsViewState();
}

class _FlightsViewState extends State<FlightsView> {
  String _activeTab = 'search'; // 'search' | 'lounges' | 'tracker'
  String _tripType = 'round'; // 'round' | 'oneway' | 'multi'

  String _origCode = 'JFK';
  String _origCity = 'New York (John F. Kennedy)';
  String _destCode = 'LHR';
  String _destCity = 'London Heathrow Terminal 3';

  final String _departDate = 'Thu, Oct 29';
  final String _returnDate = 'Fri, Nov 06';
  bool _isTrackingPrice = false;

  void _swapRoute() {
    setState(() {
      final tempCode = _origCode;
      final tempCity = _origCity;
      _origCode = _destCode;
      _origCity = _destCity;
      _destCode = tempCode;
      _destCity = tempCity;
    });
  }

  void _setPair(String c1, String n1, String c2, String n2) {
    setState(() {
      _origCode = c1;
      _origCity = n1;
      _destCode = c2;
      _destCity = n2;
    });
    _runSearch();
  }

  Future<void> _runSearch() async {
    await flightsStore.search(
      FlightSearchParams(
        origin: _origCode,
        destination: _destCode,
        departureDate: '2026-10-29',
        returnDate: _tripType == 'round' ? '2026-11-06' : null,
        tripType: _tripType == 'round' ? 'round-trip' : 'one-way',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayCcy = uiSettingsStore.displayCurrency;

    return ListenableBuilder(
      listenable: Listenable.merge([flightsStore, uiSettingsStore]),
      builder: (context, _) {
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            // ── Top Segmented Switcher Hub ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAEDFF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    _buildHubTab('search', 'Flight Search', Icons.flight_takeoff),
                    _buildHubTab('lounges', 'Lounges & Hub', Icons.chair_outlined),
                    _buildHubTab('tracker', 'Tracker', Icons.radar),
                  ],
                ),
              ),
            ),

            if (_activeTab == 'search') ...[
              // ── Search Panel Container ───────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0F0F172A),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Sub Segment: Trip Type & Passengers
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        runSpacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAEDFF),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildTripTypeButton('round', 'Roundtrip'),
                                _buildTripTypeButton('oneway', 'One Way'),
                                _buildTripTypeButton('multi', 'Multi-City'),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F3FF),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.person,
                                  size: 14,
                                  color: Color(0xFF004AC6),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '1 Adult, Econ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF131B2E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Origin & Destination Interchange Block
                      Stack(
                        children: [
                          Column(
                            children: [
                              _buildAirportRow(
                                label: 'DEPARTURE AIRPORT',
                                code: _origCode,
                                city: _origCity,
                                icon: Icons.flight_takeoff,
                              ),
                              const SizedBox(height: 8),
                              _buildAirportRow(
                                label: 'DESTINATION AIRPORT',
                                code: _destCode,
                                city: _destCity,
                                icon: Icons.flight_land,
                              ),
                            ],
                          ),
                          // Central Swap Button
                          Positioned(
                            right: 16,
                            top: 48,
                            child: GestureDetector(
                              onTap: _swapRoute,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2563EB),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0x332563EB),
                                      blurRadius: 8,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.swap_vert,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Dates Row
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'DEPART DATE',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today,
                                        size: 15,
                                        color: Color(0xFF004AC6),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _departDate,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF131B2E),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'RETURN DATE',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.event_repeat,
                                        size: 15,
                                        color: Color(0xFF004AC6),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _returnDate,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF131B2E),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Quick Preset Airport Pairs
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildAirportPairChip('JFK', 'New York', 'LHR', 'London'),
                            _buildAirportPairChip('MNL', 'Manila', 'SIN', 'Singapore'),
                            _buildAirportPairChip('BKK', 'Bangkok', 'HND', 'Tokyo'),
                            _buildAirportPairChip('DXB', 'Dubai', 'CDG', 'Paris'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Search CTA
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF004AC6),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _runSearch,
                        icon: const Icon(Icons.search, size: 20),
                        label: const Text(
                          'Find Flights',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Live Flight Price Radar & Fare Forecast Widget ───────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF004AC6), Color(0xFF2563EB)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F2563EB),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.insights,
                                  size: 18,
                                  color: Color(0xFF6FFBBE),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'SMART FARE FORECAST',
                                    style: TextStyle(
                                      color: Color(0xFFDBE1FF),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    'Cheapest time to book: Now',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6FFBBE),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              '94% Confidence',
                              style: TextStyle(
                                color: Color(0xFF002113),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.trending_up,
                                  size: 18,
                                  color: Color(0xFFF59E0B),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Expected to increase by +\$45 in 2 days',
                                  style: TextStyle(
                                    color: Color(0xFFDBE1FF),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isTrackingPrice = !_isTrackingPrice;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _isTrackingPrice
                                      ? const Color(0xFF6FFBBE)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  _isTrackingPrice ? 'Tracking ✓' : 'Track Price',
                                  style: TextStyle(
                                    color: _isTrackingPrice
                                        ? const Color(0xFF002113)
                                        : const Color(0xFF004AC6),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Filter Chips ─────────────────────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _buildFilterPill('Cheapest first', Icons.arrow_downward, isSelected: true),
                    _buildFilterPill('Non-stop only', Icons.bolt),
                    _buildFilterPill('Airlines', Icons.expand_more),
                    _buildFilterPill('Departure time', Icons.schedule),
                    _buildFilterPill('Baggage included', Icons.luggage),
                  ],
                ),
              ),

              // ── Recommended Flights Feed ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recommended Flights',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF131B2E),
                      ),
                    ),
                    Text(
                      flightsStore.offers.isNotEmpty
                          ? 'Showing ${flightsStore.offers.length} fares'
                          : 'Showing 14 fares',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              if (flightsStore.isLoading)
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: 3,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, _) => const Skeleton(height: 140),
                )
              else if (flightsStore.offers.isNotEmpty)
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: flightsStore.offers.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final o = flightsStore.offers[index];
                    final firstSeg = o.segments.isNotEmpty ? o.segments.first : null;
                    return _buildFlightCard(
                      ribbonText: 'Cheapest Direct Route • Duffel Verified',
                      airlineName: firstSeg != null && firstSeg.airlineName.isNotEmpty ? firstSeg.airlineName : 'Duffel Airways',
                      flightCode: firstSeg != null && firstSeg.flightNumber.isNotEmpty ? firstSeg.flightNumber : 'VS 401',
                      depTime: firstSeg != null && firstSeg.departureTime.isNotEmpty ? firstSeg.departureTime : '19:30',
                      depCode: firstSeg != null && firstSeg.origin.isNotEmpty ? firstSeg.origin : _origCode,
                      depAirport: 'Terminal 4',
                      arrTime: firstSeg != null && firstSeg.arrivalTime.isNotEmpty ? firstSeg.arrivalTime : '07:45',
                      arrCode: firstSeg != null && firstSeg.destination.isNotEmpty ? firstSeg.destination : _destCode,
                      arrAirport: '+1 Day • T3',
                      durationText: o.totalDuration > 0 ? '${o.totalDuration ~/ 60}h ${o.totalDuration % 60}m' : '7h 15m',
                      stopLabel: o.totalStops == 0 ? 'Non-stop' : '${o.totalStops} stop',
                      baggageLabel: '1 Checked (23kg)',
                      price: o.price.total,
                      strikePrice: o.price.total * 1.22,
                      currency: o.price.currency,
                      onSelect: () {
                        flightsStore.selectOffer(o);
                        context.push('/flight-checkout');
                      },
                    );
                  },
                )
              else
                // Curated mockup showcases
                Column(
                  children: [
                    _buildFlightCard(
                      ribbonText: 'Cheapest Direct Route • Duffel Verified',
                      airlineName: 'Virgin Atlantic',
                      flightCode: 'Operated by Duffel Airways • VS 401',
                      depTime: '19:30',
                      depCode: 'JFK',
                      depAirport: 'Terminal 4',
                      arrTime: '07:45',
                      arrCode: 'LHR',
                      arrAirport: '+1 Day • T3',
                      durationText: '7h 15m',
                      stopLabel: 'Non-stop',
                      baggageLabel: '1 Checked (23kg)',
                      price: 319,
                      strikePrice: 389,
                      currency: displayCcy,
                      onSelect: () => context.push('/flight-checkout'),
                    ),
                    const SizedBox(height: 12),
                    _buildFlightCard(
                      airlineName: 'British Airways',
                      flightCode: 'BA 178 • Boeing 777-300ER',
                      depTime: '08:15',
                      depCode: 'JFK',
                      depAirport: 'Terminal 8',
                      arrTime: '20:55',
                      arrCode: 'LHR',
                      arrAirport: 'Terminal 5',
                      durationText: '9h 40m',
                      stopLabel: '1 stop (BOS 1h 15m)',
                      baggageLabel: 'Cabin Bag Included',
                      price: 345,
                      currency: displayCcy,
                      onSelect: () => context.push('/flight-checkout'),
                    ),
                    const SizedBox(height: 12),
                    _buildFlightCard(
                      airlineName: 'Cathay Pacific',
                      flightCode: 'Codeshare with American • CX 888',
                      depTime: '22:00',
                      depCode: 'JFK',
                      depAirport: 'Terminal 7',
                      arrTime: '10:20',
                      arrCode: 'LHR',
                      arrAirport: '+1 Day • T3',
                      durationText: '7h 20m',
                      stopLabel: 'Non-stop (Red-eye)',
                      baggageLabel: 'Free Wi-Fi',
                      price: 362,
                      currency: displayCcy,
                      onSelect: () => context.push('/flight-checkout'),
                    ),
                  ],
                ),

              // ── Destination Inspiration Banner (London Spotlight) ────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: const DecorationImage(
                      image: NetworkImage(
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuBWcVPQ1nc2OLP0zjHpaZjwHUtKdJzdATK9uy49aNheIjwoahwsBR11IRp7ELyAvtwxkxzzRU9xYfEA_Qyt5IRlmH0CFvEGbiGMdlI4HuDgPYsV2uhyMa01uImskJr-xpiSLLo1ELKAHgTttP4KXVEI5oCxCpw1FJ-rRC50twOb7S9GTQm-Xq97rA-pz6lp9-iDSXiiaQ0rSGQ2M75vGP2HIHQgCFEJo9HvOWvJj70',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Colors.transparent, Color(0xDD283044)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CITY SPOTLIGHT',
                          style: TextStyle(
                            color: Color(0xFFA2EEFF),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'London: History, Culture & Iconic Landmarks',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Save up to 25% when bundling flights with Heathrow Express passes',
                          style: TextStyle(
                            color: Color(0xFFE2E7FF),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Airport Services Hub Section ──────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Airport Services',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF131B2E),
                              ),
                            ),
                            Text(
                              'Breeze through JFK & LHR terminals',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'View all',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF004AC6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildServiceCard(
                          icon: Icons.local_bar,
                          iconBg: const Color(0xFFE0F7FA),
                          iconColor: const Color(0xFF006877),
                          title: 'Executive Lounge',
                          desc: 'Buffet, shower pods & ultra-fast Wi-Fi.',
                          priceText: '\$38/day',
                          btnText: 'Book',
                        ),
                        _buildServiceCard(
                          icon: Icons.speed,
                          iconBg: const Color(0xFFEAEDFF),
                          iconColor: const Color(0xFF004AC6),
                          title: 'Fast-Track Pass',
                          desc: 'Skip normal security queues at JFK T4 & T8.',
                          priceText: '\$14/pass',
                          btnText: 'Book',
                        ),
                        _buildServiceCard(
                          icon: Icons.map,
                          iconBg: const Color(0xFFE8F5E9),
                          iconColor: const Color(0xFF006242),
                          title: 'Terminal Map',
                          desc: 'Indoor gate-to-gate turn-by-turn routing.',
                          priceText: 'Live GPS',
                          btnText: 'Open',
                          onTap: () => setState(() => _activeTab = 'lounges'),
                        ),
                        _buildServiceCard(
                          icon: Icons.local_parking,
                          iconBg: const Color(0xFFF1F5F9),
                          iconColor: const Color(0xFF131B2E),
                          title: 'Airport Parking',
                          desc: 'Guaranteed covered bay near departure drop.',
                          priceText: '\$22/day',
                          btnText: 'Reserve',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else if (_activeTab == 'lounges') ...[
              // ── Lounges Panel ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0F0F172A),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'JFK Terminal 4 Directory',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF131B2E),
                                ),
                              ),
                              Text(
                                'Switch Terminal',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF004AC6),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: 140,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: const Color(0xFF131B2E),
                              image: const DecorationImage(
                                image: NetworkImage(
                                  'https://lh3.googleusercontent.com/aida-public/AB6AXuAWiLoTME_RT0b4ZTM88aBSp8SpYeUHPFF66Sdb_1zYbLi7X7tHgnNxUTTVW7-8FYfBqc_UIlcbk5eUPdRmHN2sT1uMqI59tkegWOorzvBD6Lq4yZZkvP57liVn428C1eSZ6l2Rs8YBPneEmZA5LiDw06HCsX5Im52vq2S382-URwFvg_YC3icLDuKI-nLga54GWdDQZvdrTIsudiw1rHQRMe4Lj_LuyWMCa6f-rTY',
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                            alignment: Alignment.bottomLeft,
                            padding: const EdgeInsets.all(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xCC283044),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.near_me,
                                    size: 14,
                                    color: Color(0xFFA2EEFF),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Near Gate B24 • 4 min walk to Lounge',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Row(
                            children: [
                              _LoungeStat(title: '12m', subtitle: 'Security Wait'),
                              SizedBox(width: 8),
                              _LoungeStat(
                                title: 'On Time',
                                subtitle: 'Departures',
                                isGreen: true,
                              ),
                              SizedBox(width: 8),
                              _LoungeStat(
                                title: '4 Lounges',
                                subtitle: 'Available',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // ── Tracker Panel ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0F0F172A),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Track Any Flight in Real-Time',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF131B2E),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.search,
                                    size: 18,
                                    color: Color(0xFF004AC6),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'VS 401',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF131B2E),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {},
                            child: const Text('Track'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAEDFF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.circle,
                                      size: 8,
                                      color: Color(0xFF006242),
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'VS 401 • In Flight',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF131B2E),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  'On Schedule',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF006242),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Alt: 37,000 ft',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF434655),
                                  ),
                                ),
                                Text(
                                  'Speed: 540 mph',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF434655),
                                  ),
                                ),
                                Text(
                                  'ETA: 07:45 (+1d)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF434655),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildHubTab(String id, String label, IconData icon) {
    final isSelected = _activeTab == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x140F172A),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? const Color(0xFF004AC6)
                    : const Color(0xFF434655),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected
                        ? const Color(0xFF004AC6)
                        : const Color(0xFF434655),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripTypeButton(String id, String label) {
    final isSelected = _tripType == id;
    return GestureDetector(
      onTap: () => setState(() => _tripType = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? const Color(0xFF004AC6)
                : const Color(0xFF434655),
          ),
        ),
      ),
    );
  }

  Widget _buildAirportRow({
    required String label,
    required String code,
    required String city,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      code,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF004AC6),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        city,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF131B2E),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(icon, color: const Color(0xFF004AC6), size: 22),
        ],
      ),
    );
  }

  Widget _buildAirportPairChip(String c1, String n1, String c2, String n2) {
    return GestureDetector(
      onTap: () => _setPair(c1, n1, c2, n2),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFE2E7FF),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '$c1 ⇄ $c2',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF131B2E),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPill(String label, IconData icon, {bool isSelected = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF131B2E) : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: isSelected ? Colors.white : const Color(0xFF131B2E),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF131B2E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlightCard({
    String? ribbonText,
    required String airlineName,
    required String flightCode,
    required String depTime,
    required String depCode,
    required String depAirport,
    required String arrTime,
    required String arrCode,
    required String arrAirport,
    required String durationText,
    required String stopLabel,
    required String baggageLabel,
    required double price,
    double? strikePrice,
    required String currency,
    VoidCallback? onSelect,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (ribbonText != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: const BoxDecoration(
                color: Color(0xFF007D55),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.verified,
                        size: 14,
                        color: Color(0xFFBDFFDB),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ribbonText,
                        style: const TextStyle(
                          color: Color(0xFFBDFFDB),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'ECOSAVER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Carrier row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEAEDFF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.flight,
                            size: 16,
                            color: Color(0xFF004AC6),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              airlineName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF131B2E),
                              ),
                            ),
                            Text(
                              flightCode,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F3FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.luggage,
                            size: 13,
                            color: Color(0xFF006242),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            baggageLabel,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF006242),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Flight schedule vector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          depTime,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF131B2E),
                          ),
                        ),
                        Text(
                          depCode,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF004AC6),
                          ),
                        ),
                        Text(
                          depAirport,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),

                    // Vector center
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            Text(
                              durationText,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF004AC6),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 1.5,
                                    color: const Color(0xFFB4C5FF),
                                    child: const Center(
                                      child: Icon(
                                        Icons.airplanemode_active,
                                        size: 14,
                                        color: Color(0xFF004AC6),
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF004AC6),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              stopLabel,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF006242),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          arrTime,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF131B2E),
                          ),
                        ),
                        Text(
                          arrCode,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF004AC6),
                          ),
                        ),
                        Text(
                          arrAirport,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Price & Button
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total per traveler',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  CurrencyService.formatPrice(price, currency),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF004AC6),
                                  ),
                                ),
                                if (strikePrice != null) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    CurrencyService.formatPrice(strikePrice, currency),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      decoration: TextDecoration.lineThrough,
                                      color: Color(0xFFF43F5E),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        onPressed: onSelect,
                        label: const Text(
                          'Select Flight',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        icon: const Icon(Icons.arrow_forward, size: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String desc,
    required String priceText,
    required String btnText,
    VoidCallback? onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF131B2E),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                priceText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF004AC6),
                ),
              ),
              GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAEDFF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    btnText,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF004AC6),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoungeStat extends StatelessWidget {
  const _LoungeStat({
    required this.title,
    required this.subtitle,
    this.isGreen = false,
  });

  final String title;
  final String subtitle;
  final bool isGreen;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isGreen ? const Color(0xFF006242) : const Color(0xFF004AC6),
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}
