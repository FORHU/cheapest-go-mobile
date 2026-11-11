import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:cheapest_go_mobile/features/home/components/stage_chrome.dart';
import 'package:cheapest_go_mobile/features/home/components/step_parts.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/search/destinations_api.dart';
import 'package:cheapest_go_mobile/shared/stores/trip_search_store.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/generated/tw_palette.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/generated/tw_scale.dart';

/// V2's landing search, one question at a time. See #38 and `step-search.tsx`.
///
/// Every word here comes from the generated ARB. The first version of this file asked "Where
/// are you going?" as a string literal, which was wrong twice over: the parity checklist
/// forbids literal copy, and V2 actually asks "Where do you want to stay?". The strings were
/// missing because `search.steps` was added to V2 *after* the commit this app was pinned to —
/// the pin was bumped and the copy regenerated rather than invented here.
enum StepMode { stays, flights }

/// The field's edge on the Stage: a hairline on the glass at the panel's inner radius, in
/// place of the theme's outline — which is drawn for a field on a page, not on a photograph.
final _fieldEdge = OutlineInputBorder(
    borderRadius: BorderRadius.circular(TwRadius.xl),
    borderSide: const BorderSide(color: Color(0x1FFFFFFF)),
);

const _steps = <StepMode, List<_StepId>>{
    StepMode.stays: [_StepId.where, _StepId.when, _StepId.who],
    StepMode.flights: [_StepId.trip, _StepId.from, _StepId.to, _StepId.when, _StepId.who],
};

enum _StepId { trip, where, from, to, when, who }

/// Enough to choose from, few enough that the heading, tabs, question, list and the button
/// under it still fit the screen. V2 caps it at the same number for the same reason.
const _maxOptions = 3;

/// The places offered before anything is typed, as `stages.ts` lists them. The country names
/// sit beside the cities there too — labels on a constant, not translated copy.
const _picks = [
    (city: 'Seoul', country: 'South Korea', image: 'assets/images/destinations/seoul.webp'),
    (city: 'Tokyo', country: 'Japan', image: 'assets/images/destinations/tokyo.webp'),
    (city: 'Bali', country: 'Indonesia', image: 'assets/images/destinations/bali.webp'),
    (
        city: 'Oklahoma City',
        country: 'United States',
        image: 'assets/images/destinations/downtown-dusk.webp',
    ),
];

class StepSearch extends StatefulWidget {
    const StepSearch({required this.mode, super.key});

    final StepMode mode;

    @override
    State<StepSearch> createState() => _StepSearchState();
}

class _StepSearchState extends State<StepSearch> {
    int _index = 0;

    DestinationSuggestion? _place;
    DestinationSuggestion? _origin;
    DestinationSuggestion? _destination;
    bool? _roundTrip;
    DateTimeRange? _dates;
    DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
    int _adults = 2;
    int _children = 0;

    final _query = TextEditingController();
    List<DestinationSuggestion> _options = const [];
    Timer? _debounce;
    bool _looking = false;
    bool _searched = false;

    List<_StepId> get _flow => _steps[widget.mode]!;
    _StepId get _step => _flow[_index];

    @override
    void dispose() {
        _debounce?.cancel();
        _query.dispose();
        super.dispose();
    }

    /// Typing does not ask on every keystroke: the destinations endpoint reaches a supplier.
    void _onTyped(String value, {required bool airports}) {
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 250), () async {
            setState(() => _looking = true);
            final found = await destinationsApi.search(value, forFlights: airports);
            if (!mounted) return;
            setState(() {
                _options = found.take(_maxOptions).toList();
                _looking = false;
                _searched = value.trim().length >= 2;
            });
        });
    }

    bool get _answered => switch (_step) {
        _StepId.trip => _roundTrip != null,
        _StepId.where => _place != null,
        _StepId.from => _origin != null,
        _StepId.to => _destination != null,
        // V2 says so outright: optional, and it will pick dates for you.
        _StepId.when => true,
        _StepId.who => true,
    };

    void _next() {
        if (_index < _flow.length - 1) {
            setState(() {
                _index++;
                _query.clear();
                _options = const [];
                _searched = false;
            });
            return;
        }
        _finish();
    }

    void _finish() {
        final store = tripSearchStore;
        if (_dates != null) store.setDates(_dates!.start, _dates!.end);
        store.setAdults(_adults);

        if (widget.mode == StepMode.stays) {
            store.setDestination(_place!);
            context.go('/hotels');
        } else {
            if (_origin?.iata != null) store.setOrigin(_origin!.iata!);
            if (_destination?.iata != null) store.setAirport(_destination!.iata!);
            context.go('/flights');
        }
    }

    /// The line under the button: what has been chosen, or that this step can be skipped.
    String? _note(AppLocalizations t) {
        if (_step == _StepId.when) return t.search_steps_datesOptional;
        final chosen = switch (_step) {
            _StepId.where => _place,
            _StepId.from => _origin,
            _StepId.to => _destination,
            _ => null,
        };
        return chosen == null ? null : t.search_steps_selected(chosen.name);
    }

    /// Tapping a day either starts a stay or closes one.
    ///
    /// The first tap sets both ends, so a single night is a single tap; a later tap after that
    /// day extends to it, and a tap before it starts again from there. A traveller picking
    /// dates rarely means "clear what I chose", so nothing here clears.
    DateTimeRange _extendRange(DateTime day) {
        final current = _dates;
        if (current == null || !day.isAfter(current.start) || current.end != current.start) {
            return DateTimeRange(start: day, end: day);
        }
        return DateTimeRange(start: current.start, end: day);
    }

    void _pick(DestinationSuggestion option) {
        setState(() {
            switch (_step) {
                case _StepId.where:
                    _place = option;
                case _StepId.from:
                    _origin = option;
                default:
                    _destination = option;
            }
            _query.text = option.name;
            _options = const [];
        });
    }

    @override
    Widget build(BuildContext context) {
        final t = AppLocalizations.of(context)!;
        // Always on the showcase photograph, whatever the app theme: V2 docks this panel on
        // the stage, not on the page, so its chrome is light-on-dark either way.
        const dark = true;

        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                _StepTrail(flow: _flow, index: _index, t: t, dark: dark),
                SizedBox(height: TwSpace.of(4)),
                Text(
                    _question(t),
                    style: TextStyle(
                        fontFamily: TwFonts.display,
                        fontSize: TwText.xl.size,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                    ),
                ),
                SizedBox(height: TwSpace.of(3)),
                _body(context, t, dark),
                SizedBox(height: TwSpace.of(4)),
                // Wrap, not Row: V2 sets `flexWrap: wrap` on this pair, and it is needed —
                // "Back" beside "Next: travellers" is four pixels too wide for a phone, and a
                // Row answers that with the striped overflow bar rather than a second line.
                Wrap(
                    spacing: TwSpace.of(3),
                    runSpacing: TwSpace.of(3),
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                        if (_index > 0)
                            GlassPill(
                                label: t.search_steps_back,
                                icon: Icons.arrow_back_rounded,
                                onPressed: () => setState(() => _index--),
                            ),
                        GradientPill(
                            label: _nextLabel(t),
                            icon: _index == _flow.length - 1 ? Icons.search_rounded : null,
                            trailingIcon: _index == _flow.length - 1 ? null : Icons.arrow_forward_rounded,
                            onPressed: _answered ? _next : null,
                        ),
                    ],
                ),
                if (_note(t) case final note?) ...[SizedBox(height: TwSpace.of(2)), StageNote(note)],
            ],
        );
    }

    String _question(AppLocalizations t) => switch (_step) {
        _StepId.trip => t.search_steps_askTrip,
        _StepId.where => t.search_steps_askStay,
        _StepId.from => t.search_steps_askFrom,
        _StepId.to => t.search_steps_askTo,
        _StepId.when => t.search_steps_askStayDates,
        _StepId.who => t.search_steps_who,
    };

    /// V2 names the step you are going to, not the one you are on — "Next: dates".
    String _nextLabel(AppLocalizations t) {
        if (_index == _flow.length - 1) {
            return widget.mode == StepMode.stays
                    ? t.search_steps_searchStays
                    : t.search_steps_searchFlights;
        }
        return switch (_flow[_index + 1]) {
            _StepId.when => t.search_steps_nextDates,
            _StepId.from => t.search_steps_nextOrigin,
            _StepId.to => t.search_steps_nextDestination,
            _ =>
                widget.mode == StepMode.flights ? t.search_steps_nextTravellers : t.search_steps_nextGuests,
        };
    }

    Widget _body(BuildContext context, AppLocalizations t, bool dark) {
        switch (_step) {
            // Two cards side by side, each with its icon, title and the line under it — the
            // arrow for a one-way, the swap for a return.
            case _StepId.trip:
                // Both cards stand as tall as the taller one, so the pair reads as a pair
                // however the notes wrap. `stretch` alone cannot do that here: this Row sits
                // in a scrolling Column, where its height is unbounded, and stretching into
                // an unbounded height throws during layout — which on a device is not an
                // error message but a frozen, half-painted screen. IntrinsicHeight measures
                // the taller card first and gives the Row a real height to stretch into.
                return IntrinsicHeight(
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                            for (final (round, icon, title, note) in [
                                (false, Icons.arrow_forward_rounded, t.search_oneWay, t.search_steps_oneWayNote),
                                (true, Icons.swap_horiz_rounded, t.search_roundTrip, t.search_steps_roundTripNote),
                            ])
                                Expanded(
                                    child: Padding(
                                        padding: EdgeInsets.only(right: round ? 0 : TwSpace.of(3)),
                                        child: GestureDetector(
                                            onTap: () => setState(() => _roundTrip = round),
                                            child: GlassPanel(
                                                highlighted: _roundTrip == round,
                                                child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                        Container(
                                                            width: 32,
                                                            height: 32,
                                                            alignment: Alignment.center,
                                                            decoration: BoxDecoration(
                                                                color: const Color(0x1FFFFFFF),
                                                                borderRadius: BorderRadius.circular(TwRadius.lg),
                                                            ),
                                                            child: Icon(icon, size: 16, color: Colors.white),
                                                        ),
                                                        SizedBox(height: TwSpace.of(3)),
                                                        Text(
                                                            title,
                                                            style: TextStyle(
                                                                fontSize: TwText.base.size,
                                                                fontWeight: FontWeight.w700,
                                                                color: Colors.white,
                                                            ),
                                                        ),
                                                        SizedBox(height: TwSpace.of(1)),
                                                        Text(
                                                            note,
                                                            style: TextStyle(
                                                                fontSize: TwText.xs.size,
                                                                height: 1.4,
                                                                color: Colors.white60,
                                                            ),
                                                        ),
                                                    ],
                                                ),
                                            ),
                                        ),
                                    ),
                                ),
                        ],
                    ),
                );

            // One glass card holding the field and the places under it, rather than a field
            // on the photograph with a list floating beneath it.
            case _StepId.where:
            case _StepId.from:
            case _StepId.to:
                final airports = _step != _StepId.where;
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                        GlassPanel(
                            padding: EdgeInsets.all(TwSpace.of(3)),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                    TextField(
                                        controller: _query,
                                        autocorrect: false,
                                        style: const TextStyle(color: Colors.white),
                                        decoration: InputDecoration(
                                            isDense: true,
                                            hintText: airports
                                                    ? t.search_cityAirportPlaceholder
                                                    : t.search_steps_placePlaceholder,
                                            hintStyle: const TextStyle(color: Colors.white54),
                                            prefixIcon: const Icon(Icons.search_rounded, size: 18),
                                            prefixIconColor: Colors.white70,
                                            // The app theme fills every input with the page
                                            // surface, which on the Stage is white over the
                                            // photograph — the field read as a solid white
                                            // block. The Stage takes none of the theme, so it
                                            // states its own fill and edge here.
                                            filled: true,
                                            fillColor: const Color(0x14FFFFFF),
                                            contentPadding: EdgeInsets.symmetric(
                                                horizontal: TwSpace.of(3),
                                                vertical: TwSpace.of(3),
                                            ),
                                            border: _fieldEdge,
                                            enabledBorder: _fieldEdge,
                                            focusedBorder: _fieldEdge,
                                        ),
                                        onChanged: (v) => _onTyped(v, airports: airports),
                                    ),
                                    for (final option in _options) ...[
                                        Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
                                        PlaceRow(option: option, onTap: () => _pick(option)),
                                    ],
                                    if (_looking)
                                        Padding(
                                            padding: EdgeInsets.only(top: TwSpace.of(3)),
                                            child: const Center(
                                                child: SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child: CircularProgressIndicator(strokeWidth: 2),
                                                ),
                                            ),
                                        ),
                                    if (_searched && _options.isEmpty && !_looking)
                                        Padding(
                                            padding: EdgeInsets.only(top: TwSpace.of(3)),
                                            child: StageNote(t.search_steps_noPlaceMatch(_query.text)),
                                        ),
                                ],
                            ),
                        ),
                        // Before anything is typed, the places we promote — as V2 offers them.
                        if (_step == _StepId.where && _options.isEmpty && _query.text.isEmpty) ...[
                            SizedBox(height: TwSpace.of(4)),
                            Text(
                                t.search_steps_orPickOne.toUpperCase(),
                                style: TextStyle(
                                    fontSize: TwText.xs.size,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: TwText.xs.size * 0.1,
                                    color: Colors.white60,
                                ),
                            ),
                            SizedBox(height: TwSpace.of(2)),
                            _PickGrid(
                                // V2's `pickTile` sets the destination outright and marks the
                                // field as untyped — it never looks the city up. Searching for
                                // it instead made a promoted place depend on the destinations
                                // endpoint answering, and when it did not the tile a person had
                                // just tapped came back as "No places match Seoul".
                                onPick: (city) => setState(() {
                                    _place = DestinationSuggestion(
                                        id: city,
                                        kind: DestinationKind.city,
                                        name: city,
                                    );
                                    _query.text = city;
                                    _options = const [];
                                    _searched = false;
                                    _looking = false;
                                    _debounce?.cancel();
                                }),
                            ),
                        ],
                    ],
                );

            // A month at a time, in a card: V2 shows the calendar itself rather than a button
            // that opens one.
            case _StepId.when:
                return GlassPanel(
                    padding: EdgeInsets.all(TwSpace.of(3)),
                    child: MonthCalendar(
                        month: _month,
                        range: _dates,
                        onMonth: (m) => setState(() => _month = m),
                        onPick: (d) => setState(() => _dates = _extendRange(d)),
                    ),
                );

            case _StepId.who:
                return GlassPanel(
                    padding: EdgeInsets.symmetric(horizontal: TwSpace.of(4), vertical: TwSpace.of(2)),
                    child: Column(
                        children: [
                            Counter(
                                label: t.landing_search_adults,
                                sublabel: '18+',
                                value: _adults,
                                fewerLabel: t.search_steps_fewerAdults,
                                moreLabel: t.search_steps_moreAdults,
                                onChanged: (v) => setState(() => _adults = v.clamp(1, 9)),
                            ),
                            Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
                            Counter(
                                label: t.landing_search_children,
                                sublabel: '0–17',
                                value: _children,
                                fewerLabel: t.search_steps_fewerChildren,
                                moreLabel: t.search_steps_moreChildren,
                                onChanged: (v) => setState(() => _children = v.clamp(0, 9)),
                            ),
                        ],
                    ),
                );
        }
    }
}

/// Where you are in the questions: ① Where — ② When — ③ Who.
class _StepTrail extends StatelessWidget {
    const _StepTrail({required this.flow, required this.index, required this.t, required this.dark});

    final List<_StepId> flow;
    final int index;
    final AppLocalizations t;
    final bool dark;

    String _label(_StepId id) => switch (id) {
        _StepId.trip => t.search_steps_trip,
        _StepId.where => t.search_steps_where,
        _StepId.from => t.search_steps_from,
        _StepId.to => t.search_steps_to,
        _StepId.when => t.search_steps_when,
        _StepId.who => t.search_steps_who,
    };

    @override
    Widget build(BuildContext context) {
        return Semantics(
            label: t.search_steps_navLabel,
            child: Row(
                children: [
                    for (var i = 0; i < flow.length; i++) ...[
                        if (i > 0)
                            Container(
                                // V2: `width: clamp(12px, 4vw, 40px)`, and it does not stretch — the trail
                                // hugs its steps at the left rather than spanning the screen.
                                width: (MediaQuery.sizeOf(context).width * 0.04).clamp(12.0, 40.0),
                                height: 1,
                                margin: EdgeInsets.symmetric(horizontal: TwSpace.of(2.5)),
                                color: dark ? const Color(0x33FFFFFF) : TwPalette.slate200,
                            ),
                        _TrailStep(
                            number: i + 1,
                            label: _label(flow[i]),
                            current: i == index,
                            done: i < index,
                            dark: dark,
                            // V2 hides every label but the one being answered below 420px: five named
                            // steps do not fit a phone, and the row overflowed — which Flutter draws as
                            // the striped bar and reports as a layout error on every frame.
                            named: i == index || MediaQuery.sizeOf(context).width > 420,
                        ),
                    ],
                ],
            ),
        );
    }
}

class _TrailStep extends StatelessWidget {
    const _TrailStep({
        required this.number,
        required this.label,
        required this.current,
        required this.done,
        required this.dark,
        required this.named,
    });

    final int number;
    final String label;
    final bool current;

    /// Whether the step's name is drawn beside its number. False for the steps a phone leaves
    /// as numbers alone — see the trail above.
    final bool named;

    /// Answered already: the reference ticks these rather than leaving the number.
    final bool done;
    final bool dark;

    @override
    Widget build(BuildContext context) {
        final dim = dark ? TwPalette.slate400 : TwPalette.slate500;
        return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
                Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: current || done ? TwPalette.blue600 : Colors.transparent,
                        border: current || done ? null : Border.all(color: dim),
                    ),
                    child: Text(
                        '$number',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: current ? Colors.white : dim,
                        ),
                    ),
                ),
                if (named) ...[
                    SizedBox(width: TwSpace.of(1.5)),
                    Text(
                        label,
                        style: TextStyle(
                            fontSize: TwText.sm.size,
                            fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                            color: current ? (dark ? Colors.white : TwPalette.slate900) : dim,
                        ),
                    ),
                ],
            ],
        );
    }
}

/// The four promoted places, two up.
class _PickGrid extends StatelessWidget {
    const _PickGrid({required this.onPick});

    final ValueChanged<String> onPick;

    @override
    Widget build(BuildContext context) {
        return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: TwSpace.of(2),
            crossAxisSpacing: TwSpace.of(2),
            childAspectRatio: 1.6,
            children: [
                for (final pick in _picks)
                    InkWell(
                        onTap: () => onPick(pick.city),
                        borderRadius: BorderRadius.circular(TwRadius.xl),
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(TwRadius.xl),
                            child: Stack(
                                fit: StackFit.expand,
                                children: [
                                    Image.asset(pick.image, fit: BoxFit.cover),
                                    // The photograph alone leaves the names unreadable over a
                                    // bright sky, so they sit on a wash from the foot up.
                                    const DecoratedBox(
                                        decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                                begin: Alignment.bottomCenter,
                                                end: Alignment.topCenter,
                                                colors: [Color(0xCC000000), Color(0x00000000)],
                                            ),
                                        ),
                                    ),
                                    Padding(
                                        padding: EdgeInsets.all(TwSpace.of(2)),
                                        child: Column(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                                Text(
                                                    pick.city,
                                                    style: TextStyle(
                                                        fontSize: TwText.sm.size,
                                                        fontWeight: FontWeight.w700,
                                                        color: Colors.white,
                                                    ),
                                                ),
                                                Text(
                                                    pick.country,
                                                    style: TextStyle(fontSize: TwText.xs.size, color: Colors.white70),
                                                ),
                                            ],
                                        ),
                                    ),
                                ],
                            ),
                        ),
                    ),
            ],
        );
    }
}
