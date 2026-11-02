import 'package:flutter/material.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/app_colors.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/app_radius.dart';
import 'package:cheapest_go_mobile/shared/utils/format.dart';

/// Small uppercase label (v1 `text-ui-label`).
class UiLabel extends StatelessWidget {
  const UiLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.2,
        color: context.colors.label,
      ),
    );
  }
}

/// White (or dark-grey) card with a hairline border and 16 px corners.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.onTap,
    this.color,
    this.borderColor,
    this.borderWidth = 1,
    this.clip = false,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;

  /// Clip children to the rounded corners (for edge-to-edge photos).
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final shape = RoundedRectangleBorder(
      borderRadius: AppRadius.brCard,
      side: BorderSide(color: borderColor ?? c.border, width: borderWidth),
    );
    return Material(
      color: color ?? c.surface,
      shape: shape,
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Blue score box, e.g. `8.7`.
class RatingBadge extends StatelessWidget {
  const RatingBadge(this.score, {super.key});

  final double score;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(AppRadius.xs)),
      child: Text(
        score.toStringAsFixed(1),
        style: TextStyle(color: c.accentOn, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}

/// Tinted box standing in for a photo until real images arrive.
class PhotoPlaceholder extends StatelessWidget {
  const PhotoPlaceholder({
    this.label = 'Photo',
    this.width,
    this.height,
    this.radius = AppRadius.md,
    this.golf = false,
    this.fade = false,
    super.key,
  });

  final String label;
  final double? width;
  final double? height;
  final double radius;
  final bool golf;

  /// Darken the bottom edge, as v1 cards do under overlaid text.
  final bool fade;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: golf ? c.golfSoft : c.photo),
            Center(
              child: Text(
                label,
                style: TextStyle(fontSize: 11, color: golf ? c.onGolfSoft : c.onPhoto),
              ),
            ),
            if (fade)
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                    colors: [Color(0x59000000), Color(0x00000000)],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Two-to-four option switch on a grey track.
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    required this.labels,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: AppRadius.brMd),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Semantics(
                selected: i == selected,
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == selected ? c.surface : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: i == selected
                          ? const [BoxShadow(color: Color(0x14000000), blurRadius: 2, offset: Offset(0, 1))]
                          : null,
                    ),
                    child: Text(
                      labels[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: i == selected ? FontWeight.w600 : FontWeight.w500,
                        color: i == selected ? c.accent : c.textSecondary,
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

/// Rounded filter or quick-pick chip.
class FilterPill extends StatelessWidget {
  const FilterPill({
    required this.label,
    required this.onTap,
    this.selected = false,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? c.secondary : c.surface,
        shape: StadiumBorder(side: BorderSide(color: selected ? c.accent : c.border)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 36),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: c.label),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? c.onSecondary : c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Grey amenity tag.
class TagChip extends StatelessWidget {
  const TagChip(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(fontSize: 11, color: c.textSecondary)),
    );
  }
}

/// Green pill for confirmed bookings and refundable rates.
class StatusPill extends StatelessWidget {
  const StatusPill(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: c.successSoft, borderRadius: AppRadius.brPill),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c.onSuccessSoft)),
    );
  }
}

/// 44 px round icon button, used for back and save.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surface,
      shape: CircleBorder(side: BorderSide(color: c.border)),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: 20, color: color ?? c.textPrimary),
        constraints: const BoxConstraints.tightFor(width: 44, height: 44),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

/// Bold blue price with an optional muted suffix, e.g. `₱4,850 /night`.
class PriceText extends StatelessWidget {
  const PriceText(this.amount, {this.suffix, this.size = 16, super.key});

  final int amount;
  final String? suffix;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: formatPeso(amount),
            style: TextStyle(fontSize: size, fontWeight: FontWeight.w700, color: c.accent),
          ),
          if (suffix != null)
            TextSpan(
              text: ' $suffix',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: c.textMuted),
            ),
        ],
      ),
    );
  }
}

/// Fixed bottom bar holding the screen's main action.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surfaceElevated,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 12), child: child),
      ),
    );
  }
}

/// Location line with a blue pin, e.g. `0.4 km from Terminal 3`.
class PinLine extends StatelessWidget {
  const PinLine(this.text, {this.icon = Icons.place_outlined, super.key});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Icon(icon, size: 13, color: c.accent),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: c.textMuted),
          ),
        ),
      ],
    );
  }
}

/// Centered message for empty lists.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: c.secondary, shape: BoxShape.circle),
            child: Icon(icon, color: c.accent),
          ),
          const SizedBox(height: 14),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: c.textMuted)),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}
