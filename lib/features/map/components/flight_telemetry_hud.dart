import 'package:flutter/material.dart';
import 'package:cheapest_go_mobile/features/map/models/map_models.dart';
import 'package:cheapest_go_mobile/shared/components/glass_card.dart';

/// In-Flight Live Flight Tracker Telemetry HUD
///
/// Displays real-time flight telemetry (altitude, speed, route progression, ETA)
/// with a frosted glass aesthetic matching `gate-closes-app-v2`.
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
  final double progress; // 0.0 to 1.0
  final VoidCallback onNextFlight;
  final VoidCallback onViewDestinationHub;
  final VoidCallback onExitTracking;

  @override
  Widget build(BuildContext context) {
    final traveledNm = (flight.totalDistanceNm * progress).toInt();
    final remainingNm = flight.totalDistanceNm - traveledNm;
    final remainingSecs = (flight.scheduledDuration.inSeconds * (1.0 - progress)).toInt();
    final remHours = remainingSecs ~/ 3600;
    final remMins = (remainingSecs % 3600) ~/ 60;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        color: const Color(0xFF0D1527).withValues(alpha: 0.92),
        borderColor: const Color(0xFF3FE1FD).withValues(alpha: 0.35),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Badges Row: Flight No, Aircraft, Status & Exit
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF004AC6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF3FE1FD).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.flight,
                            size: 14,
                            color: Color(0xFF3FE1FD),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            flight.flightNumber,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            flight.airline,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            flight.aircraftType,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: onNextFlight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Next Route',
                            style: TextStyle(
                              color: Color(0xFF3FE1FD),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Icon(Icons.skip_next, size: 14, color: Color(0xFF3FE1FD)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: onExitTracking,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 2. Flight Route Arc Progress Bar
          Row(
            children: [
              Text(
                flight.originHub.code,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress.clamp(0.01, 1.0),
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF004AC6), Color(0xFF3FE1FD)],
                          ),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3FE1FD).withValues(alpha: 0.6),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: (progress * 180).clamp(0.0, 180.0),
                      child: Transform.rotate(
                        angle: 1.57, // facing right
                        child: const Icon(
                          Icons.flight,
                          size: 14,
                          color: Color(0xFF3FE1FD),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                flight.destinationHub.code,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 3. Telemetry Indicators (FL, Speed, ETA, Distance)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF050B18).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTelemetryTile(
                  label: 'ALTITUDE',
                  value: '${(flight.cruisingAltitudeFeet / 1000).toInt()},000 FT',
                  subValue: 'FL${flight.cruisingAltitudeFeet ~/ 100}',
                ),
                _buildTelemetryTile(
                  label: 'GROUND SPEED',
                  value: '${flight.groundSpeedKnots} KTS',
                  subValue: '${(flight.groundSpeedKnots * 1.15).toInt()} MPH',
                ),
                _buildTelemetryTile(
                  label: 'EST. TIME REMAINING',
                  value: '${remHours}h ${remMins.toString().padLeft(2, '0')}m',
                  subValue: '$remainingNm NM Left',
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 4. Quick Action Button to Inspect Arrival Hub Hotels & Golf
          GestureDetector(
            onTap: onViewDestinationHub,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF006242), Color(0xFF004AC6)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.beach_access, size: 14, color: Color(0xFFBDFFDB)),
                  const SizedBox(width: 6),
                  Text(
                    'Explore Hotels & Golf at ${flight.destinationHub.name} (${flight.destinationHub.code})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
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

  Widget _buildTelemetryTile({
    required String label,
    required String value,
    required String subValue,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          subValue,
          style: const TextStyle(
            color: Color(0xFF3FE1FD),
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
