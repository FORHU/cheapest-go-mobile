import 'package:flutter/material.dart';
import 'package:cheapest_go_mobile/features/map/models/map_models.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/components/app_buttons.dart';
import 'package:cheapest_go_mobile/shared/components/ui_kit.dart';
import 'package:cheapest_go_mobile/shared/flights/flight_status.dart';
import 'package:cheapest_go_mobile/shared/flights/offline_route_maps.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/app_colors.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/app_radius.dart';
import 'package:cheapest_go_mobile/shared/utils/format.dart';

/// Where the plane on the map comes from.
enum PositionSource {
  /// The phone's GPS (works in airplane mode, best by a window).
  gps,

  /// Estimated from the departure time and route.
  schedule,

  /// Estimated, and location access was refused.
  scheduleNoPermission,
}

/// Tracker panel for one booked flight: its status before, during and after
/// the flight, where its position comes from, and its offline map.
class FlightTelemetryHud extends StatelessWidget {
  const FlightTelemetryHud({
    required this.flight,
    required this.status,
    required this.positionSource,
    required this.offlineMap,
    required this.onDownloadMap,
    required this.onExitTracking,
    this.onNextFlight,
    this.onViewDestinationHub,
    this.onSimulate,
    this.simulating = false,
    this.flightLabel,
    super.key,
  });

  final TrackedFlight flight;
  final FlightStatus status;
  final PositionSource positionSource;
  final OfflineMapStatus offlineMap;
  final VoidCallback onDownloadMap;
  final VoidCallback onExitTracking;

  /// Null when there is only one flight to track.
  final VoidCallback? onNextFlight;

  /// Null when the arrival airport has no stays or golf in the catalogue.
  final VoidCallback? onViewDestinationHub;

  /// Demo tools only (see `kDemoTools`): replay the flight fast, or stop the replay.
  final VoidCallback? onSimulate;
  final bool simulating;

  /// e.g. `1 of 2`.
  final String? flightLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final f = flight.flight;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surfaceElevated,
        borderRadius: AppRadius.brSheet,
        border: Border.all(color: c.border),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 8))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: c.secondary, borderRadius: AppRadius.brSm),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flight_rounded, size: 14, color: c.accent),
                    const SizedBox(width: 4),
                    Text(f.flightNo, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: c.onSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.airline, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    Text(
                      [_phaseLabel(status.phase, AppLocalizations.of(context)!), ?flightLabel].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: c.textMuted),
                    ),
                  ],
                ),
              ),
              if (onNextFlight != null)
                IconButton(tooltip: AppLocalizations.of(context)!.mobile_tracker_nextFlight, onPressed: onNextFlight, icon: Icon(Icons.skip_next_rounded, color: c.accent)),
              CircleIconButton(
                icon: Icons.close_rounded,
                tooltip: AppLocalizations.of(context)!.mobile_tracker_stopTracking,
                onPressed: onExitTracking,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _RouteBar(flight: flight, progress: status.progress),
          const SizedBox(height: 12),
          ..._phaseBody(context),
          const SizedBox(height: 10),
          _OfflineMapRow(status: offlineMap, onDownload: onDownloadMap),
          if (onSimulate != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onSimulate,
                icon: Icon(simulating ? Icons.stop_rounded : Icons.fast_forward_rounded, size: 18),
                label: Text(
                  simulating
                      ? AppLocalizations.of(context)!.mobile_tracker_stopSimulation
                      : AppLocalizations.of(context)!.mobile_tracker_simulate,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _phaseBody(BuildContext context) {
    final c = context.colors;
    final t = AppLocalizations.of(context)!;
    final f = flight.flight;
    final depLocal = f.departureUtc.add(flight.origin.utcOffset);
    final arrLocal = f.arrivalUtc.add(flight.destination.utcOffset);
    String clock(DateTime t) => formatTeeTime('${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');

    switch (status.phase) {
      case FlightPhase.scheduled:
      case FlightPhase.boarding:
        return [
          Text(
            status.phase == FlightPhase.boarding
                ? t.mobile_tracker_boardingDepartsIn(_span(t, status.untilDeparture))
                : t.mobile_tracker_departsIn(_span(t, status.untilDeparture)),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            // gen_l10n orders a message's arguments alphabetically by placeholder name,
            // not by where they appear in the sentence: airport comes before time.
            '${formatDayDate(depLocal)} · '
            '${t.mobile_tracker_airportClock(flight.origin.code, clock(depLocal))} → '
            '${t.mobile_tracker_airportClock(flight.destination.code, clock(arrLocal))}',
            style: TextStyle(fontSize: 12, color: c.textSecondary),
          ),
        ];
      case FlightPhase.inAir:
        final remainingNm = (flight.distanceNm * (1 - status.progress)).round();
        return [
          Row(
            children: [
              // The units stay as they are: ft, kts, km/h and nm are what a cockpit, a
              // boarding pass and every other tracker print, in any language.
              _Stat(label: t.mobile_tracker_altitude, value: '${_thousands(flight.cruiseFeet)} ft'),
              _Stat(label: t.mobile_tracker_groundSpeed, value: '${flight.groundSpeedKnots} kts', sub: '${(flight.groundSpeedKnots * 1.852).round()} km/h'),
              _Stat(label: t.mobile_tracker_timeLeft, value: _span(t, status.untilArrival), sub: t.mobile_tracker_distanceToGo(remainingNm)),
            ],
          ),
          const SizedBox(height: 8),
          _SourceLine(source: positionSource),
        ];
      case FlightPhase.landed:
        return [
          Text(t.mobile_tracker_landedIn(flight.destination.city), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(
            // Alphabetical again: ago, then time.
            t.mobile_tracker_landedAt(_span(t, status.sinceArrival), clock(arrLocal)),
            style: TextStyle(fontSize: 12, color: c.textSecondary),
          ),
          if (onViewDestinationHub != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: AppGradientButton(
                label: t.mobile_tracker_nearbyStaysAndGolf(flight.destination.code),
                icon: Icons.flight_land_rounded,
                height: 44,
                onPressed: onViewDestinationHub,
              ),
            ),
          ],
        ];
    }
  }

  /// Takes the translations rather than a context: it is static, and the four phases read
  /// as one set — localising only the first would leave three English words beside a Korean
  /// one, which is worse than leaving all four.
  static String _phaseLabel(FlightPhase p, AppLocalizations t) => switch (p) {
        FlightPhase.scheduled => t.mobile_tracker_scheduled,
        FlightPhase.boarding => t.mobile_tracker_boarding,
        FlightPhase.inAir => t.mobile_tracker_inAir,
        FlightPhase.landed => t.mobile_tracker_landed,
      };

  /// `2d 4h`, `3h 05m` or `25 min`, in whichever language the app is being read in.
  ///
  /// The hours and minutes come from `flights_durationParts_*`, which the flight list has
  /// always used for exactly this: one flight's length should not read two ways depending
  /// on which screen you are looking at.
  static String _span(AppLocalizations t, Duration d) {
    final m = d.inMinutes.abs();
    if (m >= 24 * 60) {
      return t.mobile_tracker_daysHours(m ~/ (24 * 60), (m % (24 * 60)) ~/ 60);
    }
    if (m >= 60) {
      return t.flights_durationParts_hoursMinutes(
        m ~/ 60,
        (m % 60).toString().padLeft(2, '0'),
      );
    }
    return t.flights_durationParts_minutesOnly(m);
  }

  static String _thousands(int n) => n >= 1000 ? '${n ~/ 1000},${(n % 1000).toString().padLeft(3, '0')}' : '$n';
}

class _RouteBar extends StatelessWidget {
  const _RouteBar({required this.flight, required this.progress});

  final TrackedFlight flight;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final p = progress.clamp(0.0, 1.0);
    return Row(
      children: [
        Text(flight.origin.code, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        const SizedBox(width: 10),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) => Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                Container(height: 4, decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: BorderRadius.circular(2))),
                Container(
                  width: box.maxWidth * p,
                  height: 4,
                  decoration: BoxDecoration(gradient: kBrandGradient, borderRadius: BorderRadius.circular(2)),
                ),
                Positioned(
                  left: (box.maxWidth * p - 9).clamp(0.0, box.maxWidth - 18),
                  child: Transform.rotate(angle: 1.5708, child: Icon(Icons.flight_rounded, size: 18, color: c.accent)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(flight.destination.code, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _SourceLine extends StatelessWidget {
  const _SourceLine({required this.source});

  final PositionSource source;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = AppLocalizations.of(context)!;
    final (icon, text) = switch (source) {
      PositionSource.gps => (Icons.my_location_rounded, t.mobile_tracker_sourceGps),
      PositionSource.schedule => (Icons.schedule_rounded, t.mobile_tracker_sourceSchedule),
      PositionSource.scheduleNoPermission => (
        Icons.location_disabled_rounded,
        t.mobile_tracker_sourceNoPermission,
      ),
    };
    return Row(
      children: [
        Icon(icon, size: 14, color: source == PositionSource.gps ? c.success : c.textMuted),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: TextStyle(fontSize: 11.5, color: c.textSecondary))),
      ],
    );
  }
}

class _OfflineMapRow extends StatelessWidget {
  const _OfflineMapRow({required this.status, required this.onDownload});

  final OfflineMapStatus status;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = AppLocalizations.of(context)!;
    final (icon, text, action) = switch (status.state) {
      OfflineMapState.ready => (
        Icons.download_done_rounded,
        t.mobile_tracker_offlineSaved(status.sizeLabel),
        null,
      ),
      OfflineMapState.downloading => (
        Icons.downloading_rounded,
        t.mobile_tracker_offlineSaving((status.progress * 100).round()),
        null,
      ),
      OfflineMapState.failed => (
        Icons.error_outline_rounded,
        t.mobile_tracker_offlineFailed,
        // V2's own word for trying a failed thing again, rather than a second one of our
        // own that a translator would have to render twice.
        t.common_retry,
      ),
      OfflineMapState.none => (
        Icons.cloud_download_outlined,
        t.mobile_tracker_offlineNone,
        t.mobile_tracker_saveMap,
      ),
    };
    return Row(
      children: [
        Icon(icon, size: 16, color: status.state == OfflineMapState.ready ? c.success : c.textMuted),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: c.textSecondary))),
        if (action != null) TextButton(onPressed: onDownload, child: Text(action)),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.sub});

  final String label;
  final String value;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UiLabel(label),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          if (sub != null) Text(sub!, style: TextStyle(fontSize: 11, color: c.accent)),
        ],
      ),
    );
  }
}

/// Shown on My flights when nothing booked is coming up.
class NoFlightsCard extends StatelessWidget {
  const NoFlightsCard({required this.onFindFlights, super.key});

  final VoidCallback onFindFlights;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.surfaceElevated, borderRadius: AppRadius.brSheet, border: Border.all(color: c.border)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.mobile_tracker_noFlights, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(t.mobile_tracker_noFlightsBody, style: TextStyle(fontSize: 13, color: c.textSecondary)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: AppGradientButton(
              label: t.landing_hero_searchFlights,
              icon: Icons.flight_rounded,
              height: 44,
              onPressed: onFindFlights,
            ),
          ),
        ],
      ),
    );
  }
}
