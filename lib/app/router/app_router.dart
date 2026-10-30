import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cheapest_go_mobile/app/router/globe_bottom_nav.dart';
import 'package:cheapest_go_mobile/app/theme/app_theme.dart';
import 'package:cheapest_go_mobile/features/auth/stores/auth_store.dart';
import 'package:cheapest_go_mobile/features/auth/views/forgot_password_view.dart';
import 'package:cheapest_go_mobile/features/auth/views/login_view.dart';
import 'package:cheapest_go_mobile/features/auth/views/register_view.dart';
import 'package:cheapest_go_mobile/features/explore/views/explore_view.dart';
import 'package:cheapest_go_mobile/features/flights/views/flight_checkout_view.dart';
import 'package:cheapest_go_mobile/features/flights/views/flights_view.dart';
import 'package:cheapest_go_mobile/features/hotels/views/hotel_checkout_view.dart';
import 'package:cheapest_go_mobile/features/hotels/views/hotel_detail_view.dart';
import 'package:cheapest_go_mobile/features/hotels/views/hotel_search_view.dart';
import 'package:cheapest_go_mobile/features/map/views/map_view.dart';
import 'package:cheapest_go_mobile/features/profile/views/profile_view.dart';
import 'package:cheapest_go_mobile/features/trips/views/trips_view.dart';
import 'package:cheapest_go_mobile/shared/stores/ui_store.dart';

/// FAOS `app/` Layer — Kinetic Horizon Composer & Declarative Router
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainScaffoldShell(navigationShell: navigationShell);
      },
      branches: [
        // Branch 0: Explore / Home
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeView(),
            ),
          ],
        ),
        // Branch 1: Hotels & Golf (Core Destination Search)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/hotels',
              builder: (context, state) => ListenableBuilder(
                listenable: savedHotelsStore,
                builder: (context, _) => HotelSearchView(
                  isFavoriteChecker: savedHotelsStore.isFavorite,
                  onToggleFavorite: (hotel) => savedHotelsStore.toggleFavorite(
                    SavedHotelItem(
                      hotelId: hotel.hotelId,
                      name: hotel.name,
                      city: hotel.city,
                      nightlyRate: hotel.nightlyRate,
                      currency: hotel.currency,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        // Branch 2: Center Globe Map
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/map',
              builder: (context, state) => const MapView(),
            ),
          ],
        ),
        // Branch 3: Flights
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/flights',
              builder: (context, state) => const FlightsView(),
            ),
          ],
        ),
        // Branch 4: Trips (Consolidated Bookings + Saved Stays)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/trips',
              builder: (context, state) => const TripsView(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/saved',
      builder: (context, state) => const TripsView(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => ListenableBuilder(
        listenable: authStore,
        builder: (context, _) => ProfileView(
          isAuthenticated: authStore.isAuthenticated,
          userName: authStore.user?.fullName,
          userEmail: authStore.user?.email,
          onSignInTap: () => context.push('/login'),
          onRegisterTap: () => context.push('/register'),
          onSignOutTap: authStore.logout,
        ),
      ),
    ),
    GoRoute(
      path: '/flight-checkout',
      builder: (context, state) => const FlightCheckoutView(),
    ),
    GoRoute(
      path: '/hotel/:id',
      builder: (context, state) => HotelDetailView(
        hotelId: state.pathParameters['id'] ?? '',
      ),
    ),
    GoRoute(
      path: '/checkout',
      builder: (context, state) => const HotelCheckoutView(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginView(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterView(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordView(),
    ),
  ],
);

class MainScaffoldShell extends StatelessWidget {
  const MainScaffoldShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  void _onTapBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  void _showCurrencySelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final currencies = ['USD', 'EUR', 'GBP', 'PHP', 'KRW', 'JPY', 'SGD', 'AED'];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Select Currency',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: currencies.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final ccy = currencies[i];
                    return ListTile(
                      title: Text(ccy, style: const TextStyle(fontWeight: FontWeight.w600)),
                      trailing: uiSettingsStore.displayCurrency == ccy
                          ? const Icon(Icons.check, color: KineticHorizonColors.primary)
                          : null,
                      onTap: () {
                        uiSettingsStore.setDisplayCurrency(ccy);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final idx = navigationShell.currentIndex;
    final isMapTab = idx == 2;

    // Map 5 branches to 4 tabs + center globe:
    // Tab 0 -> Branch 0 (Explore)
    // Tab 1 -> Branch 1 (Hotels)
    // Center Globe -> Branch 2 (Map)
    // Tab 2 -> Branch 3 (Flights)
    // Tab 3 -> Branch 4 (Trips: Bookings + Saved)
    int navTabIndex;
    switch (idx) {
      case 0:
        navTabIndex = 0;
        break;
      case 1:
        navTabIndex = 1;
        break;
      case 3:
        navTabIndex = 2;
        break;
      case 4:
        navTabIndex = 3;
        break;
      default:
        navTabIndex = -1;
    }

    return Scaffold(
      backgroundColor: isMapTab ? const Color(0xFF070B14) : KineticHorizonColors.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: BoxDecoration(
            color: isMapTab
                ? const Color(0xFF070B14).withValues(alpha: 0.95)
                : Colors.white.withValues(alpha: 0.92),
            border: Border(
              bottom: BorderSide(
                color: isMapTab
                    ? Colors.white.withValues(alpha: 0.1)
                    : const Color(0x140F172A),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo + Title
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: KineticHorizonColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.travel_explore,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'CheapestGo',
                        style: AppTheme.headlineSm(
                          color: isMapTab ? Colors.white : KineticHorizonColors.primary,
                        ).copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
                      ),
                    ],
                  ),

                  // Actions: Currency Chip + Avatar
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _showCurrencySelector(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isMapTab
                                ? Colors.white.withValues(alpha: 0.12)
                                : const Color(0xFFE2E7FF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: ListenableBuilder(
                            listenable: uiSettingsStore,
                            builder: (context, _) => Row(
                              children: [
                                const Text('🇺🇸', style: TextStyle(fontSize: 12)),
                                const SizedBox(width: 4),
                                Text(
                                  uiSettingsStore.displayCurrency,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isMapTab ? Colors.white : const Color(0xFF131B2E),
                                  ),
                                ),
                                Icon(
                                  Icons.expand_more,
                                  size: 14,
                                  color: isMapTab ? Colors.white70 : const Color(0xFF131B2E),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // User Profile Avatar Dropdown
                      Theme(
                        data: Theme.of(context).copyWith(
                          popupMenuTheme: PopupMenuThemeData(
                            color: const Color(0xFF0F172A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.15),
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                        child: PopupMenuButton<String>(
                          tooltip: 'Profile & Map Settings',
                          offset: const Offset(0, 42),
                          padding: EdgeInsets.zero,
                          elevation: 10,
                          onSelected: (value) {
                            if (value == 'profile') {
                              context.push('/profile');
                            } else if (value == 'logout') {
                              authStore.logout();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Logged out of session'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          itemBuilder: (context) {
                            return <PopupMenuEntry<String>>[
                              PopupMenuItem<String>(
                                enabled: false,
                                child: ListenableBuilder(
                                  listenable: authStore,
                                  builder: (context, _) {
                                    final u = authStore.user;
                                    final fullName = u != null ? '${u.firstName} ${u.lastName}'.trim() : '';
                                    final userName = fullName.isNotEmpty ? fullName : 'CheapestGo Traveler';
                                    final userEmail = u?.email ?? 'Member Account';
                                    return Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: KineticHorizonColors.primary.withValues(alpha: 0.25),
                                          child: const Icon(
                                            Icons.person,
                                            size: 18,
                                            color: Color(0xFF3FE1FD),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                userName,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                userEmail,
                                                style: TextStyle(
                                                  color: Colors.white.withValues(alpha: 0.6),
                                                  fontSize: 11,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                              const PopupMenuDivider(height: 1),
                              PopupMenuItem<String>(
                                value: 'profile',
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.manage_accounts_outlined,
                                      size: 18,
                                      color: Colors.white70,
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Profile & Account',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      size: 16,
                                      color: Colors.white38,
                                    ),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(height: 1),
                              PopupMenuItem<String>(
                                value: 'logout',
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.logout_rounded,
                                      size: 18,
                                      color: Color(0xFFEF4444),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Log Out',
                                        style: TextStyle(
                                          color: Color(0xFFEF4444),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ];
                          },
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: KineticHorizonColors.surfaceContainerHigh,
                              border: Border.all(
                                color: KineticHorizonColors.primaryFixedDim,
                                width: 1.5,
                              ),
                            ),
                            child: ClipOval(
                              child: Image.network(
                                'https://lh3.googleusercontent.com/aida-public/AB6AXuAgJhQqomXb83w03ofFuO95SlW-4DDtMu6H_BAhUCn3DyjkF9LTJi5eSlnA8z-EM84WU1Gah_gE5DLsBy1s6jI0z4EXmJY-3jfMa0_dg2KBJQ9nGsoEHiSqT2jGqejUxsm-HIYiRTsKDhV_f2oRwKNAbW_qWDJoupWcgYAFESBp9jF_OfVwU2_S7FwHGokOCHLwmNK1CBWwQ_ClXuj4MMiDN_29MQMNebcDonYtVhk',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(
                                  Icons.person,
                                  size: 18,
                                  color: KineticHorizonColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: navigationShell,
      bottomNavigationBar: GlobeBottomNav(
        tabs: const [
          GlobeNavTab(
            icon: Icons.explore_outlined,
            activeIcon: Icons.explore,
            label: 'Explore',
          ),
          GlobeNavTab(
            icon: Icons.hotel_outlined,
            activeIcon: Icons.hotel_rounded,
            label: 'Hotels',
          ),
          GlobeNavTab(
            icon: Icons.flight_takeoff_outlined,
            activeIcon: Icons.flight_takeoff_rounded,
            label: 'Flights',
          ),
          GlobeNavTab(
            icon: Icons.luggage_outlined,
            activeIcon: Icons.luggage_rounded,
            label: 'Trips',
          ),
        ],
        currentIndex: navTabIndex,
        isGlobeActive: isMapTab,
        onTabSelected: (tabIdx) {
          switch (tabIdx) {
            case 0:
              _onTapBranch(0); // Explore
              break;
            case 1:
              _onTapBranch(1); // Hotels
              break;
            case 2:
              _onTapBranch(3); // Flights
              break;
            case 3:
              _onTapBranch(4); // Trips
              break;
          }
        },
        onGlobePressed: () => _onTapBranch(2), // Globe Map in the center
      ),
    );
  }
}
