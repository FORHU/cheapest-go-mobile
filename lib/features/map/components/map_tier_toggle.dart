import 'package:flutter/material.dart';
import 'package:cheapest_go_mobile/features/map/models/map_models.dart';

/// 2D / 3D Map Tier Toggle Switch
///
/// Inspired by `gate-closes-app-v2/lib/core/services/map_tier.dart`
/// Allows users to switch smoothly between 2D Lite Map Projection and 3D Standard Globe.
class MapTierToggle extends StatelessWidget {
  const MapTierToggle({
    required this.currentTier,
    required this.onTierChanged,
    super.key,
  });

  final MapTier currentTier;
  final ValueChanged<MapTier> onTierChanged;

  @override
  Widget build(BuildContext context) {
    final is3D = currentTier == MapTier.standard;

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
            label: '2D Lite',
            icon: Icons.map_outlined,
            isSelected: !is3D,
            onTap: () => onTierChanged(MapTier.lite),
          ),
          const SizedBox(width: 2),
          _buildOption(
            label: '3D Globe',
            icon: Icons.language,
            isSelected: is3D,
            onTap: () => onTierChanged(MapTier.standard),
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
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
              color: isSelected ? const Color(0xFF3FE1FD) : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

