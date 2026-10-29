import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cheapest_go_mobile/app/theme/app_theme.dart';
import 'package:cheapest_go_mobile/shared/components/app_buttons.dart';
import 'package:cheapest_go_mobile/shared/components/glass_card.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _selectedCategoryIndex = 0;

  final _categories = const ['All Getaways', 'Beach Stays', 'Metropolis', 'Golf & Villas'];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        // Minimalist Obsidian Hero Card
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppEffects.heroGradient,
            borderRadius: AppRadius.brCard,
            boxShadow: AppEffects.premiumShadow,
          ),
          child: ClipRRect(
            borderRadius: AppRadius.brCard,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(gradient: AppEffects.cardSheen),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: AppRadius.brPill,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 0.8,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('⚡', style: TextStyle(fontSize: 10)),
                                SizedBox(width: 5),
                                Text(
                                  'Server-Verified Fare Lock',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Where will you\njourney next?',
                        style: AppTheme.headlineXlMobile(color: Colors.white).copyWith(
                          letterSpacing: -0.8,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Instant live rates from Duffel, Mystifly & TravelgateX with zero markup.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: AppPrimaryButton(
                              label: 'Search Hotels',
                              icon: Icons.hotel_outlined,
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF0F172A),
                              onPressed: () => context.go('/hotels'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: AppSecondaryButton(
                              label: 'Search Flights',
                              icon: Icons.flight_takeoff,
                              textColor: Colors.white,
                              onPressed: () => context.push('/flights'),
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

        const SizedBox(height: 24),

        // Categories Segment
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              return AppFilterChip(
                label: _categories[index],
                selected: _selectedCategoryIndex == index,
                onSelected: (_) => setState(() => _selectedCategoryIndex = index),
              );
            },
          ),
        ),

        const SizedBox(height: 20),

        // Section Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Trending Getaways',
              style: AppTheme.headlineSm(color: colors.textPrimary).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            GestureDetector(
              onTap: () => context.go('/hotels'),
              child: Text(
                'View All',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Minimalist Destination Cards
        for (final item in const [
          (
            'Bali, Indonesia',
            'Championship Fairways · Luxury Beach Villas',
            'From \$214',
            '/night',
            Icons.beach_access_outlined,
            4.9,
          ),
          (
            'Tokyo, Japan',
            'Shinjuku & Ginza · Duffel Direct Fares',
            'From \$480',
            ' roundtrip',
            Icons.flight_outlined,
            4.8,
          ),
          (
            'Dubai, UAE',
            'Marina Suites · Verified Prebook Rates',
            'From \$380',
            '/night',
            Icons.location_city_outlined,
            4.9,
          ),
          (
            'Seoul, South Korea',
            'Gangnam & Myeongdong · Rapid Transit',
            'From \$140',
            '/night',
            Icons.hotel_outlined,
            4.7,
          ),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              onTap: () => context.go('/hotels'),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: colors.backgroundCanvas,
                      borderRadius: AppRadius.brMd,
                    ),
                    child: Icon(item.$5, color: colors.textPrimary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                item.$1,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: colors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 2),
                            Text(
                              item.$6.toString(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.$2,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        item.$3,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: colors.accent,
                        ),
                      ),
                      Text(
                        item.$4,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: colors.textMuted,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class ExploreView extends StatelessWidget {
  const ExploreView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        Text(
          'Curated Global Inventory',
          style: AppTheme.headlineMd(color: colors.textPrimary).copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Access multi-provider flight routes and verified hotel rates across Asia-Pacific, Europe, and the Americas.',
          style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.45),
        ),
        const SizedBox(height: 20),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.backgroundCanvas,
                  borderRadius: AppRadius.brMd,
                ),
                child: Icon(Icons.flight, color: colors.accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Multi-Provider Flight Engine',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Real-time fare comparison via Duffel & Mystifly',
                      style: TextStyle(fontSize: 12, color: colors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              AppPrimaryButton(
                label: 'Search',
                onPressed: () => context.push('/flights'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.backgroundCanvas,
                  borderRadius: AppRadius.brMd,
                ),
                child: const Icon(Icons.hotel_outlined, color: Color(0xFF0D9488), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TravelgateX Hotel Engine',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Direct Prebook rate lock & Stripe payments',
                      style: TextStyle(fontSize: 12, color: colors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              AppPrimaryButton(
                label: 'Explore',
                onPressed: () => context.go('/hotels'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
