import 'package:flutter/material.dart';

/// Design tokens — colors for CheapestGo Mobile.
///
/// Refactored to align with the minimalist, high-contrast, frosted-glass
/// aesthetic evaluated from gate-closes-app-v2.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.backgroundCanvas,
    required this.surface,
    required this.surfaceElevated,
    required this.surfacePressed,
    required this.glass,
    required this.glassStrong,
    required this.accent,
    required this.accentOn,
    required this.accentGlow15,
    required this.accentGlow20,
    required this.accentWarm,
    required this.accentDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textSubtle,
    required this.border,
    required this.borderStrong,
    required this.hairline,
    required this.error,
    required this.success,
    required this.warning,
  });

  /// App/scaffold background canvas.
  final Color background;

  /// Grouped background canvas.
  final Color backgroundCanvas;

  /// Card/surface fill.
  final Color surface;

  /// Elevated surface.
  final Color surfaceElevated;

  /// Surface while pressed.
  final Color surfacePressed;

  /// Frosted glass tint.
  final Color glass;

  /// Dense frosted glass for floating navigation and headers.
  final Color glassStrong;

  /// CheapestGo brand accent: electric royal cobalt.
  final Color accent;

  /// Foreground on accent fills.
  final Color accentOn;

  final Color accentGlow15;
  final Color accentGlow20;

  /// Warm accent (amber gold) for verified deals and rating stars.
  final Color accentWarm;

  /// Obsidian / midnight slate for hero surfaces.
  final Color accentDark;

  /// Primary high-contrast text (Slate 900).
  final Color textPrimary;

  /// Secondary text (Slate 600).
  final Color textSecondary;

  /// Muted helper text (Slate 400).
  final Color textMuted;

  /// Low-emphasis text / disabled state.
  final Color textSubtle;

  /// Crisp hairline border.
  final Color border;

  /// Strong border for focused cards.
  final Color borderStrong;

  /// Ultra-fine hairline for glass edges.
  final Color hairline;

  final Color error;
  final Color success;
  final Color warning;

  /// Default Light Theme: crisp, clean, breathable canvas with crisp obsidian text.
  static const light = AppColors(
    background: Color(0xFFF8FAFC),
    backgroundCanvas: Color(0xFFF1F5F9),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFFFFFF),
    surfacePressed: Color(0xFFF1F5F9),
    glass: Color(0xD9FFFFFF),
    glassStrong: Color(0xF2FFFFFF),
    accent: Color(0xFF0052FF),
    accentOn: Color(0xFFFFFFFF),
    accentGlow15: Color(0x260052FF),
    accentGlow20: Color(0x330052FF),
    accentWarm: Color(0xFFF59E0B),
    accentDark: Color(0xFF0B132B),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF475569),
    textMuted: Color(0xFF94A3B8),
    textSubtle: Color(0xFFCBD5E1),
    border: Color(0xFFE2E8F0),
    borderStrong: Color(0xFFCBD5E1),
    hairline: Color(0x140F172A),
    error: Color(0xFFEF4444),
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? backgroundCanvas,
    Color? surface,
    Color? surfaceElevated,
    Color? surfacePressed,
    Color? glass,
    Color? glassStrong,
    Color? accent,
    Color? accentOn,
    Color? accentGlow15,
    Color? accentGlow20,
    Color? accentWarm,
    Color? accentDark,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textSubtle,
    Color? border,
    Color? borderStrong,
    Color? hairline,
    Color? error,
    Color? success,
    Color? warning,
  }) {
    return AppColors(
      background: background ?? this.background,
      backgroundCanvas: backgroundCanvas ?? this.backgroundCanvas,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfacePressed: surfacePressed ?? this.surfacePressed,
      glass: glass ?? this.glass,
      glassStrong: glassStrong ?? this.glassStrong,
      accent: accent ?? this.accent,
      accentOn: accentOn ?? this.accentOn,
      accentGlow15: accentGlow15 ?? this.accentGlow15,
      accentGlow20: accentGlow20 ?? this.accentGlow20,
      accentWarm: accentWarm ?? this.accentWarm,
      accentDark: accentDark ?? this.accentDark,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textSubtle: textSubtle ?? this.textSubtle,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      hairline: hairline ?? this.hairline,
      error: error ?? this.error,
      success: success ?? this.success,
      warning: warning ?? this.warning,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      backgroundCanvas: Color.lerp(backgroundCanvas, other.backgroundCanvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      surfacePressed: Color.lerp(surfacePressed, other.surfacePressed, t)!,
      glass: Color.lerp(glass, other.glass, t)!,
      glassStrong: Color.lerp(glassStrong, other.glassStrong, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentOn: Color.lerp(accentOn, other.accentOn, t)!,
      accentGlow15: Color.lerp(accentGlow15, other.accentGlow15, t)!,
      accentGlow20: Color.lerp(accentGlow20, other.accentGlow20, t)!,
      accentWarm: Color.lerp(accentWarm, other.accentWarm, t)!,
      accentDark: Color.lerp(accentDark, other.accentDark, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textSubtle: Color.lerp(textSubtle, other.textSubtle, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      error: Color.lerp(error, other.error, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

extension AppColorsContextX on BuildContext {
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;
}

