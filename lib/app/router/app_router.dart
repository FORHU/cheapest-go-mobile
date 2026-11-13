import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cheapest_go_mobile/app/router/app_header.dart';
import 'package:cheapest_go_mobile/app/router/v2_bottom_nav.dart';
import 'package:cheapest_go_mobile/shared/stores/app_refresh.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/generated/tw_palette.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/generated/tw_scale.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cheapest_go_mobile/app/router/stay_play_view.dart';
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
import 'package:cheapest_go_mobile/features/about/views/about_view.dart';
import 'package:cheapest_go_mobile/features/map/views/map_view.dart';
import 'package:cheapest_go_mobile/features/profile/views/profile_view.dart';
import 'package:cheapest_go_mobile/features/trips/views/trips_view.dart';

/// FAOS `app/` layer: routes and the tab shell.
GoRouter createAppRouter() => GoRouter(
      // `--dart-define=START_AT=/about` opens straight onto a screen, which is how a screen
      // under construction gets looked at before anything links to it. Defaults to the home
      // tab, so a release build behaves exactly as it always did.
      initialLocation: const String.fromEnvironment('START_AT', defaultValue: '/'),
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => MainScaffoldShell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(routes: [GoRoute(path: '/', builder: (_, _) => const HomeView())]),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/stay',
                  builder: (_, state) => StayPlayView(initialTab: state.uri.queryParameters['tab'] == 'golf' ? 1 : 0),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [GoRoute(path: '/map', builder: (_, _) => const MapView())],
            ),
            StatefulShellBranch(routes: [GoRoute(path: '/flights', builder: (_, _) => const FlightResultsView(asTab: true))]),
            StatefulShellBranch(routes: [GoRoute(path: '/trips', builder: (_, _) => const TripsView())]),
          ],
        ),
        // The same hotel and golf lists, opened as pages from Home, the airport
        // hub, checkout and trips.
        GoRoute(path: '/hotels', builder: (_, _) => const Scaffold(body: HotelResultsView())),
        GoRoute(path: '/golf', builder: (_, _) => const Scaffold(body: GolfView())),
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
          builder: (context, state) => HotelCheckoutView(
            hotelId: state.uri.queryParameters['hotel'] ?? '',
            // The Offer, not the room: a prebook is made against one set of terms.
            roomId: state.uri.queryParameters['room'] ?? '',
            // The checkout needs to know who is booking, and the hotels feature may not reach
            // into the auth feature to find out. The two are composed here, which is the app
            // layer's job — the screen is handed an answer, not a store.
            guest: () {
              final user = authStore.user;
              return user == null
                  ? const CheckoutGuest()
                  : CheckoutGuest(
                      signedIn: true,
                      email: user.email,
                      firstName: user.firstName,
                      lastName: user.lastName,
                    );
            },
            onSignIn: () => context.push('/login'),
          ),
        ),
        GoRoute(
          path: '/flight-checkout',
          builder: (_, state) => FlightCheckoutView(
            offerId: state.uri.queryParameters['offer'] ?? '',
            leadName: authStore.user?.fullName,
            leadEmail: authStore.user?.email,
            simulatedPriceShift: int.tryParse(state.uri.queryParameters['shift'] ?? ''),
          ),
        ),
        GoRoute(path: '/saved', redirect: (_, _) => '/trips'),
        GoRoute(path: '/login', builder: (_, _) => const LoginView()),
        GoRoute(path: '/register', builder: (_, _) => const RegisterView()),
        GoRoute(path: '/forgot-password', builder: (_, _) => const ForgotPasswordView()),
        // Nothing links here yet: the account screen that carries V2's footer links is a later
        // slice. Reachable by deep link and by test until then.
        GoRoute(path: '/about', builder: (_, _) => const AboutView()),
      ],
    );

final GoRouter appRouter = createAppRouter();

/// The app shell: a shared header, the current branch, and V2's bottom bar.
///
/// The bar is Home · Trips · Settings, which is V2's exactly (#36). It used to be four
/// labelled tabs plus a centre globe into the native map; V2 has neither, so both are gone.
///
/// Three consequences worth stating, because each looks like an omission:
///
///  * **No pull to refresh.** V2 offers none, and its query layer holds data for 60 seconds
///    with refetch-on-focus switched off, so content refreshes when you navigate. Mobile now
///    matches rather than offering an affordance the web does not have — see **Design Parity**
///    in CONTEXT.md, which governs behaviour as well as appearance.
///  * **No map entry point.** `/map` still routes, so a deep link and the feature's own tests
///    still reach it, but nothing in the interface links there any more. ADR-0001 explains why
///    the code stays; do not delete it on the assumption it is dead.
///  * **Nothing hides the bar on checkout.** V2 has to, because its bar is global. Here
///    `/checkout` and `/flight-checkout` sit outside this shell and never had one.
class MainScaffoldShell extends StatefulWidget {
  const MainScaffoldShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  State<MainScaffoldShell> createState() => _MainScaffoldShellState();
}

class _MainScaffoldShellState extends State<MainScaffoldShell> {
  static const _homeBranch = 0;
  static const _tripsBranch = 4;

  bool _settingsOpen = false;

  void _goBranch(int branch) {
    final shell = widget.navigationShell;
    shell.goBranch(branch, initialLocation: branch == shell.currentIndex);
    // Arriving at a tab is what refreshes it now that the pull gesture is gone, and only if
    // what we hold is over a minute old — V2's staleTime, for the same reason.
    unawaited(refreshAppDataIfStale());
  }

  /// V2 shows the gear lit while its sheet is open, and falls back to Home for any route that
  /// is not one of the three. The branches reachable only by deep link do the same here.
  bool get _onHome => widget.navigationShell.currentIndex == _homeBranch;

  int get _activeIndex {
    if (_settingsOpen) return 2;
    return widget.navigationShell.currentIndex == _tripsBranch ? 1 : 0;
  }

  Future<void> _openSettings() async {
    setState(() => _settingsOpen = true);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      // V2 dims the page behind at 50%.
      barrierColor: const Color(0x80000000),
      builder: (_) => const _SettingsSheet(),
    );
    if (mounted) setState(() => _settingsOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // On the landing only: the showcase runs under the bar as well as under the header, or
      // the photo stops short and leaves a strip of scaffold below it. Everywhere else the
      // body stays above the bar, which is what those screens were laid out against.
      extendBody: _onHome,
      // On the landing the header floats over the stage's photograph, so the picture runs to
      // the top of the screen as it does on V2. Everywhere else it sits on a bar above the
      // content, which is why the two arrangements differ rather than one serving both.
      body: _onHome
          ? Stack(
              children: [
                widget.navigationShell,
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: AppHeader(onShowcase: true),
                ),
              ],
            )
          : Column(
              children: [
                const AppHeader(),
                Expanded(
                  child: MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    child: widget.navigationShell,
                  ),
                ),
              ],
            ),
      bottomNavigationBar: V2BottomNav(
        activeIndex: _activeIndex,
        settingsOpen: _settingsOpen,
        onHome: () => _goBranch(_homeBranch),
        onTrips: () => _goBranch(_tripsBranch),
        onSettings: _openSettings,
      ),
    );
  }
}

/// The sheet behind the gear.
///
/// V2's gear opens its account surface rather than linking to a settings page — "the sheet this
/// opens is already the account surface — it carries Account settings and sign in/out" — so
/// this shows the same surface mobile already has, without its own header, which the sheet
/// supplies. #46 replaces the contents with V2's account layout.
class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
      decoration: BoxDecoration(
        color: dark ? TwPalette.slate900 : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The grab handle: 48 x 6, centred, with 12 above and below.
          Container(
            width: TwSpace.of(12),
            height: TwSpace.of(1.5),
            margin: EdgeInsets.symmetric(vertical: TwSpace.of(3)),
            decoration: BoxDecoration(
              color: dark ? TwPalette.slate800 : TwPalette.slate200,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: TwSpace.of(6), vertical: TwSpace.of(2)),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: dark ? TwPalette.slate800 : TwPalette.slate100),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: TwText.lg.size,
                    height: TwText.lg.height,
                    fontWeight: FontWeight.w700,
                    color: dark ? Colors.white : TwPalette.slate900,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close settings',
                  icon: Icon(LucideIcons.x, size: 20, color: TwPalette.slate500),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListenableBuilder(
              listenable: authStore,
              builder: (context, _) => ProfileView(
                embedded: true,
                isAuthenticated: authStore.isAuthenticated,
                userName: authStore.user?.fullName,
                userEmail: authStore.user?.email,
                onSignInTap: () {
                  Navigator.of(context).pop();
                  context.push('/login');
                },
                onRegisterTap: () {
                  Navigator.of(context).pop();
                  context.push('/register');
                },
                onSignOutTap: authStore.logout,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
