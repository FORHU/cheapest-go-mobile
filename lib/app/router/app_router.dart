import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cheapest_go_mobile/app/router/globe_bottom_nav.dart';
import 'package:cheapest_go_mobile/features/airports/views/airport_hub_view.dart';
import 'package:cheapest_go_mobile/features/auth/stores/auth_store.dart';
import 'package:cheapest_go_mobile/features/auth/views/forgot_password_view.dart';
import 'package:cheapest_go_mobile/features/auth/views/login_view.dart';
import 'package:cheapest_go_mobile/features/auth/views/register_view.dart';
import 'package:cheapest_go_mobile/features/flights/views/flight_checkout_view.dart';
import 'package:cheapest_go_mobile/features/flights/views/flight_results_view.dart';
import 'package:cheapest_go_mobile/features/golf/views/golf_view.dart';
import 'package:cheapest_go_mobile/features/home/views/home_view.dart';
import 'package:cheapest_go_mobile/features/hotels/views/hotel_checkout_view.dart';
import 'package:cheapest_go_mobile/features/hotels/views/hotel_detail_view.dart';
import 'package:cheapest_go_mobile/features/hotels/views/hotel_results_view.dart';
import 'package:cheapest_go_mobile/features/map/views/map_view.dart';
import 'package:cheapest_go_mobile/features/profile/views/profile_view.dart';
import 'package:cheapest_go_mobile/features/trips/views/trips_view.dart';

/// FAOS `app/` layer: routes and the tab shell.
GoRouter createAppRouter() => GoRouter(
      initialLocation: '/',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => MainScaffoldShell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(routes: [GoRoute(path: '/', builder: (_, _) => const HomeView())]),
            StatefulShellBranch(routes: [GoRoute(path: '/flights', builder: (_, _) => const FlightResultsView(asTab: true))]),
            StatefulShellBranch(
              routes: [GoRoute(path: '/map', builder: (_, _) => const SafeArea(bottom: false, child: MapView()))],
            ),
            StatefulShellBranch(routes: [GoRoute(path: '/trips', builder: (_, _) => const TripsView())]),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (context, _) => ListenableBuilder(
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
              ],
            ),
          ],
        ),
        // Stays and golf live under the Stay & Play tab; they open as pages.
        GoRoute(path: '/hotels', builder: (_, _) => const Scaffold(body: HotelResultsView())),
        GoRoute(path: '/golf', builder: (_, _) => const Scaffold(body: GolfView())),
        GoRoute(
          path: '/airport/:code',
          builder: (_, state) => AirportHubView(code: state.pathParameters['code']!.toUpperCase()),
        ),
        GoRoute(
          path: '/hotel/:id',
          builder: (_, state) => HotelDetailView(hotelId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/checkout',
          builder: (_, state) => HotelCheckoutView(
            hotelId: state.uri.queryParameters['hotel'] ?? '',
            roomId: state.uri.queryParameters['room'] ?? '',
          ),
        ),
        GoRoute(
          path: '/flight-checkout',
          builder: (_, state) => FlightCheckoutView(offerId: state.uri.queryParameters['offer'] ?? ''),
        ),
        GoRoute(path: '/saved', redirect: (_, _) => '/trips'),
        GoRoute(path: '/login', builder: (_, _) => const LoginView()),
        GoRoute(path: '/register', builder: (_, _) => const RegisterView()),
        GoRoute(path: '/forgot-password', builder: (_, _) => const ForgotPasswordView()),
      ],
    );

final GoRouter appRouter = createAppRouter();

/// Bottom navigation: Stay & Play · Flights · Map (center globe) · Trips · Profile.
/// Stay & Play is Home, where stays and golf near the arrival airport start.
class MainScaffoldShell extends StatelessWidget {
  const MainScaffoldShell({required this.navigationShell, super.key});

  static const _mapBranch = 2;

  /// Tab index (0–3) for each non-map branch.
  static const _branchForTab = [0, 1, 3, 4];

  final StatefulNavigationShell navigationShell;

  void _goBranch(int branch) {
    navigationShell.goBranch(branch, initialLocation: branch == navigationShell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final branch = navigationShell.currentIndex;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: GlobeBottomNav(
        tabs: const [
          GlobeNavTab(icon: Icons.travel_explore_outlined, activeIcon: Icons.travel_explore_rounded, label: 'Stay & Play'),
          GlobeNavTab(icon: Icons.flight_outlined, activeIcon: Icons.flight_rounded, label: 'Flights'),
          GlobeNavTab(icon: Icons.luggage_outlined, activeIcon: Icons.luggage_rounded, label: 'Trips'),
          GlobeNavTab(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
        ],
        currentIndex: _branchForTab.indexOf(branch),
        isGlobeActive: branch == _mapBranch,
        onTabSelected: (tab) => _goBranch(_branchForTab[tab]),
        onGlobePressed: () => _goBranch(_mapBranch),
      ),
    );
  }
}
