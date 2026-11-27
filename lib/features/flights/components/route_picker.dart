import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:cheapest_go_mobile/features/flights/components/flight_chrome.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/search/destinations_api.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/generated/tw_palette.dart';

/// An airport a traveller can pick: V2's `DestinationSuggestion` for flights.
class AirportChoice {
  const AirportChoice({required this.code, required this.title, required this.subtitle});

  final String code;

  /// "Manila (MNL)" — what the search link carries afterwards.
  final String title;
  final String subtitle;
}

/// V2's `POPULAR_AIRPORTS`, offered until two letters are typed.
const popularAirports = <AirportChoice>[
  AirportChoice(code: 'MNL', title: 'Manila (MNL)', subtitle: 'Ninoy Aquino International Airport · Philippines'),
  AirportChoice(code: 'ICN', title: 'Seoul (ICN)', subtitle: 'Incheon International Airport · South Korea'),
  AirportChoice(code: 'NRT', title: 'Tokyo (NRT)', subtitle: 'Narita International Airport · Japan'),
  AirportChoice(code: 'KIX', title: 'Osaka (KIX)', subtitle: 'Kansai International Airport · Japan'),
  AirportChoice(code: 'SIN', title: 'Singapore (SIN)', subtitle: 'Singapore Changi Airport · Singapore'),
  AirportChoice(code: 'BKK', title: 'Bangkok (BKK)', subtitle: 'Suvarnabhumi Airport · Thailand'),
  AirportChoice(code: 'HKG', title: 'Hong Kong (HKG)', subtitle: 'Hong Kong International Airport · Hong Kong'),
  AirportChoice(code: 'DPS', title: 'Bali (DPS)', subtitle: 'Ngurah Rai International Airport · Indonesia'),
];

/// V2's `excludeOrigin`: the destination list never offers the airport being flown from.
List<AirportChoice> excludeOrigin(List<AirportChoice> options, String origin) {
  final place = origin.trim();
  if (place.isEmpty) return options;
  final code =
      RegExp(r'\(([A-Z]{3})\)$').firstMatch(place)?.group(1) ?? (RegExp(r'^[A-Z]{3}$').hasMatch(place) ? place : null);
  return options.where((o) => code != null ? o.code != code : o.title != place).toList();
}

/// Opens [AirportPicker] the way V2's `MobileSearchModal` opens: the whole screen, sliding up
/// from the bottom on a spring, on V2's slate-100 / slate-950 ground.
Future<AirportChoice?> showAirportPicker(
  BuildContext context, {
  required bool destination,
  required String origin,
  DestinationsApi? api,
}) {
  return Navigator.of(context).push<AirportChoice>(
    PageRouteBuilder(
      opaque: true,
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, _, _) => AirportPicker(destination: destination, origin: origin, api: api),
      transitionsBuilder: (_, animation, _, child) {
        // `damping: 28, stiffness: 220` — an underdamped spring that settles without a
        // visible bounce; easeOutCubic is its nearest stock curve.
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}

/// One end of the route, chosen: the popular airports until two letters are in, then the
/// airport index — debounced, with an answer that arrives late for "ma" never landing over
/// the one for "man".
class AirportPicker extends StatefulWidget {
  const AirportPicker({required this.destination, required this.origin, this.api, super.key});

  final bool destination;

  /// What the route leaves from, so the destination list can leave it out.
  final String origin;
  final DestinationsApi? api;

  @override
  State<AirportPicker> createState() => _AirportPickerState();
}

class _AirportPickerState extends State<AirportPicker> {
  final _query = TextEditingController();
  Timer? _debounce;
  int _asked = 0;
  bool _loading = false;
  List<AirportChoice> _results = const [];

  DestinationsApi get _api => widget.api ?? destinationsApi;

  bool get _typed => _query.text.trim().length >= 2;

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    _debounce?.cancel();
    if (!_typed) {
      setState(() {
        _results = const [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    final ask = ++_asked;
    _debounce = Timer(const Duration(milliseconds: 200), () async {
      final found = await _api.search(_query.text, forFlights: true);
      if (!mounted || ask != _asked) return;
      setState(() {
        _loading = false;
        // `null` is a lookup that failed, not an answer. The airports already listed are
        // still the best thing to show — clearing them turns a dropped request into an
        // empty list that reads as "no such airport".
        if (found == null) return;
        _results = [
          for (final s in found)
            if (s.iata != null)
              AirportChoice(
                code: s.iata!,
                title: '${(s.city?.isNotEmpty ?? false) ? s.city : s.name} (${s.iata})',
                subtitle: s.name,
              ),
        ];
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final skin = FlightSkin.of(context);
    final offered = _typed ? _results : popularAirports;
    final options = widget.destination ? excludeOrigin(offered, widget.origin) : offered;

    return Scaffold(
      backgroundColor: dark ? TwPalette.slate950 : TwPalette.slate100,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: t.common_goBack,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(LucideIcons.arrowLeft, size: 18, color: skin.title),
                  ),
                  Expanded(
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: skin.field,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: skin.hairline),
                        boxShadow: [
                          BoxShadow(color: dark ? const Color(0x2EFFFFFF) : const Color(0x24111111), spreadRadius: 2),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            widget.destination ? LucideIcons.planeLanding : LucideIcons.planeTakeoff,
                            size: 16,
                            color: skin.muted,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _query,
                              autofocus: true,
                              onChanged: _onChanged,
                              textInputAction: TextInputAction.search,
                              onSubmitted: (_) {
                                if (_typed && options.isNotEmpty) Navigator.of(context).pop(options.first);
                              },
                              style: TextStyle(fontSize: 15, color: skin.title),
                              cursorColor: skin.title,
                              decoration: InputDecoration(
                                isCollapsed: true,
                                border: InputBorder.none,
                                hintText: t.landing_search_placeholder_airport,
                                hintStyle: TextStyle(color: skin.muted),
                                semanticCounterText: widget.destination ? t.landing_search_to : t.landing_search_from,
                              ),
                            ),
                          ),
                          if (_loading)
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 1.5, color: skin.title),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                decoration: BoxDecoration(
                  color: skin.menu,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: skin.hairline),
                ),
                clipBehavior: Clip.antiAlias,
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  children: [
                    if (!_typed)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 6, 18, 4),
                        child: Text(
                          t.search_popularAirports.toUpperCase(),
                          style: TextStyle(fontSize: 11, letterSpacing: 1.43, color: skin.muted),
                        ),
                      ),
                    if (_typed && !_loading && options.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        child: Text(
                          t.search_noAirportsMatch(_query.text.trim()),
                          style: TextStyle(fontSize: 13, color: skin.muted),
                        ),
                      ),
                    for (final o in options)
                      InkWell(
                        onTap: () => Navigator.of(context).pop(o),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 28,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(color: skin.hover, borderRadius: BorderRadius.circular(6)),
                                child: Text(
                                  o.code,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                    color: skin.title,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      o.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: skin.title),
                                    ),
                                    Text(
                                      o.subtitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 11, color: skin.muted),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
