import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:cheapest_go_mobile/features/trips/api/bookings_source.dart';
import 'package:cheapest_go_mobile/features/trips/components/booking_card.dart';
import 'package:cheapest_go_mobile/features/trips/lib/booking_search.dart';
import 'package:cheapest_go_mobile/features/trips/models/trip_booking.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/components/app_buttons.dart';
import 'package:cheapest_go_mobile/shared/components/ui_kit.dart';
import 'package:cheapest_go_mobile/shared/stores/app_refresh.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/app_colors.dart';

/// **My Bookings** — everything the traveller has booked. See #42 and ADR-0003.
///
/// What this replaced: a screen rendering a list in SharedPreferences, seeded with five
/// invented past trips. It now shows what api-v2 confirms and nothing else, so a card here
/// is a reservation a supplier is actually holding.
///
/// V2's four tabs, counted, with one search across all of them. No Upcoming/Past split and no
/// grouping by airport — V2 has neither, and this screen follows V2.
enum BookingTab { all, hotels, flights, golf }

/// English literals, as in V2's `trips-list.tsx`, which holds the four labels as a constant
/// rather than in its locale files. The `trips_tabs_*` keys in the ARBs are an older V2's and
/// name different tabs; translating only here would put the two products out of step.
const _tabLabels = {
    BookingTab.all: 'All',
    BookingTab.hotels: 'Hotels',
    BookingTab.flights: 'Flights',
    BookingTab.golf: 'Golf',
};

class TripsView extends StatefulWidget {
    const TripsView({this.initialTab = BookingTab.all, super.key});

    final BookingTab initialTab;

    @override
    State<TripsView> createState() => _TripsViewState();
}

class _TripsViewState extends State<TripsView> {
    late BookingTab _tab = widget.initialTab;
    final _query = TextEditingController();

    Future<BookingsPage>? _load;

    @override
    void initState() {
        super.initState();
        _reload();
        // The tab's state is kept alive by the shell, so `initState` runs once an app launch.
        // Without this, a booking made on the web — or on this phone, in another session —
        // would never appear. The staleness policy is `app_refresh.dart`'s and unchanged;
        // this only makes My Bookings obey it, as the old store-backed screen did for free.
        appDataRevision.addListener(_reload);
    }

    @override
    void dispose() {
        appDataRevision.removeListener(_reload);
        _query.dispose();
        super.dispose();
    }

    void _reload() {
        // The call is made first and the state set from it. A `setState` whose body returns a
        // Future is an error: the arrow form here read as async and threw on first build.
        final loading = bookingsSource.myBookings();
        // A block, not an arrow: `() => _load = loading` *returns* the Future it assigns, and
        // setState rejects a callback that returns one.
        setState(() {
            _load = loading;
        });
    }

    @override
    Widget build(BuildContext context) {
        final t = AppLocalizations.of(context)!;
        final c = context.colors;

        return SafeArea(
            bottom: false,
            child: FutureBuilder<BookingsPage>(
                future: _load,
                builder: (context, snapshot) {
                    final Widget body;
                    if (snapshot.connectionState == ConnectionState.waiting) {
                        body = const _Loading();
                    } else if (snapshot.error is NotSignedIn) {
                        // Not a failure: they simply have not said who they are.
                        body = _SignInPrompt(t: t, onSignIn: () => context.push('/login'));
                    } else if (snapshot.hasError || !snapshot.hasData) {
                        body = _LoadFailed(t: t, onRetry: _reload);
                    } else {
                        body = _Results(
                            page: snapshot.data!,
                            tab: _tab,
                            query: _query.text,
                            t: t,
                        );
                    }

                    return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        children: [
                            Text(
                                t.trips_myTrips,
                                style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 26),
                            ),
                            const SizedBox(height: 2),
                            Text(
                                t.trips_pageSubtitle,
                                style: TextStyle(fontSize: 13, color: c.textMuted),
                            ),
                            const SizedBox(height: 14),
                            _Tabs(
                                selected: _tab,
                                counts: _countsOf(snapshot.data),
                                onChanged: (tab) => setState(() => _tab = tab),
                            ),
                            const SizedBox(height: 12),
                            _SearchField(
                                controller: _query,
                                hint: t.trips_search_placeholder,
                                onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 16),
                            body,
                        ],
                    );
                },
            ),
        );
    }

    /// The counts on the pills. Null while loading, so the tabs show no number rather than a
    /// zero that is about to be wrong.
    Map<BookingTab, int>? _countsOf(BookingsPage? page) {
        if (page == null) return null;
        final terms = queryTerms(_query.text);
        List<TripBooking> matching(Iterable<TripBooking> rows) =>
            rows.where((b) => matchesTerms(b.searchText, terms)).toList();

        final hotels = matching(page.bookings.whereType<HotelStayBooking>());
        final flights = matching(page.bookings.whereType<FlightTripBooking>());
        final golf = matching(page.golf);
        return {
            BookingTab.all: hotels.length + flights.length + golf.length,
            BookingTab.hotels: hotels.length,
            BookingTab.flights: flights.length,
            BookingTab.golf: golf.length,
        };
    }
}

// ─── Tabs ─────────────────────────────────────────────────────────────────────

class _Tabs extends StatelessWidget {
    const _Tabs({required this.selected, required this.counts, required this.onChanged});

    final BookingTab selected;
    final Map<BookingTab, int>? counts;
    final ValueChanged<BookingTab> onChanged;

    @override
    Widget build(BuildContext context) {
        return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            // The list's own gutter, repeated inside the scroller, so the last tab clears
            // the edge of the screen instead of being sliced by it.
            padding: const EdgeInsets.only(right: 16),
            clipBehavior: Clip.none,
            child: Row(
                children: [
                    for (final tab in BookingTab.values) ...[
                        _TabPill(
                            label: _tabLabels[tab]!,
                            count: counts?[tab],
                            selected: tab == selected,
                            onTap: () => onChanged(tab),
                        ),
                        if (tab != BookingTab.values.last) const SizedBox(width: 8),
                    ],
                ],
            ),
        );
    }
}

class _TabPill extends StatelessWidget {
    const _TabPill({
        required this.label,
        required this.count,
        required this.selected,
        required this.onTap,
    });

    final String label;
    final int? count;
    final bool selected;
    final VoidCallback onTap;

    @override
    Widget build(BuildContext context) {
        final c = context.colors;
        final content = Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                    Text(
                        label,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : c.textPrimary,
                        ),
                    ),
                    if (count != null) ...[
                        const SizedBox(width: 6),
                        Text(
                            '$count',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: selected ? Colors.white70 : c.textMuted,
                            ),
                        ),
                    ],
                ],
            ),
        );

        if (!selected) {
            return Material(
                color: c.surface,
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(999),
                    child: content,
                ),
            );
        }

        // The chosen tab takes the brand gradient, as a chosen sort does in V2.
        return Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(999),
                child: Ink(
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF06B6D4)],
                        ),
                        borderRadius: BorderRadius.circular(999),
                    ),
                    child: content,
                ),
            ),
        );
    }
}

// ─── Search ───────────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
    const _SearchField({required this.controller, required this.hint, required this.onChanged});

    final TextEditingController controller;
    final String hint;
    final ValueChanged<String> onChanged;

    @override
    Widget build(BuildContext context) {
        final c = context.colors;
        return TextField(
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            // 16px: any smaller and the field is hard to read at arm's length.
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
                hintText: hint,
                filled: true,
                fillColor: c.surface,
                prefixIcon: Icon(Icons.search_rounded, size: 20, color: c.textMuted),
                suffixIcon: controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                            controller.clear();
                            onChanged('');
                        },
                    ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide.none,
                ),
            ),
        );
    }
}

// ─── Results ──────────────────────────────────────────────────────────────────

class _Results extends StatelessWidget {
    const _Results({required this.page, required this.tab, required this.query, required this.t});

    final BookingsPage page;
    final BookingTab tab;
    final String query;
    final AppLocalizations t;

    @override
    Widget build(BuildContext context) {
        final terms = queryTerms(query);
        final rows = _rows.where((b) => matchesTerms(b.searchText, terms)).toList();

        if (rows.isEmpty) {
            return terms.isEmpty
                ? _Empty(t: t, tab: tab)
                : _NoMatch(t: t, query: query);
        }

        return Column(
            children: [
                // A golf outage costs the golf rows and nothing else, so it is said where the
                // rows would have been rather than replacing the whole screen.
                if (page.golfFailed && (tab == BookingTab.all || tab == BookingTab.golf))
                    Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _Notice(
                            message: "Golf bookings couldn't be loaded just now.",
                        ),
                    ),
                for (final booking in rows)
                    Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: BookingCard(
                            booking: booking,
                            onOpen: () => context.push('/trips/${booking.id}'),
                            // The e-ticket lives on the detail screen, beside the passenger
                            // and the ticket number it belongs to.
                            onETicket: () => context.push('/trips/${booking.id}'),
                        ),
                    ),
            ],
        );
    }

    List<TripBooking> get _rows => switch (tab) {
        BookingTab.all => page.all,
        BookingTab.hotels => page.bookings.whereType<HotelStayBooking>().toList(),
        BookingTab.flights => page.bookings.whereType<FlightTripBooking>().toList(),
        BookingTab.golf => page.golf,
    };
}

// ─── States ───────────────────────────────────────────────────────────────────

class _Loading extends StatelessWidget {
    const _Loading();

    @override
    Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.only(top: 48),
        child: Center(child: CircularProgressIndicator()),
    );
}

class _Empty extends StatelessWidget {
    const _Empty({required this.t, required this.tab});

    final AppLocalizations t;
    final BookingTab tab;

    @override
    Widget build(BuildContext context) => EmptyState(
        icon: Icons.luggage_outlined,
        title: tab == BookingTab.golf ? t.trips_golfCard_empty : t.trips_emptyState_allTitle,
        message: t.trips_emptyHint,
        action: AppGradientButton(
            label: t.trips_emptyState_otherDesc,
            height: 46,
            onPressed: () => context.go('/'),
        ),
    );
}

class _NoMatch extends StatelessWidget {
    const _NoMatch({required this.t, required this.query});

    final AppLocalizations t;
    final String query;

    @override
    Widget build(BuildContext context) => EmptyState(
        icon: Icons.search_off_rounded,
        title: t.trips_search_noMatch(query),
        message: t.trips_search_noMatchHint,
    );
}

class _LoadFailed extends StatelessWidget {
    const _LoadFailed({required this.t, required this.onRetry});

    final AppLocalizations t;
    final VoidCallback onRetry;

    @override
    Widget build(BuildContext context) => EmptyState(
        icon: Icons.cloud_off_rounded,
        title: t.trips_loadFailed_title,
        message: '',
        action: AppGradientButton(label: t.trips_loadFailed_retry, height: 46, onPressed: onRetry),
    );
}

/// Signed out there is nothing to show and nothing wrong. api-v2 ties a booking to an
/// account, so this asks rather than reporting an error.
class _SignInPrompt extends StatelessWidget {
    const _SignInPrompt({required this.t, required this.onSignIn});

    final AppLocalizations t;
    final VoidCallback onSignIn;

    @override
    Widget build(BuildContext context) => EmptyState(
        icon: Icons.lock_outline_rounded,
        title: t.checkout_signInToComplete,
        message: t.trips_emptyHint,
        action: AppGradientButton(label: t.nav_signIn, height: 46, onPressed: onSignIn),
    );
}

class _Notice extends StatelessWidget {
    const _Notice({required this.message});

    final String message;

    @override
    Widget build(BuildContext context) {
        final c = context.colors;
        return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: c.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
                children: [
                    Icon(Icons.cloud_off_rounded, size: 16, color: c.textMuted),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(message, style: TextStyle(fontSize: 12.5, color: c.textMuted)),
                    ),
                ],
            ),
        );
    }
}
