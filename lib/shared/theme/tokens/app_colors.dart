import 'package:flutter/material.dart';

/// Design tokens — colors for CheapestGo Mobile.
///
/// Paired with the v2 web palette (`cheapestgo-app-v2/src/shared/lib/palette.ts`):
/// slate neutrals on an alabaster ground, obsidian + slate-900 in dark, and the
/// blue family (600 light, 500 / 400 dark) for everything interactive.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.backgroundCanvas,
    required this.surface,
    required this.surfaceElevated,
    required this.surfacePressed,
    required this.surfaceMuted,
    required this.glass,
    required this.glassStrong,
    required this.accent,
    required this.accentOn,
    required this.accentGlow15,
    required this.accentGlow20,
    required this.accentWarm,
    required this.accentDark,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textSubtle,
    required this.label,
    required this.border,
    required this.borderStrong,
    required this.hairline,
    required this.photo,
    required this.onPhoto,
    required this.golfSoft,
    required this.onGolfSoft,
    required this.successSoft,
    required this.onSuccessSoft,
    required this.error,
    required this.success,
    required this.warning,
  });

  /// App/scaffold background (v1 `surface-gray`).
  final Color background;

  /// Grouped background canvas.
  final Color backgroundCanvas;

  /// Card/surface fill (v1 `card`).
  final Color surface;

  /// Elevated surface (sheets, bars).
  final Color surfaceElevated;

  /// Surface while pressed.
  final Color surfacePressed;

  /// Segmented control track and tag fill (v1 `muted`).
  final Color surfaceMuted;

  /// Frosted glass tint, used only over the map.
  final Color glass;

  /// Dense frosted glass for floating navigation and headers.
  final Color glassStrong;

  /// Brand primary (v1 `primary`).
  final Color accent;

  /// Foreground on accent fills.
  final Color accentOn;

  final Color accentGlow15;
  final Color accentGlow20;

  /// Warm accent for rating stars.
  final Color accentWarm;

  /// Obsidian hero surface (v1 `obsidian`).
  final Color accentDark;

  /// Soft blue fill for secondary buttons and highlights (v1 `secondary`).
  final Color secondary;

  /// Text on [secondary] (v1 `secondary-foreground`).
  final Color onSecondary;

  /// Border for [secondary] surfaces.
  final Color secondaryBorder;

  /// Primary text (v1 `foreground`).
  final Color textPrimary;

  /// Secondary text.
  final Color textSecondary;

  /// Muted helper text (v1 `muted-foreground`).
  final Color textMuted;

  /// Low-emphasis text / disabled state.
  final Color textSubtle;

  /// Uppercase micro label (v1 `text-ui-label`).
  final Color label;

  /// Hairline border (v1 `border`).
  final Color border;

  /// Strong border for focused cards.
  final Color borderStrong;

  /// Ultra-fine divider.
  final Color hairline;

  /// Photo placeholder fill and its text.
  final Color photo;
  final Color onPhoto;

  /// Golf course placeholder fill and its text.
  final Color golfSoft;
  final Color onGolfSoft;

  /// Confirmed / refundable pill fill and its text.
  final Color successSoft;
  final Color onSuccessSoft;

  final Color error;
  final Color success;
  final Color warning;

  static const light = AppColors(
    background: Color(0xFFF8FAFC),
    backgroundCanvas: Color(0xFFF1F5F9),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFFFFFF),
    surfacePressed: Color(0xFFF1F5F9),
    surfaceMuted: Color(0xFFF1F5F9),
    glass: Color(0xB3FFFFFF),
    glassStrong: Color(0xF2FFFFFF),
    accent: Color(0xFF2563EB),
    accentOn: Color(0xFFFFFFFF),
    accentGlow15: Color(0x262563EB),
    accentGlow20: Color(0x332563EB),
    accentWarm: Color(0xFFF59E0B),
    accentDark: Color(0xFF020617),
    secondary: Color(0xFFEFF6FF),
    onSecondary: Color(0xFF1E3A8A),
    secondaryBorder: Color(0xFFBFDBFE),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF334155),
    textMuted: Color(0xFF64748B),
    textSubtle: Color(0xFF94A3B8),
    label: Color(0xFF64748B),
    border: Color(0xFFE2E8F0),
    borderStrong: Color(0xFFCBD5E1),
    hairline: Color(0xFFF1F5F9),
    photo: Color(0xFFDBEAFE),
    onPhoto: Color(0xFF1E3A8A),
    golfSoft: Color(0xFFDCFCE7),
    onGolfSoft: Color(0xFF166534),
    successSoft: Color(0xFFDCFCE7),
    onSuccessSoft: Color(0xFF166534),
    error: Color(0xFFDC2626),
    success: Color(0xFF047857),
    warning: Color(0xFFB45309),
  );

  static const dark = AppColors(
    background: Color(0xFF020617),
    backgroundCanvas: Color(0xFF020617),
    surface: Color(0xFF0F172A),
    surfaceElevated: Color(0xFF0F172A),
    surfacePressed: Color(0xFF1E293B),
    surfaceMuted: Color(0xFF1E293B),
    glass: Color(0x0DFFFFFF),
    glassStrong: Color(0xF20F172A),
    accent: Color(0xFF3B82F6),
    accentOn: Color(0xFFFFFFFF),
    accentGlow15: Color(0x263B82F6),
    accentGlow20: Color(0x333B82F6),
    accentWarm: Color(0xFFFBBF24),
    accentDark: Color(0xFF020617),
    secondary: Color(0xFF172554),
    onSecondary: Color(0xFFBFDBFE),
    secondaryBorder: Color(0xFF1E3A8A),
    textPrimary: Color(0xFFF1F5F9),
    textSecondary: Color(0xFFCBD5E1),
    textMuted: Color(0xFF94A3B8),
    textSubtle: Color(0xFF64748B),
    label: Color(0xFF94A3B8),
    border: Color(0x1AFFFFFF),
    borderStrong: Color(0x26FFFFFF),
    hairline: Color(0x14FFFFFF),
    photo: Color(0xFF1E293B),
    onPhoto: Color(0xFFBFDBFE),
    golfSoft: Color(0xFF14532D),
    onGolfSoft: Color(0xFFBBF7D0),
    successSoft: Color(0xFF14532D),
    onSuccessSoft: Color(0xFFBBF7D0),
    error: Color(0xFFF87171),
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? backgroundCanvas,
    Color? surface,
    Color? surfaceElevated,
    Color? surfacePressed,
    Color? surfaceMuted,
    Color? glass,
    Color? glassStrong,
    Color? accent,
    Color? accentOn,
    Color? accentGlow15,
    Color? accentGlow20,
    Color? accentWarm,
    Color? accentDark,
    Color? secondary,
    Color? onSecondary,
    Color? secondaryBorder,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textSubtle,
    Color? label,
    Color? border,
    Color? borderStrong,
    Color? hairline,
    Color? photo,
    Color? onPhoto,
    Color? golfSoft,
    Color? onGolfSoft,
    Color? successSoft,
    Color? onSuccessSoft,
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
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      glass: glass ?? this.glass,
      glassStrong: glassStrong ?? this.glassStrong,
      accent: accent ?? this.accent,
      accentOn: accentOn ?? this.accentOn,
      accentGlow15: accentGlow15 ?? this.accentGlow15,
      accentGlow20: accentGlow20 ?? this.accentGlow20,
      accentWarm: accentWarm ?? this.accentWarm,
      accentDark: accentDark ?? this.accentDark,
      secondary: secondary ?? this.secondary,
      onSecondary: onSecondary ?? this.onSecondary,
      secondaryBorder: secondaryBorder ?? this.secondaryBorder,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textSubtle: textSubtle ?? this.textSubtle,
      label: label ?? this.label,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      hairline: hairline ?? this.hairline,
      photo: photo ?? this.photo,
      onPhoto: onPhoto ?? this.onPhoto,
      golfSoft: golfSoft ?? this.golfSoft,
      onGolfSoft: onGolfSoft ?? this.onGolfSoft,
      successSoft: successSoft ?? this.successSoft,
      onSuccessSoft: onSuccessSoft ?? this.onSuccessSoft,
      error: error ?? this.error,
      success: success ?? this.success,
      warning: warning ?? this.warning,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      background: l(background, other.background),
      backgroundCanvas: l(backgroundCanvas, other.backgroundCanvas),
      surface: l(surface, other.surface),
      surfaceElevated: l(surfaceElevated, other.surfaceElevated),
      surfacePressed: l(surfacePressed, other.surfacePressed),
      surfaceMuted: l(surfaceMuted, other.surfaceMuted),
      glass: l(glass, other.glass),
      glassStrong: l(glassStrong, other.glassStrong),
      accent: l(accent, other.accent),
      accentOn: l(accentOn, other.accentOn),
      accentGlow15: l(accentGlow15, other.accentGlow15),
      accentGlow20: l(accentGlow20, other.accentGlow20),
      accentWarm: l(accentWarm, other.accentWarm),
      accentDark: l(accentDark, other.accentDark),
      secondary: l(secondary, other.secondary),
      onSecondary: l(onSecondary, other.onSecondary),
      secondaryBorder: l(secondaryBorder, other.secondaryBorder),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textMuted: l(textMuted, other.textMuted),
      textSubtle: l(textSubtle, other.textSubtle),
      label: l(label, other.label),
      border: l(border, other.border),
      borderStrong: l(borderStrong, other.borderStrong),
      hairline: l(hairline, other.hairline),
      photo: l(photo, other.photo),
      onPhoto: l(onPhoto, other.onPhoto),
      golfSoft: l(golfSoft, other.golfSoft),
      onGolfSoft: l(onGolfSoft, other.onGolfSoft),
      successSoft: l(successSoft, other.successSoft),
      onSuccessSoft: l(onSuccessSoft, other.onSuccessSoft),
      error: l(error, other.error),
      success: l(success, other.success),
      warning: l(warning, other.warning),
    );
  }
}

/// v2's one brand gradient, blue-600 → cyan-500, for the main action on a
/// screen (pay, book, select) and nothing else.
const LinearGradient kBrandGradient = LinearGradient(
  colors: [Color(0xFF2563EB), Color(0xFF06B6D4)],
);

extension AppColorsContextX on BuildContext {
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;
}
