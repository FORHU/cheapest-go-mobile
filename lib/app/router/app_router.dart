import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/app/router/auth_gate.dart';
import 'package:cheapest_go_mobile/shared/tips/tip_anchor.dart';
import 'package:cheapest_go_mobile/app/router/v2_bottom_nav.dart';
import 'package:cheapest_go_mobile/features/onboarding/stores/onboarding_store.dart';
import 'package:cheapest_go_mobile/features/onboarding/views/onboarding_view.dart';
import 'package:cheapest_go_mobile/features/ai_chat/views/ai_chat_view.dart';
import 'package:cheapest_go_mobile/shared/stores/app_refresh.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/generated/tw_palette.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/generated/tw_scale.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cheapest_go_mobile/app/router/stay_play_view.dart';
import 'package:cheapest_go_mobile/features/airports/views/airport_hub_view.dart';
import 'package:cheapest_go_mobile/features/auth/stores/auth_store.dart';
import 'package:cheapest_go_mobile/features/legal/lib/legal_documents.dart';
import 'package:cheapest_go_mobile/features/legal/views/help_view.dart';
import 'package:cheapest_go_mobile/features/legal/views/legal_view.dart';
import 'package:cheapest_go_mobile/features/auth/views/auth_code_error_view.dart';
import 'package:cheapest_go_mobile/features/auth/views/forgot_password_view.dart';
import 'package:cheapest_go_mobile/features/auth/views/reset_password_view.dart';
import 'package:cheapest_go_mobile/features/auth/views/login_view.dart';
import 'package:cheapest_go_mobile/features/auth/views/register_view.dart';
import 'package:cheapest_go_mobile/features/flights/lib/flight_search_query.dart';
import 'package:cheapest_go_mobile/features/flights/views/flight_checkout_view.dart';
import 'package:cheapest_go_mobile/features/flights/views/flight_search_view.dart';
import 'package:cheapest_go_mobile/shared/stores/trip_search_store.dart';
import 'package:cheapest_go_mobile/features/golf/views/golf_view.dart';
import 'package:cheapest_go_mobile/features/home/views/home_view.dart';
import 'package:cheapest_go_mobile/features/hotels/views/hotel_checkout_view.dart';
import 'package:cheapest_go_mobile/features/hotels/views/hotel_detail_view.dart';
import 'package:cheapest_go_mobile/features/hotels/views/hotel_results_view.dart';
import 'package:cheapest_go_mobile/features/about/views/about_view.dart';
import 'package:cheapest_go_mobile/features/map/views/map_view.dart';
import 'package:cheapest_go_mobile/features/profile/views/profile_view.dart';
import 'package:cheapest_go_mobile/features/trips/views/booking_detail_view.dart';
import 'package:cheapest_go_mobile/features/trips/views/trips_view.dart';

/// FAOS `app/` layer: routes and the tab shell.
/// [gate] is what stands between a launch and the app. On in every build; a widget test that
/// is about some other screen turns it off rather than signing an account in first, because
/// otherwise every test in the repo would be a test of the gate. `test/app/auth_gate_test.dart`
/// and the gated case in `test/app/shell_test.dart` are where it is actually exercised.
GoRouter createAppRouter({bool gate = true}) => GoRouter(
      // `--dart-define=START_AT=/about` opens straight onto a screen, which is how a screen
      // under construction gets looked at before anything links to it. Defaults to the home
      // tab, so a release build behaves exactly as it always did.
      initialLocation: const String.fromEnvironment('START_AT', defaultValue: '/'),

      // The gate: no account, no app. See `auth_gate.dart` and ADR-0005 — this is the one
      // place mobile deliberately parts company with V2, which lets anyone browse signed out.
      redirect: gate ? (context, state) => routerGateRedirect(state.uri.toString()) : null,
      refreshListenable: GateListenable([authStore, onboardingStore]),

      routes: [
        GoRoute(path: splashPath, builder: (_, _) => const _StartingView()),
        GoRoute(path: onboardingPath, builder: (_, _) => const OnboardingView()),
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
            // Kept as a branch so the shell's indexes do not move, but `/flights` is no longer a
            // screen of its own: it opens V2's search for the trip being planned (#47).
            StatefulShellBranch(
              routes: [GoRoute(path: '/flights', redirect: (_, _) => _flightSearchFromStore(), builder: (_, _) => const SizedBox.shrink())],
            ),
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
        // V2's AI chat. Outside the shell because V2's bar steps aside on `/ai-chat`
        // (`MobileBottomNav.tsx`): the conversation has the screen to itself. `?q=` is the
        // question a landing or search hands over, sent on arrival.
        GoRoute(
          path: '/ai-chat',
          builder: (_, state) => AiChatView(initialQuery: state.uri.queryParameters['q']),
        ),
        // V2's flight search and booking (#47). Every fare is api-v2's, from Duffel.
        GoRoute(
          path: '/flights/search',
          builder: (_, state) => FlightSearchView(params: state.uri.queryParameters),
        ),
        // V2 keeps `/flights/book` for links that still point at it and hands them to checkout.
        GoRoute(
          path: '/flights/book',
          redirect: (_, state) => state.uri.queryParameters['offerId'] == null
              ? '/'
              : Uri(path: '/flight-checkout', queryParameters: state.uri.queryParameters).toString(),
        ),
        GoRoute(
          path: '/flight-checkout',
          builder: (context, state) => ListenableBuilder(
            listenable: authStore,
            builder: (context, _) => FlightCheckoutView(
              params: state.uri.queryParameters,
              isSignedIn: () => authStore.isAuthenticated,
              onSignIn: () => context.push('/login'),
            ),
          ),
        ),
        // Outside the shell, as V2's booking detail is outside its list: a full screen with
        // its own way back, not a tab.
        GoRoute(
          path: '/trips/:id',
          builder: (_, state) => BookingDetailView(bookingId: state.pathParameters['id']!),
        ),
        // Saved stays moved to Profile with #42 — V2 keeps them in Account, never among
        // bookings. The old path still lands somewhere sensible.
        GoRoute(path: '/saved', redirect: (_, _) => '/profile'),
        GoRoute(path: '/login', builder: (_, _) => const LoginView()),
        GoRoute(path: '/register', builder: (_, _) => const RegisterView()),
        GoRoute(path: '/forgot-password', builder: (_, _) => const ForgotPasswordView()),
        // `?token=` is the whole credential here; the email writes this path for the web.
        GoRoute(
          path: '/reset-password',
          builder: (_, state) =>
              ResetPasswordView(token: state.uri.queryParameters['token'] ?? ''),
        ),
        // V2's path, so a failed OAuth round trip lands somewhere on both products.
        GoRoute(path: '/auth/auth-code-error', builder: (_, _) => const AuthCodeErrorView()),
        // Nothing links here yet: the account screen that carries V2's footer links is a later
        // slice. Reachable by deep link and by test until then.
        GoRoute(path: '/about', builder: (_, _) => const AboutView()),
        // The four legal documents and Help, each against its V2 counterpart (#44). Reached
        // by deep link and from within each other for now: V2 links them from its footer,
        // and mobile's account screen gains those links in a later slice.
        GoRoute(path: '/terms', builder: (_, _) => const LegalView(document: LegalDocument.terms)),
        GoRoute(path: '/privacy', builder: (_, _) => const LegalView(document: LegalDocument.privacy)),
        GoRoute(path: '/cookies', builder: (_, _) => const LegalView(document: LegalDocument.cookie)),
        GoRoute(path: '/refund', builder: (_, _) => const LegalView(document: LegalDocument.refund)),
        GoRoute(path: '/help', builder: (_, _) => const HelpView()),
      ],
    );

final GoRouter appRouter = createAppRouter();

/// The flight search for the trip being planned — where it flies from and to, the first night,
/// and the party — as V2's search link names it.
String _flightSearchFromStore() {
  final s = tripSearchStore;
  return FlightSearchQuery(
    origin: s.originCode,
    destination: s.airportCode,
    departure: isoDate(s.checkIn),
    adults: s.adults < 1 ? 1 : s.adults,
  ).toLocation();
}

/// The moment between a stored session being restored and the server saying what that account
/// still owes.
///
/// A spinner while the answer is coming, and a way out when it does not. That second part is
/// not decoration: the gate holds on an unknown status, so without it a request that fails —
/// an expired token, a dropped connection, an API that is not answering — leaves the app
/// spinning on this screen with no route to anywhere, which is exactly what it did the first
/// time it ran on a handset.
class _StartingView extends StatelessWidget {
  const _StartingView();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      body: ListenableBuilder(
        listenable: onboardingStore,
        builder: (context, _) {
          if (!onboardingStore.failed) {
            return const Center(child: CircularProgressIndicator());
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off_rounded, size: 40, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(t.errors_generic, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: onboardingStore.isLoading ? null : onboardingStore.load,
                    child: Text(t.auth_tryAgain),
                  ),
                  // The escape hatch for the case retrying cannot fix: a session this device
                  // still holds that the server will no longer accept. Signing out puts them
                  // back at the sign-in screen, which is a place they can act from.
                  TextButton(
                    onPressed: onboardingStore.isLoading ? null : authStore.logout,
                    child: Text(t.nav_signOut),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

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
      // No header on any screen. The wordmark repeated what opening the app already said,
      // and Sign in and the profile button both led where the bar's Settings slot leads —
      // see **Already Here** in CONTEXT.md. On the landing it also covered the top of the
      // photograph the stage is built around.
      //
      // The page keeps its own top inset. That inset used to be spent on the header and
      // stripped from the page below it, so with the header gone a heading sat under the
      // status bar — the overlap #61 reports.
      body: widget.navigationShell,
      // Anchored for the first-run tour (#63). Draws nothing of its own.
      bottomNavigationBar: TipAnchor(
        id: TipAnchors.bottomBar,
        child: V2BottomNav(
          activeIndex: _activeIndex,
          settingsOpen: _settingsOpen,
          onHome: () => _goBranch(_homeBranch),
          onTrips: () => _goBranch(_tripsBranch),
          onSettings: _openSettings,
        ),
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
                  AppLocalizations.of(context)!.common_settings,
                  style: TextStyle(
                    fontSize: TwText.lg.size,
                    height: TwText.lg.height,
                    fontWeight: FontWeight.w700,
                    color: dark ? Colors.white : TwPalette.slate900,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: AppLocalizations.of(context)!.common_closeSettings,
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
