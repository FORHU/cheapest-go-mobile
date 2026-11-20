import 'package:flutter/material.dart';

import 'package:cheapest_go_mobile/features/flights/components/flight_chrome.dart';
import 'package:cheapest_go_mobile/features/flights/lib/flight_utils.dart';
import 'package:cheapest_go_mobile/features/flights/models/flight_fare.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/generated/tw_palette.dart';

/// Flight by flight, each direction under its own name and run time — V2's `FlightItinerary`.
///
/// Each flight is its two ends either side of its duration; each end carries what a traveller
/// needs at that airport. A wait between two flights is a pill, because it is what someone
/// scanning a connection most needs to see.
class FlightItinerary extends StatelessWidget {
  const FlightItinerary({required this.segments, required this.sliceDurations, super.key});

  final List<FlightSegment> segments;
  final List<int> sliceDurations;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final skin = FlightSkin.of(context);
    final slices = groupSegmentsBySlice(segments);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < slices.length; i++) ...[
          if (i > 0) const SizedBox(height: 28),
          if (slices.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Wrap(
                spacing: 12,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  Text(
                    (slices.length == 2
                            ? (i == 0 ? t.flights_itinerary_outbound : t.flights_itinerary_return)
                            : t.flights_itinerary_legLabel('${i + 1}'))
                        .toUpperCase(),
                    style: TextStyle(fontSize: 12, letterSpacing: 1.56, color: skin.muted),
                  ),
                  if (slices[i].index < sliceDurations.length && sliceDurations[slices[i].index] > 0)
                    Text.rich(
                      TextSpan(
                        text: '${t.flights_itinerary_totalFlightDuration} ',
                        children: [
                          TextSpan(
                            text: formatDuration(sliceDurations[slices[i].index], t: t),
                            style: TextStyle(color: skin.text),
                          ),
                        ],
                      ),
                      style: TextStyle(fontSize: 12, color: skin.muted),
                    ),
                ],
              ),
            ),
          for (var j = 0; j < slices[i].segments.length; j++) ...[
            if (j > 0)
              ...switch (layoverMinutes(
                slices[i].segments[j - 1].arrival?.time,
                slices[i].segments[j].departure?.time,
              )) {
                null => const <Widget>[SizedBox(height: 20)],
                final minutes => [
                  const SizedBox(height: 20),
                  _LayoverNote(
                    minutes: minutes,
                    airport: slices[i].segments[j].departure?.airportName ?? slices[i].segments[j].origin,
                  ),
                  const SizedBox(height: 20),
                ],
              },
            _LegRow(segment: slices[i].segments[j]),
          ],
        ],
      ],
    );
  }
}

class _LegRow extends StatelessWidget {
  const _LegRow({required this.segment});

  final FlightSegment segment;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final skin = FlightSkin.of(context);
    final duration = formatDuration(segment.duration, t: t);
    return LayoutBuilder(
      builder: (context, constraints) {
        // `w-[38%] sm:w-[34%]` — each end takes a fixed share, the duration the rest.
        final endWidth = constraints.maxWidth * 0.38;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: endWidth,
              child: _EndColumn(
                end: segment.departure,
                code: segment.origin,
                segment: segment,
                label: t.flights_itinerary_departFrom,
                right: false,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  children: [
                    if (duration.isNotEmpty)
                      Text.rich(
                        TextSpan(
                          text: '${t.flights_itinerary_flightDuration} ',
                          children: [
                            TextSpan(
                              text: duration,
                              style: TextStyle(color: skin.text),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: skin.muted),
                      ),
                    const SizedBox(height: 6),
                    const _DottedRule(),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: endWidth,
              child: _EndColumn(
                end: segment.arrival,
                code: segment.destination,
                segment: segment,
                departedAt: segment.departure?.time,
                label: t.flights_itinerary_arriveAt,
                right: true,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// One end: the clock, the airport in full, then its facts under DEPART FROM or ARRIVE AT.
class _EndColumn extends StatelessWidget {
  const _EndColumn({
    required this.end,
    required this.code,
    required this.segment,
    required this.label,
    required this.right,
    this.departedAt,
  });

  final SegmentEnd? end;
  final String code;
  final FlightSegment segment;
  final String label;
  final bool right;
  final String? departedAt;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final skin = FlightSkin.of(context);
    final days = right ? dayOffset(departedAt, end?.time) : 0;
    final locale = Localizations.localeOf(context).toString();
    final align = right ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final textAlign = right ? TextAlign.right : TextAlign.left;
    final factStyle = TextStyle(fontSize: 12, height: 1.35, color: skin.text);

    // Kept italic when the airline has not named one, so "we don't know" reads differently
    // from a confirmed terminal.
    final terminal = end?.terminal != null && end!.terminal!.isNotEmpty
        ? Text(t.flights_itinerary_terminal(end!.terminal!), style: factStyle, textAlign: textAlign)
        : Text(
            t.flights_itinerary_terminalUnavailable,
            style: factStyle.copyWith(fontStyle: FontStyle.italic),
            textAlign: textAlign,
          );

    final facts = <Widget>[
      if (formatDateTime(end?.time, locale: locale).isNotEmpty)
        Text(
          formatDateTime(end?.time, locale: locale),
          style: factStyle,
          textAlign: textAlign,
        ),
      terminal,
      Text(
        '${cabinName(t, segment.cabinClass)} ${segment.flightNumber}'.trim(),
        style: factStyle,
        textAlign: textAlign,
      ),
      if (segment.aircraft != null && segment.aircraft!.isNotEmpty)
        Text(segment.aircraft!, style: factStyle, textAlign: textAlign),
    ];

    Widget bullet(Widget child) => Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisAlignment: right ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!right) ...[_dot(skin), const SizedBox(width: 8)],
          Flexible(child: child),
          if (right) ...[const SizedBox(width: 6), _dot(skin)],
        ],
      ),
    );

    return Column(
      crossAxisAlignment: align,
      children: [
        Text.rich(
          TextSpan(
            text: formatTime(end?.time),
            children: [
              if (days > 0)
                WidgetSpan(
                  alignment: PlaceholderAlignment.top,
                  child: Text(
                    ' +$days',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: skin.muted),
                  ),
                ),
            ],
          ),
          style: TextStyle(
            fontSize: 18,
            height: 1,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: skin.title,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          airportLabel(end, code),
          style: TextStyle(fontSize: 12, height: 1.35, color: skin.text),
          textAlign: textAlign,
        ),
        const SizedBox(height: 12),
        Text(
          label.toUpperCase(),
          style: TextStyle(fontSize: 11, letterSpacing: 1.43, color: skin.muted),
          textAlign: textAlign,
        ),
        const SizedBox(height: 4),
        for (final f in facts) bullet(f),
      ],
    );
  }

  Widget _dot(FlightSkin skin) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: skin == FlightSkin.dark ? TwPalette.slate500 : TwPalette.slate400,
      ),
    ),
  );
}

class _LayoverNote extends StatelessWidget {
  const _LayoverNote({required this.minutes, required this.airport});

  final int minutes;
  final String airport;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final skin = FlightSkin.of(context);
    final dark = skin == FlightSkin.dark;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: dark ? TwPalette.amber500.withValues(alpha: 0.15) : TwPalette.amber100,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            t.flights_itinerary_layoverLabel.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: dark ? TwPalette.amber300 : TwPalette.amber800,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          t.flights_itinerary_layoverValue(formatDuration(minutes, t: t), airport),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: skin.text),
        ),
      ],
    );
  }
}

/// `border-t border-dotted border-blue-500/70`.
class _DottedRule extends StatelessWidget {
  const _DottedRule();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 1,
    width: double.infinity,
    child: CustomPaint(painter: _DotsPainter(TwPalette.blue500.withValues(alpha: 0.7))),
  );
}

class _DotsPainter extends CustomPainter {
  _DotsPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (double x = 0; x < size.width; x += 3) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 1, 1), paint);
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) => old.color != color;
}
