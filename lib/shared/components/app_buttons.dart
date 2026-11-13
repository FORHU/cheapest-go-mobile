import 'package:flutter/material.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/app_colors.dart';

/// v2's gradient pill (blue-600 → cyan-500) for the one action that matters on
/// a screen: pay, book, select. Use [AppPrimaryButton] everywhere else.
class AppGradientButton extends StatelessWidget {
  const AppGradientButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.height = 52,
    this.compact = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final double height;

  /// A panel's action rather than the screen's.
  ///
  /// Same gradient, quieter: smaller type and a shadow that sits the control on the card
  /// instead of lifting it off the page. At full size inside a panel it reads as the most
  /// important thing on screen, which it is not — "Save request" is not "Pay".
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    return Semantics(
      button: true,
      enabled: enabled,
      child: Opacity(
        opacity: enabled || isLoading ? 1 : 0.5,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: kBrandGradient,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              compact
                  ? const BoxShadow(color: Color(0x332563EB), blurRadius: 8, offset: Offset(0, 2))
                  : const BoxShadow(color: Color(0x592563EB), blurRadius: 20, offset: Offset(0, 8), spreadRadius: -8),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: enabled ? onPressed : null,
              child: SizedBox(
                height: compact ? 38 : height,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    else if (icon != null)
                      Icon(icon, size: 18, color: Colors.white),
                    if (isLoading || icon != null) const SizedBox(width: 8),
                    Flexible(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 4),
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: Colors.white,
                                fontSize: compact ? 14 : 16,
                                fontWeight: compact ? FontWeight.w600 : FontWeight.w700,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Solid blue primary action (v1 `primary`), 48 px tall.
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).colorScheme.onPrimary;
    final button = FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: fg),
            )
          else if (icon != null)
            Icon(icon, size: 18),
          if (isLoading || icon != null) const SizedBox(width: 8),
          Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Soft blue secondary action (v1 `secondary`), 44 px tall.
class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = OutlinedButton(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
          Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
