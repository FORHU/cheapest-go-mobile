import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MapDestinationHub {
  const MapDestinationHub({
    required this.name,
    required this.country,
    required this.code,
    required this.lat,
    required this.lon,
    required this.hotelPrice,
    required this.flightPrice,
    required this.category,
    required this.description,
  });

  final String name;
  final String country;
  final String code;
  final double lat; // in radians
  final double lon; // in radians
  final double hotelPrice;
  final double flightPrice;
  final String category; // 'golf', 'resort', 'city', 'villa'
  final String description;
}

final List<MapDestinationHub> kDestinationHubs = [
  MapDestinationHub(
    name: 'Bali',
    country: 'Indonesia',
    code: 'DPS',
    lat: -8.4095 * math.pi / 180,
    lon: 115.1889 * math.pi / 180,
    hotelPrice: 214,
    flightPrice: 520,
    category: 'golf',
    description: 'Championship fairways & oceanfront luxury villas.',
  ),
  MapDestinationHub(
    name: 'Dubai',
    country: 'UAE',
    code: 'DXB',
    lat: 25.2048 * math.pi / 180,
    lon: 55.2708 * math.pi / 180,
    hotelPrice: 380,
    flightPrice: 640,
    category: 'resort',
    description: 'Emirates Golf Club & ultra-luxury marina suites.',
  ),
  MapDestinationHub(
    name: 'Tokyo',
    country: 'Japan',
    code: 'HND',
    lat: 35.6762 * math.pi / 180,
    lon: 139.6503 * math.pi / 180,
    hotelPrice: 195,
    flightPrice: 480,
    category: 'city',
    description: 'Shinjuku & Ginza metropolis with Michelin dining.',
  ),
  MapDestinationHub(
    name: 'Seoul',
    country: 'South Korea',
    code: 'ICN',
    lat: 37.5665 * math.pi / 180,
    lon: 126.9780 * math.pi / 180,
    hotelPrice: 140,
    flightPrice: 410,
    category: 'city',
    description: 'Gangnam, Myeongdong & fast high-speed transit.',
  ),
  MapDestinationHub(
    name: 'London',
    country: 'United Kingdom',
    code: 'LHR',
    lat: 51.5074 * math.pi / 180,
    lon: -0.1278 * math.pi / 180,
    hotelPrice: 240,
    flightPrice: 350,
    category: 'city',
    description: 'Heathrow direct routes & heritage historic hotels.',
  ),
  MapDestinationHub(
    name: 'New York',
    country: 'United States',
    code: 'JFK',
    lat: 40.7128 * math.pi / 180,
    lon: -74.0060 * math.pi / 180,
    hotelPrice: 290,
    flightPrice: 490,
    category: 'city',
    description: 'Manhattan skyline & rapid transatlantic routes.',
  ),
  MapDestinationHub(
    name: 'Singapore',
    country: 'Singapore',
    code: 'SIN',
    lat: 1.3521 * math.pi / 180,
    lon: 103.8198 * math.pi / 180,
    hotelPrice: 260,
    flightPrice: 510,
    category: 'resort',
    description: 'Changi global hub & Marina Bay infinity pools.',
  ),
  MapDestinationHub(
    name: 'Paris',
    country: 'France',
    code: 'CDG',
    lat: 48.8566 * math.pi / 180,
    lon: 2.3522 * math.pi / 180,
    hotelPrice: 275,
    flightPrice: 460,
    category: 'villa',
    description: 'Haute couture, Louvre art & boutique stays.',
  ),
];

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> with SingleTickerProviderStateMixin {
  double _rotationLon = 100 * math.pi / 180; // initial center on Asia-Pacific
  double _pitch = 15 * math.pi / 180;
  bool _isGlobe3D = true;
  String _selectedCategory = 'all';
  MapDestinationHub? _selectedHub;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _selectedHub = kDestinationHubs.first; // Default select Bali
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();

    _animController.addListener(() {
      if (mounted && _isGlobe3D) {
        setState(() {
          _rotationLon += 0.002;
          if (_rotationLon > math.pi * 2) {
            _rotationLon -= math.pi * 2;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: Stack(
        children: [
          // Globe / Map Interactive Canvas
          GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _rotationLon -= details.delta.dx * 0.008;
                _pitch = (_pitch + details.delta.dy * 0.005)
                    .clamp(-math.pi / 4, math.pi / 4);
              });
            },
            child: SizedBox.expand(
              child: CustomPaint(
                painter: _GlobePainter(
                  rotationLon: _rotationLon,
                  pitch: _pitch,
                  is3D: _isGlobe3D,
                  hubs: kDestinationHubs,
                  selectedHub: _selectedHub,
                  selectedCategory: _selectedCategory,
                ),
              ),
            ),
          ),

          // Top Overlay Controls
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.public,
                              size: 16,
                              color: Color(0xFF3FE1FD),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isGlobe3D ? '3D Globe Mode' : '2D Map Projection',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _isGlobe3D = !_isGlobe3D),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF004AC6),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3FE1FD).withValues(alpha: 0.4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isGlobe3D ? Icons.map_outlined : Icons.language,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Category Filter Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'All Hubs', Icons.scatter_plot),
                      _buildFilterChip('golf', 'Golf & Fairways', Icons.sports_golf),
                      _buildFilterChip('resort', 'Luxury Resorts', Icons.beach_access),
                      _buildFilterChip('city', 'Urban Flights', Icons.flight),
                      _buildFilterChip('villa', 'Private Villas', Icons.villa),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Slide-up Destination Hub Card
          if (_selectedHub != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 96,
              child: _buildDestinationSheet(context, _selectedHub!),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, IconData icon) {
    final active = _selectedCategory == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = key),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF004AC6)
              : Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active
                ? const Color(0xFF3FE1FD)
                : Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: active ? Colors.white : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 5),
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

  Widget _buildDestinationSheet(BuildContext context, MapDestinationHub hub) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.4)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF004AC6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      hub.code,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hub.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        hub.country,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  final nextIdx =
                      (kDestinationHubs.indexOf(hub) + 1) % kDestinationHubs.length;
                  setState(() {
                    _selectedHub = kDestinationHubs[nextIdx];
                    _rotationLon = -_selectedHub!.lon;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Text(
                        'Next Hub',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      Icon(Icons.chevron_right, size: 14, color: Colors.white70),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            hub.description,
            style: const TextStyle(color: Color(0xFFDAE2FD), fontSize: 12),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => context.go('/hotels'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF006242),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'HOTEL RATE',
                          style: TextStyle(
                            color: Color(0xFFBDFFDB),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'From \$${hub.hotelPrice.toInt()}/night',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => context.push('/flights'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF004AC6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'DIRECT FLIGHT',
                          style: TextStyle(
                            color: Color(0xFFDAE2FD),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'From \$${hub.flightPrice.toInt()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- 3D Globe & Flat Projection Painter ---

class _GlobePainter extends CustomPainter {
  const _GlobePainter({
    required this.rotationLon,
    required this.pitch,
    required this.is3D,
    required this.hubs,
    required this.selectedHub,
    required this.selectedCategory,
  });

  final double rotationLon;
  final double pitch;
  final bool is3D;
  final List<MapDestinationHub> hubs;
  final MapDestinationHub? selectedHub;
  final String selectedCategory;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.45);
    final radius = math.min(size.width, size.height) * 0.38;

    if (is3D) {
      _paint3DGlobe(canvas, center, radius, size);
    } else {
      _paint2DMap(canvas, size);
    }
  }

  void _paint3DGlobe(Canvas canvas, Offset center, double radius, Size size) {
    // 1. Atmosphere Halo
    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF0053DB).withValues(alpha: 0.0),
          const Color(0xFF3FE1FD).withValues(alpha: 0.15),
          const Color(0xFF3FE1FD).withValues(alpha: 0.35),
          const Color(0xFF0053DB).withValues(alpha: 0.0),
        ],
        stops: const [0.85, 0.94, 0.98, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.15));
    canvas.drawCircle(center, radius * 1.15, haloPaint);

    // 2. Globe Sphere (Deep Ocean Base)
    final oceanPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: const [
          Color(0xFF0A225C),
          Color(0xFF041133),
          Color(0xFF020717),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, oceanPaint);

    // 3. Clip to sphere for surface details
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: radius)));

    // Graticules (Latitude & Longitude grid lines)
    final gridPaint = Paint()
      ..color = const Color(0xFF2563EB).withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Latitudes (-60, -30, 0, 30, 60)
    for (final latDeg in [-60, -30, 0, 30, 60]) {
      final lat = latDeg * math.pi / 180;
      final path = Path();
      bool first = true;
      for (double lonDeg = -180; lonDeg <= 180; lonDeg += 10) {
        final lon = lonDeg * math.pi / 180;
        final pt = _project3D(lat, lon, center, radius);
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

    // Longitudes
    for (double lonDeg = -180; lonDeg < 180; lonDeg += 30) {
      final lon = lonDeg * math.pi / 180;
      final path = Path();
      bool first = true;
      for (double latDeg = -80; latDeg <= 80; latDeg += 10) {
        final lat = latDeg * math.pi / 180;
        final pt = _project3D(lat, lon, center, radius);
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

    // Flight Arcs between major hubs
    _drawFlightArc(
      canvas,
      kDestinationHubs[5], // JFK
      kDestinationHubs[4], // LHR
      center,
      radius,
    );
    _drawFlightArc(
      canvas,
      kDestinationHubs[3], // ICN
      kDestinationHubs[0], // DPS
      center,
      radius,
    );
    _drawFlightArc(
      canvas,
      kDestinationHubs[1], // DXB
      kDestinationHubs[6], // SIN
      center,
      radius,
    );

    canvas.restore();

    // Outer rim highlight
    final rimPaint = Paint()
      ..color = const Color(0xFF3FE1FD).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawCircle(center, radius, rimPaint);

    // 4. Draw Destination Beacons
    for (final hub in hubs) {
      if (selectedCategory != 'all' && hub.category != selectedCategory) {
        continue;
      }
      final pt = _project3D(hub.lat, hub.lon, center, radius);
      if (pt != null) {
        final isSelected = selectedHub?.code == hub.code;

        // Glowing outer circle
        final glowColor = isSelected
            ? const Color(0xFF3FE1FD)
            : (hub.category == 'golf'
                ? const Color(0xFF4EDEA3)
                : const Color(0xFF2563EB));

        canvas.drawCircle(
          pt,
          isSelected ? 10 : 6,
          Paint()..color = glowColor.withValues(alpha: 0.35),
        );
        canvas.drawCircle(
          pt,
          isSelected ? 6 : 3.5,
          Paint()..color = glowColor,
        );
        canvas.drawCircle(
          pt,
          isSelected ? 2.5 : 1.5,
          Paint()..color = Colors.white,
        );

        // Label Tag
        final textSpan = TextSpan(
          text: '${hub.name} • \$${hub.hotelPrice.toInt()}',
          style: TextStyle(
            color: Colors.white,
            fontSize: isSelected ? 11 : 9.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            shadows: const [
              Shadow(color: Colors.black, blurRadius: 4),
            ],
          ),
        );
        final tp = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(pt.dx - tp.width / 2, pt.dy - tp.height - 8));
      }
    }
  }

  void _paint2DMap(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF041133);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Grid lines for 2D equirectangular
    final grid = Paint()
      ..color = const Color(0xFF2563EB).withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var x = 0.0; x <= size.width; x += size.width / 12) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y <= size.height; y += size.height / 8) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    // 2D Hub pins
    for (final hub in hubs) {
      if (selectedCategory != 'all' && hub.category != selectedCategory) {
        continue;
      }
      final normX = (hub.lon + math.pi) / (2 * math.pi);
      final normY = (math.pi / 2 - hub.lat) / math.pi;

      final pt = Offset(normX * size.width, normY * (size.height * 0.7) + 60);
      final isSelected = selectedHub?.code == hub.code;

      canvas.drawCircle(
        pt,
        isSelected ? 8 : 5,
        Paint()
          ..color = isSelected ? const Color(0xFF3FE1FD) : const Color(0xFF2563EB),
      );

      final tp = TextPainter(
        text: TextSpan(
          text: '${hub.name} (${hub.code})',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(pt.dx + 8, pt.dy - 6));
    }
  }

  Offset? _project3D(
    double lat,
    double lon,
    Offset center,
    double radius,
  ) {
    final dLon = lon - rotationLon;

    // 3D coordinates on unit sphere
    final x0 = math.cos(lat) * math.sin(dLon);
    final y0 = -math.sin(lat);
    final z0 = math.cos(lat) * math.cos(dLon);

    // Apply pitch rotation around X axis
    final y1 = y0 * math.cos(pitch) - z0 * math.sin(pitch);
    final z1 = y0 * math.sin(pitch) + z0 * math.cos(pitch);

    // Back hemisphere culling
    if (z1 <= 0.05) return null;

    return Offset(
      center.dx + x0 * radius,
      center.dy + y1 * radius,
    );
  }

  void _drawFlightArc(
    Canvas canvas,
    MapDestinationHub from,
    MapDestinationHub to,
    Offset center,
    double radius,
  ) {
    final path = Path();
    bool started = false;

    for (double t = 0; t <= 1.0; t += 0.05) {
      final lat = from.lat + (to.lat - from.lat) * t;
      final lon = from.lon + (to.lon - from.lon) * t;
      final pt = _project3D(lat, lon, center, radius);

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
        ..color = const Color(0xFF3FE1FD).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawPath(path, arcPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GlobePainter old) => true;
}
