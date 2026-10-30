import 'package:flutter/material.dart';
import 'package:cheapest_go_mobile/features/map/models/map_models.dart';

/// 2D / 3D Map Tier Toggle Switch + Optional Light/Dark Theme Switch
///
/// Inspired by `gate-closes-app-v2/lib/core/services/map_tier.dart`
/// Allows users to switch smoothly between 2D Lite Map Projection and 3D Standard Globe,
/// as well as toggle between Light & Dark map themes.
class MapTierToggle extends StatelessWidget {
  const MapTierToggle({
    required this.currentTier,
    required this.onTierChanged,
    this.mapThemeMode = MapThemeMode.dark,
    this.onThemeModeChanged,
    this.is3dSupported = true,
    this.no3dReasonText,
    super.key,
  });

  final MapTier currentTier;
  final ValueChanged<MapTier> onTierChanged;
  final MapThemeMode mapThemeMode;
  final ValueChanged<MapThemeMode>? onThemeModeChanged;
  final bool is3dSupported;
  final String? no3dReasonText;

  @override
  Widget build(BuildContext context) {
    final is3D = currentTier == MapTier.standard;
    final isDark = mapThemeMode == MapThemeMode.dark;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF3FE1FD).withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOption(
            context: context,
            label: '2D Lite',
            icon: Icons.map_outlined,
            isSelected: !is3D,
            isEnabled: true,
            onTap: () => onTierChanged(MapTier.lite),
          ),
          const SizedBox(width: 2),
          _buildOption(
            context: context,
            label: '3D Globe',
            icon: is3dSupported ? Icons.language : Icons.lock_outline,
            isSelected: is3D && is3dSupported,
            isEnabled: is3dSupported,
            onTap: () => onTierChanged(MapTier.standard),
          ),
          if (onThemeModeChanged != null) ...[
            Container(
              height: 18,
              width: 1,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: Colors.white.withValues(alpha: 0.2),
            ),
            Tooltip(
              message: isDark ? 'Switch to Light Map' : 'Switch to Dark Map',
              child: GestureDetector(
                onTap: () {
                  onThemeModeChanged!(
                    isDark ? MapThemeMode.light : MapThemeMode.dark,
                  );
                },
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                        size: 14,
                        color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF3FE1FD),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isDark ? 'Light' : 'Dark',
                        style: const TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: !isEnabled && no3dReasonText != null ? no3dReasonText! : label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF004AC6)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF3FE1FD).withValues(alpha: 0.35),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: !isEnabled
                    ? const Color(0xFFF59E0B)
                    : (isSelected ? const Color(0xFF3FE1FD) : const Color(0xFF94A3B8)),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: !isEnabled
                      ? const Color(0xFF94A3B8)
                      : (isSelected ? Colors.white : const Color(0xFFCBD5E1)),
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
