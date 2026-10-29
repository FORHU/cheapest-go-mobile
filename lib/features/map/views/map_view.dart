import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cheapest_go_mobile/features/map/components/airport_hub_sheet.dart';
import 'package:cheapest_go_mobile/features/map/components/flight_telemetry_hud.dart';
import 'package:cheapest_go_mobile/features/map/components/map_tier_toggle.dart';
import 'package:cheapest_go_mobile/features/map/models/map_models.dart';

/// Interactive Map View
///
/// Implements 2D Map (`MapTier.lite`) and 3D Globe (`MapTier.standard`) modes
/// inspired by `gate-closes-app-v2`, with interactive airport hubs (hotels, flights, golf getaways)
/// and real-time in-flight live tracking mode with telemetry HUD.
class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> with TickerProviderStateMixin {
  MapTier _currentTier = MapTier.standard;
  double _rotationLon = 115 * math.pi / 180; // centered on SE Asia / Philippines
  double _pitch = 12 * math.pi / 180;
  Offset _panOffset2D = Offset.zero;

  String _selectedCategory = 'all';
  MapDestinationHub? _selectedHub;
  bool _isInFlightTrackingMode = false;
  int _activeFlightIndex = 0;

  late AnimationController _globeRotationController;
  late AnimationController _flightProgressController;
  late AnimationController _radarPulseController;

  @override
  void initState() {
    super.initState();
    _selectedHub = kGlobalDestinationHubs.first; // Default MNL

    // 1. Globe auto-rotation
    _globeRotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 50),
    )..repeat();

    _globeRotationController.addListener(() {
      if (mounted && _currentTier == MapTier.standard && !_isInFlightTrackingMode) {
        setState(() {
          _rotationLon += 0.0018;
          if (_rotationLon > math.pi * 2) {
            _rotationLon -= math.pi * 2;
          }
        });
      }
    });

    // 2. Flight interpolation controller (simulates plane travel along route)
    _flightProgressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();

    // 3. Radar ripple beacon controller
    _radarPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _globeRotationController.dispose();
    _flightProgressController.dispose();
    _radarPulseController.dispose();
    super.dispose();
  }

  TrackedFlight get _currentFlight => kActiveTrackedFlights[_activeFlightIndex];

  void _onPanUpdate(DragUpdateDetails details) {
    if (_currentTier == MapTier.standard) {
      setState(() {
        _rotationLon -= details.delta.dx * 0.008;
        _pitch = (_pitch + details.delta.dy * 0.005)
            .clamp(-math.pi / 3, math.pi / 3);
      });
    } else {
      setState(() {
        _panOffset2D += details.delta;
      });
    }
  }

  void _onTapCanvas(TapUpDetails details, Size size) {
    if (_isInFlightTrackingMode) return;

    final center = Offset(size.width / 2, size.height * 0.44);
    final radius = math.min(size.width, size.height) * 0.40;
    final tapPos = details.localPosition;

    MapDestinationHub? closest;
    double minDistance = 45.0; // hit target threshold in logical pixels

    for (final hub in kGlobalDestinationHubs) {
      Offset? pt;
      if (_currentTier == MapTier.standard) {
        pt = _project3D(hub.latRad, hub.lonRad, center, radius, _rotationLon, _pitch);
      } else {
        pt = _project2D(hub.latRad, hub.lonRad, size, _panOffset2D);
      }

      if (pt != null) {
        final d = (pt - tapPos).distance;
        if (d < minDistance) {
          minDistance = d;
          closest = hub;
        }
      }
    }

    if (closest != null) {
      setState(() {
        _selectedHub = closest;
        if (_currentTier == MapTier.standard) {
          _rotationLon = closest!.lonRad;
        }
      });
    }
  }

  void _cycleNextHub() {
    final curIdx = kGlobalDestinationHubs.indexWhere((h) => h.code == _selectedHub?.code);
    final nextIdx = (curIdx + 1) % kGlobalDestinationHubs.length;
    setState(() {
      _selectedHub = kGlobalDestinationHubs[nextIdx];
      if (_currentTier == MapTier.standard) {
        _rotationLon = _selectedHub!.lonRad;
      }
    });
  }

  void _cyclePreviousHub() {
    final curIdx = kGlobalDestinationHubs.indexWhere((h) => h.code == _selectedHub?.code);
    final prevIdx = (curIdx - 1 + kGlobalDestinationHubs.length) % kGlobalDestinationHubs.length;
    setState(() {
      _selectedHub = kGlobalDestinationHubs[prevIdx];
      if (_currentTier == MapTier.standard) {
        _rotationLon = _selectedHub!.lonRad;
      }
    });
  }

  void _cycleNextFlight() {
    setState(() {
      _activeFlightIndex = (_activeFlightIndex + 1) % kActiveTrackedFlights.length;
      if (_currentTier == MapTier.standard) {
        _rotationLon = _currentFlight.originHub.lonRad;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return Scaffold(
          backgroundColor: const Color(0xFF070B14),
          body: Stack(
            children: [
              // 1. Interactive 2D Map / 3D Globe Canvas
              GestureDetector(
                onPanUpdate: _onPanUpdate,
                onTapUp: (details) => _onTapCanvas(details, size),
                child: SizedBox.expand(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([
                      _globeRotationController,
                      _flightProgressController,
                      _radarPulseController,
                    ]),
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _MapCanvasPainter(
                          tier: _currentTier,
                          rotationLon: _rotationLon,
                          pitch: _pitch,
                          panOffset2D: _panOffset2D,
                          hubs: kGlobalDestinationHubs,
                          selectedHub: _selectedHub,
                          selectedCategory: _selectedCategory,
                          isInFlightTrackingMode: _isInFlightTrackingMode,
                          activeFlight: _currentFlight,
                          flightProgress: _flightProgressController.value,
                          pulseValue: _radarPulseController.value,
                        ),
                      );
                    },
                  ),
                ),
              ),

              // 2. Top Header Controls (Map Tier Toggle, Flight Tracker Toggle, Filter Chips)
              SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 2D / 3D Map Tier Toggle Switch
                          MapTierToggle(
                            currentTier: _currentTier,
                            onTierChanged: (tier) {
                              setState(() => _currentTier = tier);
                            },
                          ),

                          // Mode Switch: Hub Explorer vs In-Flight Live Tracker
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isInFlightTrackingMode = !_isInFlightTrackingMode;
                                if (_isInFlightTrackingMode && _currentTier == MapTier.standard) {
                                  _rotationLon = _currentFlight.originHub.lonRad;
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _isInFlightTrackingMode
                                      ? [const Color(0xFF006242), const Color(0xFF004AC6)]
                                      : [const Color(0xFF1E293B), const Color(0xFF0F172A)],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _isInFlightTrackingMode
                                      ? const Color(0xFF3FE1FD)
                                      : Colors.white.withValues(alpha: 0.2),
                                ),
                                boxShadow: _isInFlightTrackingMode
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF3FE1FD).withValues(alpha: 0.35),
                                          blurRadius: 10,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isInFlightTrackingMode ? Icons.flight_takeoff : Icons.explore,
                                    size: 14,
                                    color: _isInFlightTrackingMode
                                        ? const Color(0xFF3FE1FD)
                                        : Colors.white70,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _isInFlightTrackingMode ? 'Live In-Flight' : 'Hubs & Stays',
                                    style: TextStyle(
                                      color: _isInFlightTrackingMode ? Colors.white : const Color(0xFFDAE2FD),
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

                    // Category Filter Pills (Only shown in Hub Explorer mode)
                    if (!_isInFlightTrackingMode)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        child: Row(
                          children: [
                            _buildFilterChip('all', 'All Hubs', Icons.scatter_plot),
                            _buildFilterChip('hotels', 'Airport Hotels', Icons.hotel),
                            _buildFilterChip('flights', 'Direct Flights', Icons.flight),
                            _buildFilterChip('golf', 'Golf Getaways', Icons.sports_golf),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // 3. Floating Bottom Cards (In-Flight Telemetry HUD vs Airport Hub Sheet)
              Positioned(
                left: 0,
                right: 0,
                bottom: 84, // Cradled above Globe bottom nav dome
                child: _isInFlightTrackingMode
                    ? FlightTelemetryHud(
                        flight: _currentFlight,
                        progress: _flightProgressController.value,
                        onNextFlight: _cycleNextFlight,
                        onViewDestinationHub: () {
                          setState(() {
                            _selectedHub = _currentFlight.destinationHub;
                            _isInFlightTrackingMode = false;
                            if (_currentTier == MapTier.standard) {
                              _rotationLon = _selectedHub!.lonRad;
                            }
                          });
                        },
                        onExitTracking: () {
                          setState(() => _isInFlightTrackingMode = false);
                        },
                      )
                    : (_selectedHub != null
                        ? AirportHubSheet(
                            hub: _selectedHub!,
                            initialTab: _selectedCategory == 'golf'
                                ? 3
                                : (_selectedCategory == 'hotels'
                                    ? 1
                                    : (_selectedCategory == 'flights' ? 2 : 0)),
                            onNextHub: _cycleNextHub,
                            onPreviousHub: _cyclePreviousHub,
                            onClose: () => setState(() => _selectedHub = null),
                          )
                        : const SizedBox.shrink()),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String key, String label, IconData icon) {
    final active = _selectedCategory == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = key),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF004AC6) : const Color(0xFF0F172A).withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? const Color(0xFF3FE1FD) : Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: active ? Colors.white : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.bold : FontWeight.w500,
                color: active ? Colors.white : const Color(0xFFDAE2FD),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Canvas Painter: 2D Equirectangular Map vs 3D Orthographic Spherical Globe
// ============================================================================

class _MapCanvasPainter extends CustomPainter {
  const _MapCanvasPainter({
    required this.tier,
    required this.rotationLon,
    required this.pitch,
    required this.panOffset2D,
    required this.hubs,
    required this.selectedHub,
    required this.selectedCategory,
    required this.isInFlightTrackingMode,
    required this.activeFlight,
    required this.flightProgress,
    required this.pulseValue,
  });

  final MapTier tier;
  final double rotationLon;
  final double pitch;
  final Offset panOffset2D;
  final List<MapDestinationHub> hubs;
  final MapDestinationHub? selectedHub;
  final String selectedCategory;
  final bool isInFlightTrackingMode;
  final TrackedFlight activeFlight;
  final double flightProgress;
  final double pulseValue;

  @override
  void paint(Canvas canvas, Size size) {
    if (tier == MapTier.standard) {
      _paint3DGlobe(canvas, size);
    } else {
      _paint2DMap(canvas, size);
    }
  }

  // --- 3D Globe Projection ---

  void _paint3DGlobe(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.44);
    final radius = math.min(size.width, size.height) * 0.40;

    // 1. Atmosphere Glow & Horizon Rim Halo
    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF004AC6).withValues(alpha: 0.0),
          const Color(0xFF3FE1FD).withValues(alpha: 0.18),
          const Color(0xFF3FE1FD).withValues(alpha: 0.38),
          const Color(0xFF004AC6).withValues(alpha: 0.0),
        ],
        stops: const [0.85, 0.94, 0.98, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.15));
    canvas.drawCircle(center, radius * 1.15, haloPaint);

    // 2. Globe Sphere (Deep Slate Ocean with subtle radial light)
    final oceanPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.25, -0.3),
        colors: const [
          Color(0xFF0A225C),
          Color(0xFF051336),
          Color(0xFF020717),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, oceanPaint);

    // 3. Clip surface features inside sphere
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: radius)));

    // Graticules (Latitude & Longitude grid lines)
    final gridPaint = Paint()
      ..color = const Color(0xFF2563EB).withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (final latDeg in [-60, -30, 0, 30, 60]) {
      final lat = latDeg * math.pi / 180;
      final path = Path();
      bool first = true;
      for (double lonDeg = -180; lonDeg <= 180; lonDeg += 10) {
        final lon = lonDeg * math.pi / 180;
        final pt = _project3D(lat, lon, center, radius, rotationLon, pitch);
        if (pt != null) {
          if (first) {
            path.moveTo(pt.dx, pt.dy);
            first = false;
          } else {
            path.lineTo(pt.dx, pt.dy);
          }
        } else {
          first = true;
        }
      }
      canvas.drawPath(path, gridPaint);
    }

    for (double lonDeg = -180; lonDeg < 180; lonDeg += 30) {
      final lon = lonDeg * math.pi / 180;
      final path = Path();
      bool first = true;
      for (double latDeg = -80; latDeg <= 80; latDeg += 10) {
        final lat = latDeg * math.pi / 180;
        final pt = _project3D(lat, lon, center, radius, rotationLon, pitch);
        if (pt != null) {
          if (first) {
            path.moveTo(pt.dx, pt.dy);
            first = false;
          } else {
            path.lineTo(pt.dx, pt.dy);
          }
        } else {
          first = true;
        }
      }
      canvas.drawPath(path, gridPaint);
    }

    // Flight Route Arcs
    _drawFlightArc3D(canvas, hubs[0], hubs[3], center, radius); // MNL -> SIN
    _drawFlightArc3D(canvas, hubs[1], hubs[2], center, radius); // CRK -> DPS
    _drawFlightArc3D(canvas, hubs[3], hubs[4], center, radius); // SIN -> HND
    _drawFlightArc3D(canvas, hubs[5], hubs[6], center, radius); // DXB -> LHR
    _drawFlightArc3D(canvas, hubs[6], hubs[7], center, radius); // LHR -> JFK

    // Active in-flight aircraft path highlight & animated plane
    if (isInFlightTrackingMode) {
      _drawInFlightAircraft3D(canvas, center, radius);
    }

    canvas.restore();

    // 4. Outer Rim Horizon Ring
    final rimPaint = Paint()
      ..color = const Color(0xFF3FE1FD).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawCircle(center, radius, rimPaint);

    // 5. Hub Pins & Badges
    for (final hub in hubs) {
      if (_filterMatch(hub)) {
        final pt = _project3D(hub.latRad, hub.lonRad, center, radius, rotationLon, pitch);
        if (pt != null) {
          final isSelected = selectedHub?.code == hub.code;
          _drawHubPin(canvas, pt, hub, isSelected);
        }
      }
    }
  }

  // --- 2D Equirectangular Map Projection ---

  void _paint2DMap(Canvas canvas, Size size) {
    // 1. Dark Slate Oceanic Background
    final bgPaint = Paint()..color = const Color(0xFF070F22);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // 2. Graticules
    final grid = Paint()
      ..color = const Color(0xFF2563EB).withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var x = 0.0; x <= size.width; x += size.width / 12) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y <= size.height; y += size.height / 8) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    // 3. Flight Corridors in 2D
    _drawFlightRoute2D(canvas, hubs[0], hubs[3], size); // MNL -> SIN
    _drawFlightRoute2D(canvas, hubs[1], hubs[2], size); // CRK -> DPS
    _drawFlightRoute2D(canvas, hubs[3], hubs[4], size); // SIN -> HND
    _drawFlightRoute2D(canvas, hubs[5], hubs[6], size); // DXB -> LHR
    _drawFlightRoute2D(canvas, hubs[6], hubs[7], size); // LHR -> JFK

    // 4. Active In-flight Aircraft in 2D
    if (isInFlightTrackingMode) {
      _drawInFlightAircraft2D(canvas, size);
    }

    // 5. 2D Hub Pins
    for (final hub in hubs) {
      if (_filterMatch(hub)) {
        final pt = _project2D(hub.latRad, hub.lonRad, size, panOffset2D);
        final isSelected = selectedHub?.code == hub.code;
        _drawHubPin(canvas, pt, hub, isSelected);
      }
    }
  }

  bool _filterMatch(MapDestinationHub hub) {
    if (selectedCategory == 'all') return true;
    if (selectedCategory == 'golf') return hub.golfCourses.isNotEmpty;
    if (selectedCategory == 'hotels') return hub.airportHotels.isNotEmpty;
    if (selectedCategory == 'flights') return hub.directFlights.isNotEmpty;
    return true;
  }

  void _drawHubPin(Canvas canvas, Offset pt, MapDestinationHub hub, bool isSelected) {
    final glowColor = isSelected
        ? const Color(0xFF3FE1FD)
        : (hub.category == 'golf' ? const Color(0xFF4EDEA3) : const Color(0xFF2563EB));

    // Outer glow
    canvas.drawCircle(
      pt,
      isSelected ? 10 : 6,
      Paint()..color = glowColor.withValues(alpha: 0.35),
    );
    // Core dot
    canvas.drawCircle(
      pt,
      isSelected ? 5.5 : 3.5,
      Paint()..color = glowColor,
    );
    // Center white dot
    canvas.drawCircle(
      pt,
      isSelected ? 2.5 : 1.5,
      Paint()..color = Colors.white,
    );

    // Label Badge
    final label = '${hub.code} • \$${hub.hotelPrice.toInt()}';
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white,
          fontSize: isSelected ? 11 : 9.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, Offset(pt.dx - tp.width / 2, pt.dy - tp.height - 7));
  }

  // --- Flight Arc & Aircraft Drawing ---

  void _drawFlightArc3D(
    Canvas canvas,
    MapDestinationHub from,
    MapDestinationHub to,
    Offset center,
    double radius,
  ) {
    final path = Path();
    bool started = false;

    for (double t = 0; t <= 1.0; t += 0.05) {
      final lat = from.latRad + (to.latRad - from.latRad) * t;
      final lon = from.lonRad + (to.lonRad - from.lonRad) * t;
      final pt = _project3D(lat, lon, center, radius, rotationLon, pitch);

      if (pt != null) {
        if (!started) {
          path.moveTo(pt.dx, pt.dy);
          started = true;
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }
    }

    if (started) {
      final arcPaint = Paint()
        ..color = const Color(0xFF2563EB).withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawPath(path, arcPaint);
    }
  }

  void _drawFlightRoute2D(
    Canvas canvas,
    MapDestinationHub from,
    MapDestinationHub to,
    Size size,
  ) {
    final pt1 = _project2D(from.latRad, from.lonRad, size, panOffset2D);
    final pt2 = _project2D(to.latRad, to.lonRad, size, panOffset2D);

    final linePaint = Paint()
      ..color = const Color(0xFF2563EB).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawLine(pt1, pt2, linePaint);
  }

  void _drawInFlightAircraft3D(Canvas canvas, Offset center, double radius) {
    final from = activeFlight.originHub;
    final to = activeFlight.destinationHub;

    // 1. Draw glowing active flight path
    final path = Path();
    bool started = false;
    for (double t = 0; t <= 1.0; t += 0.03) {
      final lat = from.latRad + (to.latRad - from.latRad) * t;
      final lon = from.lonRad + (to.lonRad - from.lonRad) * t;
      final pt = _project3D(lat, lon, center, radius, rotationLon, pitch);
      if (pt != null) {
        if (!started) {
          path.moveTo(pt.dx, pt.dy);
          started = true;
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }
    }
    if (started) {
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF3FE1FD).withValues(alpha: 0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }

    // 2. Interpolate Plane Position
    final curLat = from.latRad + (to.latRad - from.latRad) * flightProgress;
    final curLon = from.lonRad + (to.lonRad - from.lonRad) * flightProgress;
    final planePt = _project3D(curLat, curLon, center, radius, rotationLon, pitch);

    if (planePt != null) {
      _drawAircraftBeacon(canvas, planePt);
    }
  }

  void _drawInFlightAircraft2D(Canvas canvas, Size size) {
    final from = activeFlight.originHub;
    final to = activeFlight.destinationHub;

    final pt1 = _project2D(from.latRad, from.lonRad, size, panOffset2D);
    final pt2 = _project2D(to.latRad, to.lonRad, size, panOffset2D);

    // Glowing route
    canvas.drawLine(
      pt1,
      pt2,
      Paint()
        ..color = const Color(0xFF3FE1FD).withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Current plane point
    final planePt = Offset(
      pt1.dx + (pt2.dx - pt1.dx) * flightProgress,
      pt1.dy + (pt2.dy - pt1.dy) * flightProgress,
    );

    _drawAircraftBeacon(canvas, planePt);
  }

  void _drawAircraftBeacon(Canvas canvas, Offset planePt) {
    // 1. Radar Ripple Wave ("The blue thing" / current live location beacon)
    final rippleRadius = 10.0 + pulseValue * 18.0;
    final rippleAlpha = (1.0 - pulseValue).clamp(0.0, 1.0) * 0.55;
    canvas.drawCircle(
      planePt,
      rippleRadius,
      Paint()
        ..color = const Color(0xFF3FE1FD).withValues(alpha: rippleAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    // 2. Inner Glowing Core
    canvas.drawCircle(
      planePt,
      9,
      Paint()..color = const Color(0xFF004AC6).withValues(alpha: 0.6),
    );
    canvas.drawCircle(
      planePt,
      5,
      Paint()..color = const Color(0xFF3FE1FD),
    );
    canvas.drawCircle(
      planePt,
      2,
      Paint()..color = Colors.white,
    );

    // 3. Flight Callout Tag
    final textSpan = TextSpan(
      text: '✈ ${activeFlight.flightNumber}',
      style: const TextStyle(
        color: Color(0xFF3FE1FD),
        fontSize: 10,
        fontWeight: FontWeight.w900,
        shadows: [Shadow(color: Colors.black, blurRadius: 4)],
      ),
    );
    final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(planePt.dx - tp.width / 2, planePt.dy - tp.height - 10));
  }

  @override
  bool shouldRepaint(covariant _MapCanvasPainter old) => true;
}

// ============================================================================
// Projection Helpers (3D Orthographic Spherical vs 2D Equirectangular)
// ============================================================================

Offset? _project3D(
  double lat,
  double lon,
  Offset center,
  double radius,
  double rotationLon,
  double pitch,
) {
  final dLon = lon - rotationLon;

  // 3D coordinates on unit sphere
  final x0 = math.cos(lat) * math.sin(dLon);
  final y0 = -math.sin(lat);
  final z0 = math.cos(lat) * math.cos(dLon);

  // Apply pitch tilt rotation around X-axis
  final y1 = y0 * math.cos(pitch) - z0 * math.sin(pitch);
  final z1 = y0 * math.sin(pitch) + z0 * math.cos(pitch);

  // Back-face hemisphere culling
  if (z1 <= 0.05) return null;

  return Offset(
    center.dx + x0 * radius,
    center.dy + y1 * radius,
  );
}

Offset _project2D(double lat, double lon, Size size, Offset panOffset) {
  final normX = (lon + math.pi) / (2 * math.pi);
  final normY = (math.pi / 2 - lat) / math.pi;

  final baseHeight = size.height * 0.65;
  final x = normX * size.width + panOffset.dx;
  final y = normY * baseHeight + 70 + panOffset.dy;

  return Offset(x, y);
}
