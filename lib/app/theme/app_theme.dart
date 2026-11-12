import 'package:flutter/material.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/generated/tw_scale.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/app_colors.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/app_radius.dart';

export 'package:cheapest_go_mobile/shared/theme/tokens/app_colors.dart';
export 'package:cheapest_go_mobile/shared/theme/tokens/app_effects.dart';
export 'package:cheapest_go_mobile/shared/theme/tokens/app_radius.dart';
export 'package:cheapest_go_mobile/shared/theme/tokens/app_spacing.dart';

/// Light and dark Material themes paired with the v2 web app: Plus Jakarta Sans
/// throughout, bold and tightly tracked for display text.
class AppTheme {
  const AppTheme._();

  static ThemeData get light => _build(AppColors.light, Brightness.light);
  static ThemeData get dark => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors c, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.accent,
      onPrimary: c.accentOn,
      primaryContainer: c.secondary,
      onPrimaryContainer: c.onSecondary,
      secondary: c.accent,
      onSecondary: c.accentOn,
      secondaryContainer: c.secondary,
      onSecondaryContainer: c.onSecondary,
      tertiary: c.success,
      onTertiary: c.accentOn,
      error: c.error,
      onError: Colors.white,
      surface: c.surface,
      onSurface: c.textPrimary,
      onSurfaceVariant: c.textMuted,
      surfaceContainerLowest: c.background,
      surfaceContainerLow: c.surface,
      surfaceContainer: c.surface,
      surfaceContainerHigh: c.surfaceElevated,
      surfaceContainerHighest: c.surfaceMuted,
      outline: c.borderStrong,
      outlineVariant: c.border,
      shadow: Colors.black,
      scrim: const Color(0x99000000),
      inverseSurface: c.textPrimary,
      onInverseSurface: c.surface,
      inversePrimary: c.secondaryBorder,
    );

    final base = ThemeData(useMaterial3: true, brightness: brightness);
    // Bundled, not fetched. google_fonts pulls the file from Google on first use, so an app
    // opened on a plane draws itself in whatever fallback the handset has — see docs/adr/0002.
    final body = base.textTheme.apply(
      fontFamily: TwFonts.sans,
      bodyColor: c.textPrimary,
      displayColor: c.textPrimary,
    );
    TextStyle display(double size) => TextStyle(
          fontFamily: TwFonts.sans,
          fontSize: size,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.02 * size,
          height: 1.15,
          color: c.textPrimary,
        );

    final textTheme = body.copyWith(
      displaySmall: display(32),
      headlineLarge: display(28),
      headlineMedium: display(24),
      headlineSmall: display(20),
      titleLarge: display(18),
      titleMedium: body.titleMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
      titleSmall: body.titleSmall?.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
      bodyLarge: body.bodyLarge?.copyWith(fontSize: 15),
      bodyMedium: body.bodyMedium?.copyWith(fontSize: 14),
      bodySmall: body.bodySmall?.copyWith(fontSize: 12, color: c.textMuted),
      labelLarge: body.labelLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
      labelMedium: body.labelMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
      labelSmall: body.labelSmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w500),
    );

    final buttonShape = RoundedRectangleBorder(borderRadius: AppRadius.brMd);
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.base),
      borderSide: BorderSide(color: c.border),
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      extensions: [c],
      textTheme: textTheme,
      dividerColor: c.hairline,
      dividerTheme: DividerThemeData(color: c.hairline, space: 1, thickness: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: display(20),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brCard,
          side: BorderSide(color: c.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: c.accentOn,
          minimumSize: const Size(64, 48),
          shape: buttonShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: c.accentOn,
          elevation: 0,
          minimumSize: const Size(64, 48),
          shape: buttonShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.onSecondary,
          backgroundColor: c.secondary,
          side: BorderSide(color: c.secondaryBorder),
          minimumSize: const Size(64, 44),
          shape: buttonShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: c.accent, textStyle: textTheme.labelMedium),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(borderSide: BorderSide(color: c.accent, width: 1.5)),
        labelStyle: TextStyle(color: c.textSecondary),
        hintStyle: TextStyle(color: c.textSubtle),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: c.borderStrong,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.textPrimary,
        contentTextStyle: TextStyle(color: c.surface, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
      ),
      listTileTheme: ListTileThemeData(iconColor: c.textSecondary, textColor: c.textPrimary),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: c.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        rangeSelectionBackgroundColor: c.secondary,
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.accent : c.borderStrong,
        ),
      ),
    );
  }
}
