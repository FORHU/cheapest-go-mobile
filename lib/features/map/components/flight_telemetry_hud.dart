import 'package:flutter/material.dart';
import 'package:cheapest_go_mobile/features/map/models/map_models.dart';
import 'package:cheapest_go_mobile/shared/components/app_buttons.dart';
import 'package:cheapest_go_mobile/shared/components/ui_kit.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/app_colors.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/app_radius.dart';

/// Live tracker panel: route progress, altitude, speed and time left for one
/// mock flight, with a way into its arrival airport's stays and golf.
class FlightTelemetryHud extends StatelessWidget {
  const FlightTelemetryHud({
    required this.flight,
    required this.progress,
    required this.onNextFlight,
    required this.onViewDestinationHub,
    required this.onExitTracking,
    super.key,
  });

  final TrackedFlight flight;

  /// 0.0 at take-off to 1.0 at landing.
  final double progress;
  final VoidCallback onNextFlight;
  final VoidCallback onViewDestinationHub;
  final VoidCallback onExitTracking;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final p = progress.clamp(0.0, 1.0);
    final remainingNm = (flight.distanceNm * (1 - p)).round();
    final remaining = Duration(seconds: (flight.duration.inSeconds * (1 - p)).round());
    final offer = flight.offer;

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
                    Text(offer.flightNo, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: c.onSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(offer.airline, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    Text(flight.aircraft, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: c.textMuted)),
                  ],
                ),
              ),
              IconButton(tooltip: 'Next flight', onPressed: onNextFlight, icon: Icon(Icons.skip_next_rounded, color: c.accent)),
              CircleIconButton(icon: Icons.close_rounded, tooltip: 'Stop tracking', onPressed: onExitTracking),
            ],
          ),
          const SizedBox(height: 14),
          Row(
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
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Stat(label: 'Altitude', value: '${_thousands(flight.cruiseFeet)} ft', sub: 'FL${flight.cruiseFeet ~/ 100}'),
              _Stat(label: 'Ground speed', value: '${flight.groundSpeedKnots} kts', sub: '${(flight.groundSpeedKnots * 1.852).round()} km/h'),
              _Stat(
                label: 'Time left',
                value: '${remaining.inHours}h ${(remaining.inMinutes % 60).toString().padLeft(2, '0')}m',
                sub: '$remainingNm nm to go',
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Mock flight, shown at 60× speed.', style: TextStyle(fontSize: 10.5, color: c.textSubtle)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: AppGradientButton(
              label: 'Stays & golf near ${flight.destination.code}',
              icon: Icons.flight_land_rounded,
              height: 44,
              onPressed: onViewDestinationHub,
            ),
          ),
        ],
      ),
    );
  }

  static String _thousands(int n) => n >= 1000 ? '${n ~/ 1000},${(n % 1000).toString().padLeft(3, '0')}' : '$n';
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.sub});

  final String label;
  final String value;
  final String sub;

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
          Text(sub, style: TextStyle(fontSize: 11, color: c.accent)),
        ],
      ),
    );
  }
}
