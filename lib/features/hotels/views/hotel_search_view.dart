import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cheapest_go_mobile/features/hotels/contracts/hotels_contract.dart';
import 'package:cheapest_go_mobile/features/hotels/stores/hotels_store.dart';
import 'package:cheapest_go_mobile/shared/components/skeleton.dart';
import 'package:cheapest_go_mobile/shared/stores/ui_store.dart';
import 'package:cheapest_go_mobile/shared/utils/currency.dart';

class HotelSearchView extends StatefulWidget {
  const HotelSearchView({
    super.key,
    this.onToggleFavorite,
    this.isFavoriteChecker,
  });

  final Future<void> Function(HotelSummary hotel)? onToggleFavorite;
  final bool Function(String hotelId)? isFavoriteChecker;

  @override
  State<HotelSearchView> createState() => _HotelSearchViewState();
}

class _HotelSearchViewState extends State<HotelSearchView> {
  final _destinationController =
      TextEditingController(text: 'Bali, Indonesia');
  final _checkInController = TextEditingController(text: '2026-10-24');
  final _checkOutController = TextEditingController(text: '2026-10-28');

  String _activeCategory = 'golf'; // 'hotels' | 'golf' | 'villas'
  int _guestCount = 2;
  String _activeFilter = 'Golf Course On-site';

  @override
  void dispose() {
    _destinationController.dispose();
    _checkInController.dispose();
    _checkOutController.dispose();
    super.dispose();
  }

  void _adjustGuest(int delta) {
    setState(() {
      _guestCount = (_guestCount + delta).clamp(1, 8);
    });
  }

  void _setDestination(String dest) {
    setState(() {
      _destinationController.text = dest;
    });
    _runSearch();
  }

  Future<void> _runSearch() async {
    await hotelsStore.search(
      HotelSearchParams(
        destination: _destinationController.text,
        checkIn: _checkInController.text,
        checkOut: _checkOutController.text,
        adults: _guestCount,
        rooms: 1,
        currency: uiSettingsStore.displayCurrency,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayCcy = uiSettingsStore.displayCurrency;

    return ListenableBuilder(
      listenable: Listenable.merge([hotelsStore, uiSettingsStore]),
      builder: (context, _) {
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            // ── Category Segmented Switcher Bar ──────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E7FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    _buildCategoryButton(
                      id: 'hotels',
                      label: 'Hotels & Resorts',
                      icon: Icons.hotel_outlined,
                    ),
                    _buildCategoryButton(
                      id: 'golf',
                      label: 'Golf & Tee Times',
                      icon: Icons.sports_golf,
                    ),
                    _buildCategoryButton(
                      id: 'villas',
                      label: 'Villas',
                      icon: Icons.villa_outlined,
                    ),
                  ],
                ),
              ),
            ),

            // ── Destination & Itinerary Selector Card ───────────────────────
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
                    // Header row: Label + Quick Chips
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'DESTINATION / COURSE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        Row(
                          children: [
                            _buildDestinationQuickChip('Bali'),
                            const SizedBox(width: 6),
                            _buildDestinationQuickChip('Dubai'),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Destination Input
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F3FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.pin_drop,
                            color: Color(0xFF004AC6),
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: _destinationController,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF131B2E),
                                  ),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                    border: InputBorder.none,
                                    hintText: 'Enter city or course...',
                                  ),
                                  onSubmitted: (_) => _runSearch(),
                                ),
                                const Text(
                                  'Island of the Gods · Championship Fairways',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Dates & Guests Row
                    Row(
                      children: [
                        // Dates Box
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F3FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 15,
                                      color: Color(0xFF64748B),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'DATES',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Oct 24 - 28',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF131B2E),
                                  ),
                                ),
                                Text(
                                  '4 nights · 2 rounds',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF006242),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Guests Box
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F3FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.group_outlined,
                                      size: 15,
                                      color: Color(0xFF64748B),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'GUESTS',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '$_guestCount Guests',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF131B2E),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        InkWell(
                                          onTap: () => _adjustGuest(-1),
                                          child: Container(
                                            width: 22,
                                            height: 22,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFE2E7FF),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.remove, size: 14),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        InkWell(
                                          onTap: () => _adjustGuest(1),
                                          child: Container(
                                            width: 22,
                                            height: 22,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFE2E7FF),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.add, size: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const Text(
                                  '1 Suite / Villa',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Find Tee Times & Stays CTA Button
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
                        'Find Tee Times & Stays',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Quick Filter Horizon Chips ──────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildHorizonFilterChip(
                    'Golf Course On-site',
                    icon: Icons.verified,
                  ),
                  _buildHorizonFilterChip(
                    'Free Cancellation',
                    icon: Icons.event_available,
                  ),
                  _buildHorizonFilterChip('Spa & Pool', icon: Icons.pool),
                  _buildHorizonFilterChip(
                    'Under \$200',
                    icon: Icons.attach_money,
                  ),
                  _buildHorizonFilterChip(
                    'PGA Pro On-site',
                    icon: Icons.sports_score,
                  ),
                ],
              ),
            ),

            // ── Hero Promotional Banner: Stay + Golf Bundle ─────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Container(
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuCHq_98Rx-dIJKDsywqQK459aBBM_UTN3b1vVvCx96xD65CT0789ZyJaEIWLQXAoXP-nG-ToV2uN3rwVbi_jOY7EPzVr2cCLGAVhBi3hIiczfVjow8CqXtGyG6ROkjDtIDQ5yz-KAkISurfs0w1lC-bM1WuLauktzO3xoUUPztvIYnSRha3ZprU45JaNJqpgQtpsRFBUohV2x_0oznB0pd-uxbMvYVHHxqlCXK3lBY',
                    ),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x140F172A),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [
                        Colors.transparent,
                        Color(0x99131B2E),
                        Color(0xEE131B2E),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Badges Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF006242),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.stars, size: 14, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'SIGNATURE BUNDLE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.local_fire_department,
                                  size: 14,
                                  color: Color(0xFFF43F5E),
                                ),
                                SizedBox(width: 2),
                                Text(
                                  'Save 32%',
                                  style: TextStyle(
                                    color: Color(0xFF131B2E),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Content bottom
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: Color(0xFFA2EEFF),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Tanah Lot · Bali, Indonesia',
                                style: TextStyle(
                                  color: Color(0xFFA2EEFF),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Nirwana Bali Golf Resort & Spa',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Text(
                            'Unlimited Green Fees + 5-Star Oceanfront Villa + Caddy',
                            style: TextStyle(
                              color: Color(0xFFDBE1FF),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '\$410',
                                      style: TextStyle(
                                        decoration: TextDecoration.lineThrough,
                                        color: Color(0xFFEAEDFF),
                                        fontSize: 12,
                                      ),
                                    ),
                                    RichText(
                                      text: const TextSpan(
                                        children: [
                                          TextSpan(
                                            text: '\$280 ',
                                            style: TextStyle(
                                              color: Color(0xFFA2EEFF),
                                              fontSize: 22,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          TextSpan(
                                            text: '/ night',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3FE1FD),
                                  foregroundColor: const Color(0xFF001F25),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () {
                                  context.push('/hotel/nirwana-bali-bundle');
                                },
                                label: const Text(
                                  'Claim Bundle',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                icon: const Icon(Icons.arrow_forward, size: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Section Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Featured Golf Getaways',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF131B2E),
                        ),
                      ),
                      Text(
                        'Handpicked stay & play packages with verified tee times',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAEDFF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      hotelsStore.results.isNotEmpty
                          ? '${hotelsStore.results.length} Available'
                          : '14 Available',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF004AC6),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Hotels Feed ─────────────────────────────────────────────────
            if (hotelsStore.isLoading)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: 3,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, _) => const Skeleton(height: 160),
              )
            else if (hotelsStore.results.isNotEmpty)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: hotelsStore.results.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final h = hotelsStore.results[index];
                  final isFav = widget.isFavoriteChecker?.call(h.hotelId) ?? false;
                  return _buildFeedListingCard(
                    hotelId: h.hotelId,
                    name: h.name,
                    categoryLabel: '5-Star Luxury Resort · ${h.city}',
                    description:
                        'Ocean view, 18-hole championship course access & free VIP airport transfer included.',
                    imageUrl: h.imageUrl ??
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuCs8oi7j8XBg85vlYI8sqb1sGHJpVhnV6Bm_CqfZdiboCm1ojImXkMR0J2KC_76kZEfdWweUT8jnxbXV_h69tPqVMhqycxsE-uePkmA69pm1WKYYM_zg4UXYiQm_RbG5Ink5hKOZlFERIUDX89LlH78rYia56EmRYb2PFqbYXbubMSX-4qy7jTmXRAnEw17oHNHlnmBlFgDc4175ItsYDg8hTNg2k2f0UTou_z1w5M',
                    rating: h.reviewRating ?? 4.9,
                    reviewCount: h.reviewsCount > 0 ? h.reviewsCount : 840,
                    nightlyPrice: h.nightlyRate > 0 ? h.nightlyRate : 195,
                    originalPrice: (h.nightlyRate > 0 ? h.nightlyRate : 195) * 1.33,
                    currency: h.currency,
                    isFavorite: isFav,
                    onFavoriteTap: () => widget.onToggleFavorite?.call(h),
                    onBookTap: () => context.push('/hotel/${h.hotelId}'),
                  );
                },
              )
            else
              // Fallback curated showcases matching HTML mockup
              Column(
                children: [
                  _buildFeedListingCard(
                    hotelId: 'bal-01',
                    name: 'Grand Mirage Resort & Bali National Golf Club',
                    categoryLabel: '5-Star Luxury Resort · Nusa Dua, Bali',
                    description:
                        'Ocean view, 18-hole championship course access & free VIP airport transfer included.',
                    imageUrl:
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuCs8oi7j8XBg85vlYI8sqb1sGHJpVhnV6Bm_CqfZdiboCm1ojImXkMR0J2KC_76kZEfdWweUT8jnxbXV_h69tPqVMhqycxsE-uePkmA69pm1WKYYM_zg4UXYiQm_RbG5Ink5hKOZlFERIUDX89LlH78rYia56EmRYb2PFqbYXbubMSX-4qy7jTmXRAnEw17oHNHlnmBlFgDc4175ItsYDg8hTNg2k2f0UTou_z1w5M',
                    rating: 4.9,
                    reviewCount: 840,
                    nightlyPrice: 195,
                    originalPrice: 260,
                    currency: displayCcy,
                    dealBadge: 'Cheapest Direct Rate',
                    inventoryNotice: 'Only 2 villas left',
                    onBookTap: () => context.push('/hotel/bal-01'),
                  ),
                  const SizedBox(height: 14),
                  _buildFeedListingCard(
                    hotelId: 'dxb-02',
                    name: 'Emirates Golf Club & Luxury Marina Suites',
                    categoryLabel: 'Luxury Suites · Dubai Marina, UAE',
                    description:
                        'Floodlit night golf under the city stars + access to private rooftop infinity pool & lounge.',
                    imageUrl:
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuAv5Y8sHTSySize6iBaOvUCB0d6K2720gxq4xalxkAB32qmHMNKPY91-1f8YfL9AnuTNH7FtksC6NbN--RnfGkweijY-gW9lBcIluuBKAjgJBTHOPTMInOJIwi9udM63E9BmG_vsZrc95ZBflfXOnSccqIOs66Cgr9g1Fah5Z2Hsq1jRwJ1059jRq0sfOlYITjhqqEJkskk8YxhIs-E584cKOm2-QNvyjWzQn3OY8I',
                    rating: 4.8,
                    reviewCount: 612,
                    nightlyPrice: 240,
                    currency: displayCcy,
                    dealBadge: 'Night Golf Experience',
                    onBookTap: () => context.push('/hotel/dxb-02'),
                  ),
                  const SizedBox(height: 14),
                  _buildFeedListingCard(
                    hotelId: 'tyo-03',
                    name: 'Tokyo Bay Grand & Kisarazu Country Club',
                    categoryLabel: 'Chiba Prefecture · Tokyo Bay, Japan',
                    description:
                        'Signature Fuji-view par-72 course, authentic thermal onsen bathhouse & traditional Kaiseki dinner.',
                    imageUrl:
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuArvYcXGTLyo60X8EM8CmIi-2uUc4ql2mqAs5o-zhAQXzRrLN4AwtrrBsLtm6IwsGfzfYDjZ3y6LQbmc8-Zl0mEhamPU1kgA-kCeV0qwYIn7xm3b3PeCvXe1om0eX9SRDouOg3y7INurpik4DALFkNbA3rZfbE6bYTPJzzl28z9zEGbBExy_YRu0kuThneVHR8_DG1hzuKufz3w4t0gOwH1XeOdfI5EhLtIpNLyT80',
                    rating: 4.7,
                    reviewCount: 428,
                    nightlyPrice: 165,
                    currency: displayCcy,
                    dealBadge: 'Onsen Spa Included',
                    onBookTap: () => context.push('/hotel/tyo-03'),
                  ),
                ],
              ),

            // ── Trust & Guarantees Strip ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              child: Row(
                children: [
                  _buildTrustItem(
                    icon: Icons.verified,
                    iconColor: const Color(0xFF007D55),
                    title: 'Guaranteed Tee',
                    subtitle: 'Instant reservation',
                  ),
                  const SizedBox(width: 8),
                  _buildTrustItem(
                    icon: Icons.price_check,
                    iconColor: const Color(0xFF004AC6),
                    title: 'Best Price',
                    subtitle: 'Bundle savings',
                  ),
                  const SizedBox(width: 8),
                  _buildTrustItem(
                    icon: Icons.support_agent,
                    iconColor: const Color(0xFFF43F5E),
                    title: 'Caddy Concierge',
                    subtitle: '24/7 golf assistance',
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryButton({
    required String id,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _activeCategory == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeCategory = id),
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
              if (isSelected && id == 'golf') ...[
                Icon(icon, size: 16, color: const Color(0xFF006242)),
                const SizedBox(width: 4),
              ],
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

  Widget _buildDestinationQuickChip(String label) {
    return GestureDetector(
      onTap: () => _setDestination(label == 'Bali' ? 'Bali, Indonesia' : 'Dubai, UAE'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFEAEDFF),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF004AC6),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizonFilterChip(String label, {required IconData icon}) {
    final isSelected = _activeFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF131B2E) : const Color(0xFFF2F3FF),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? const Color(0xFF4EDEA3)
                  : const Color(0xFF434655),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF434655),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedListingCard({
    required String hotelId,
    required String name,
    required String categoryLabel,
    required String description,
    required String imageUrl,
    required double rating,
    required int reviewCount,
    required double nightlyPrice,
    double? originalPrice,
    required String currency,
    String? dealBadge,
    String? inventoryNotice,
    bool isFavorite = false,
    VoidCallback? onFavoriteTap,
    VoidCallback? onBookTap,
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
          // Media with overlay pills
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  imageUrl,
                  height: 190,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    height: 190,
                    color: const Color(0xFFDAE2FD),
                    child: const Icon(Icons.hotel, size: 48, color: Colors.grey),
                  ),
                ),
              ),

              // Top badges
              Positioned(
                top: 10,
                left: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (dealBadge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF007D55),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          dealBadge,
                          style: const TextStyle(
                            color: Color(0xFFBDFFDB),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (inventoryNotice != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF43F5E),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          inventoryNotice,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Wishlist button
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: onFavoriteTap,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      size: 18,
                      color: isFavorite
                          ? const Color(0xFFF43F5E)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),

              // Rating overlay
              Positioned(
                bottom: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xCC131B2E),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 13,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '($reviewCount reviews)',
                        style: const TextStyle(
                          color: Color(0xFFDAE2FD),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.hotel_class,
                      size: 14,
                      color: Color(0xFF004AC6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      categoryLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF004AC6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF131B2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 10),

                // Amenity Chips
                const Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _AmenityBadge(label: 'Golf buggy included', icon: Icons.sports_golf),
                    _AmenityBadge(label: 'Caddy service', icon: Icons.person_outline),
                    _AmenityBadge(label: 'PGA Pro coaching', icon: Icons.school),
                  ],
                ),
                const SizedBox(height: 14),

                // Price & CTA Row
                Container(
                  padding: const EdgeInsets.only(top: 12),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFFEAEDFF), width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (originalPrice != null)
                              Row(
                                children: [
                                  Text(
                                    CurrencyService.formatPrice(originalPrice, currency),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      decoration: TextDecoration.lineThrough,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0x33007D55),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      '-25%',
                                      style: TextStyle(
                                        color: Color(0xFF006242),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: CurrencyService.formatPrice(nightlyPrice, currency),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF004AC6),
                                    ),
                                  ),
                                  const TextSpan(
                                    text: ' / night',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Text(
                              'Includes green fees & taxes',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF004AC6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: onBookTap,
                        icon: const Icon(Icons.event, size: 14),
                        label: const Text(
                          'Book Stay',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
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

  Widget _buildTrustItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A0F172A),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF131B2E),
              ),
            ),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF64748B),
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmenityBadge extends StatelessWidget {
  const _AmenityBadge({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEAEDFF),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF004AC6)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF131B2E),
            ),
          ),
        ],
      ),
    );
  }
}
