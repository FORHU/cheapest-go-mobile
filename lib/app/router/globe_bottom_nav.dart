import 'package:flutter/material.dart';
import 'package:cheapest_go_mobile/app/theme/app_theme.dart';

class GlobeNavTab {
  const GlobeNavTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// Kinetic Horizon Globe Navigation Bar
///
/// Inspired by `gate-closes-app-v2/lib/shared/widgets/map_bottom_nav.dart`:
/// Features 4 peripheral tabs cradling a raised 3D Globe dome button in the center
/// placed directly between Hotels and Flights.
class GlobeBottomNav extends StatelessWidget {
  const GlobeBottomNav({
    required this.tabs,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onGlobePressed,
    this.isGlobeActive = false,
    super.key,
  }) : assert(tabs.length == 4, 'Requires 2 tabs on left and 2 tabs on right of Globe');

  /// Body height without dome or safe-area
  static const double barHeight = 64;
  static const double _buttonSize = 58;

  // Dome proportions derived from Expo/gate-closes BNB-45
  static const double _domeWidth = _buttonSize * 1.76;
  static const double _domeRise = _buttonSize * 0.58;

  final List<GlobeNavTab> tabs;
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onGlobePressed;
  final bool isGlobeActive;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    Widget buildTab(int i) => Expanded(
          child: _NavTabItem(
            tab: tabs[i],
            active: !isGlobeActive && i == currentIndex,
            onTap: () => onTabSelected(i),
          ),
        );

    return SizedBox(
      height: barHeight + bottomInset + _domeRise,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Smooth Bezier Dome Bar
          Positioned.fill(
            child: CustomPaint(
              painter: _GlobeDomeBarPainter(
                color: context.colors.surface,
                borderColor: context.colors.border,
                domeWidth: _domeWidth,
                domeRise: _domeRise,
              ),
            ),
          ),

          // 2. Tab Bar Row
          Positioned(
            left: 0,
            right: 0,
            top: _domeRise,
            height: barHeight,
            child: Row(
              children: [
                buildTab(0), // Explore / Home
                buildTab(1), // Hotels
                const SizedBox(width: _domeWidth), // Center gap for Globe dome
                buildTab(2), // Flights
                buildTab(3), // Trips (Bookings + Saved)
              ],
            ),
          ),

          // 3. Center Raised 3D Globe Button
          Positioned(
            top: _domeRise - _buttonSize / 2 + 2,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: onGlobePressed,
                child: Tooltip(
                  message: 'Explore 3D World Globe & Stays Map',
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: _buttonSize,
                    height: _buttonSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        center: Alignment(-0.25, -0.25),
                        colors: [
                          Color(0xFF3FE1FD),
                          Color(0xFF2563EB),
                          Color(0xFF003EA8),
                          Color(0xFF001F4D),
                        ],
                        stops: [0.0, 0.45, 0.85, 1.0],
                      ),
                      border: Border.all(
                        color: isGlobeActive
                            ? const Color(0xFF3FE1FD)
                            : Colors.white.withValues(alpha: 0.8),
                        width: isGlobeActive ? 2.5 : 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isGlobeActive
                              ? const Color(0xFF3FE1FD).withValues(alpha: 0.6)
                              : const Color(0xFF004AC6).withValues(alpha: 0.45),
                          blurRadius: isGlobeActive ? 18 : 12,
                          spreadRadius: isGlobeActive ? 2 : 0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Subtle latitude/meridian orbital ring
                        Container(
                          width: _buttonSize * 0.75,
                          height: _buttonSize * 0.75,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                        ),
                        // Globe Icon
                        const Icon(
                          Icons.public_rounded,
                          size: 28,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTabItem extends StatelessWidget {
  const _NavTabItem({
    required this.tab,
    required this.active,
    required this.onTap,
  });

  final GlobeNavTab tab;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = active ? colors.accent : colors.textMuted;

    return Semantics(
      button: true,
      selected: active,
      label: tab.label,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              active ? tab.activeIcon : tab.icon,
              color: color,
              size: 22,
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: active ? FontWeight.bold : FontWeight.w500,
                letterSpacing: -0.2,
              ),
              child: Text(
                tab.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Smooth Bezier dome painter matching `gate-closes-app-v2/lib/shared/widgets/map_bottom_nav.dart`
class _GlobeDomeBarPainter extends CustomPainter {
  const _GlobeDomeBarPainter({
    required this.color,
    required this.borderColor,
    required this.domeWidth,
    required this.domeRise,
  });

  final Color color;
  final Color borderColor;
  final double domeWidth;
  final double domeRise;

  @override
  void paint(Canvas canvas, Size size) {
    final top = domeRise;
    final mid = size.width / 2;
    final half = domeWidth / 2;

    final path = Path()
      ..moveTo(0, top)
      ..lineTo(mid - half - 14, top)
      ..cubicTo(mid - half, top, mid - half * 0.7, 0, mid, 0)
      ..cubicTo(mid + half * 0.7, 0, mid + half, top, mid + half + 14, top)
      ..lineTo(size.width, top)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    // Drop Shadow
    canvas.drawShadow(
      path,
      const Color(0x1A0F172A),
      6,
      false,
    );

    // Surface Fill
    canvas.drawPath(path, Paint()..color = color);

    // Border Hairline
    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(_GlobeDomeBarPainter old) =>
      old.color != color ||
      old.borderColor != borderColor ||
      old.domeWidth != domeWidth ||
      old.domeRise != domeRise;
}

