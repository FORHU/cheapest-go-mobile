import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/app_colors.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/app_radius.dart';

export 'package:cheapest_go_mobile/shared/theme/tokens/app_colors.dart';
export 'package:cheapest_go_mobile/shared/theme/tokens/app_effects.dart';
export 'package:cheapest_go_mobile/shared/theme/tokens/app_radius.dart';
export 'package:cheapest_go_mobile/shared/theme/tokens/app_spacing.dart';

/// Legacy color mappings retained for backward compatibility while forwarding
/// to the refined AppColors tokens.
class KineticHorizonColors {
  const KineticHorizonColors._();

  static const primary = Color(0xFF0052FF);
  static const primaryContainer = Color(0xFF1D4ED8);
  static const onPrimary = Color(0xFFFFFFFF);
  static const onPrimaryContainer = Color(0xFFEFF6FF);
  static const primaryFixed = Color(0xFFDBEAFE);
  static const primaryFixedDim = Color(0xFF93C5FD);

  static const secondary = Color(0xFF0F172A);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFF1E293B);
  static const onSecondaryContainer = Color(0xFFF8FAFC);
  static const secondaryFixed = Color(0xFFE2E8F0);
  static const secondaryFixedDim = Color(0xFFCBD5E1);

  static const tertiary = Color(0xFF0D9488);
  static const onTertiary = Color(0xFFFFFFFF);
  static const tertiaryContainer = Color(0xFF14B8A6);
  static const onTertiaryContainer = Color(0xFFCCFBF1);
  static const tertiaryFixed = Color(0xFF99F6E4);
  static const tertiaryFixedDim = Color(0xFF5EEAD4);

  static const surface = Color(0xFFF8FAFC);
  static const surfaceDim = Color(0xFFF1F5F9);
  static const surfaceBright = Color(0xFFFFFFFF);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF8FAFC);
  static const surfaceContainer = Color(0xFFF1F5F9);
  static const surfaceContainerHigh = Color(0xFFE2E8F0);
  static const surfaceContainerHighest = Color(0xFFCBD5E1);
  static const surfaceSlate = Color(0xFFF8FAFC);
  static const surfaceVariant = Color(0xFFF1F5F9);

  static const onSurface = Color(0xFF0F172A);
  static const onSurfaceVariant = Color(0xFF475569);
  static const inverseSurface = Color(0xFF0F172A);
  static const inverseOnSurface = Color(0xFFF8FAFC);

  static const borderSubtle = Color(0xFFE2E8F0);
  static const outline = Color(0xFF94A3B8);
  static const outlineVariant = Color(0xFFE2E8F0);
  static const textMuted = Color(0xFF64748B);

  static const dealCoral = Color(0xFFF43F5E);
  static const amberWarning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const onError = Color(0xFFFFFFFF);
}

class AppTheme {
  static TextStyle headlineXl({Color color = const Color(0xFF0F172A)}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        height: 38 / 32,
        letterSpacing: -0.03 * 32,
        color: color,
      );

  static TextStyle headlineXlMobile({
    Color color = const Color(0xFF0F172A),
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        height: 32 / 26,
        letterSpacing: -0.02 * 26,
        color: color,
      );

  static TextStyle headlineLgMobile({
    Color color = const Color(0xFF0F172A),
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 28 / 22,
        letterSpacing: -0.01 * 22,
        color: color,
      );

  static TextStyle headlineMd({Color color = const Color(0xFF0F172A)}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 24 / 18,
        letterSpacing: -0.01 * 18,
        color: color,
      );

  static TextStyle headlineSm({Color color = const Color(0xFF0F172A)}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 22 / 16,
        color: color,
      );

  static TextStyle priceDisplay({
    Color color = const Color(0xFF0052FF),
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        height: 26 / 22,
        letterSpacing: -0.02 * 22,
        color: color,
      );

  static TextStyle bodyLg({Color color = const Color(0xFF0F172A)}) =>
      GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
        color: color,
      );

  static TextStyle bodyMd({Color color = const Color(0xFF334155)}) =>
      GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
        color: color,
      );

  static TextStyle bodySm({Color color = const Color(0xFF64748B)}) =>
      GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 16 / 12,
        color: color,
      );

  static TextStyle labelMd({Color color = const Color(0xFF0F172A)}) =>
      GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 18 / 13,
        letterSpacing: 0.01 * 13,
        color: color,
      );

  static TextStyle labelSm({Color color = const Color(0xFF64748B)}) =>
      GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 14 / 11,
        letterSpacing: 0.02 * 11,
        color: color,
      );

  static TextStyle codeFlight({
    Color color = const Color(0xFF0052FF),
  }) =>
      GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 18 / 14,
        letterSpacing: 0.05 * 14,
        color: color,
      );

  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF0052FF),
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFEFF6FF),
      onPrimaryContainer: Color(0xFF1D4ED8),
      secondary: Color(0xFF0F172A),
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFF1F5F9),
      onSecondaryContainer: Color(0xFF0F172A),
      tertiary: Color(0xFF0D9488),
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFCCFBF1),
      onTertiaryContainer: Color(0xFF115E59),
      error: Color(0xFFEF4444),
      onError: Colors.white,
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF0F172A),
      onSurfaceVariant: Color(0xFF475569),
      outline: Color(0xFFCBD5E1),
      outlineVariant: Color(0xFFE2E8F0),
      shadow: Color(0x0A0F172A),
      scrim: Color(0x66000000),
      inverseSurface: Color(0xFF0F172A),
      onInverseSurface: Color(0xFFF8FAFC),
      inversePrimary: Color(0xFF93C5FD),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.light.background,
      extensions: const [AppColors.light],
      textTheme: TextTheme(
        headlineLarge: headlineXlMobile(),
        headlineMedium: headlineMd(),
        headlineSmall: headlineSm(),
        bodyLarge: bodyLg(),
        bodyMedium: bodyMd(),
        bodySmall: bodySm(),
        labelLarge: labelMd(),
        labelSmall: labelSm(),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.light.background,
        foregroundColor: AppColors.light.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: headlineSm(color: AppColors.light.textPrimary).copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.light.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brCard,
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 0.8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.light.accent,
          foregroundColor: AppColors.light.accentOn,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.brPill,
          ),
          textStyle: labelMd(color: AppColors.light.accentOn),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.light.glassStrong,
        indicatorColor: AppColors.light.accent.withValues(alpha: 0.1),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return labelSm(color: AppColors.light.accent).copyWith(
              fontWeight: FontWeight.w700,
            );
          }
          return labelSm(color: AppColors.light.textSecondary);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: AppColors.light.accent, size: 22);
          }
          return IconThemeData(
            color: AppColors.light.textSecondary,
            size: 22,
          );
        }),
      ),
    );
  }

  static ThemeData get dark => light;
}
