import 'package:flutter/material.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/app_colors.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/app_effects.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/app_radius.dart';

/// A floating, softly shadowed card surface adapted from gate-closes-app-v2.
/// Features a crisp hairline border, gentle shadow, and optional frosted glass blur.
class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = AppRadius.card,
    this.blur = false,
    this.border = true,
    this.borderColor,
    this.color,
    this.onTap,
    this.accentStripe,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool blur;
  final bool border;
  final Color? borderColor;
  final Color? color;
  final VoidCallback? onTap;
  final Color? accentStripe;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final borderRadius = BorderRadius.circular(radius);
    final surfaceColor = color ?? (blur ? colors.glass : colors.surface);
    final borderLine = borderColor ?? colors.border;

    Widget body = Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: surfaceColor)),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: AppEffects.cardSheen),
          ),
        ),
        if (accentStripe != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 3,
            child: ColoredBox(color: accentStripe!),
          ),
        Padding(padding: padding, child: child),
      ],
    );

    if (blur) {
      body = BackdropFilter(filter: AppEffects.glassFilter, child: body);
    }

    if (onTap != null) {
      body = Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          child: body,
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: AppEffects.cardShadowLight,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: border ? Border.all(color: borderLine, width: 0.8) : null,
          ),
          child: body,
        ),
      ),
    );
  }
}
