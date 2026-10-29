import 'dart:ui';
import 'package:flutter/material.dart';

/// Design tokens — elevation, shadows, blur, glow, and gradients.
class AppEffects {
  AppEffects._();

  /// Standard blur for glassmorphic surfaces.
  static const double glassBlur = 16.0;

  static ImageFilter get glassFilter =>
      ImageFilter.blur(sigmaX: glassBlur, sigmaY: glassBlur);

  /// Subtle, crisp shadow for cards on light backgrounds.
  static List<BoxShadow> get cardShadowLight => const [
        BoxShadow(
          color: Color(0x0A0F172A),
          blurRadius: 16,
          offset: Offset(0, 4),
        ),
        BoxShadow(
          color: Color(0x050F172A),
          blurRadius: 4,
          offset: Offset(0, 1),
        ),
      ];

  /// Elevated shadow for floating dialogs, bottom sheets, and hero cards.
  static List<BoxShadow> get premiumShadow => const [
        BoxShadow(
          color: Color(0x140F172A),
          blurRadius: 28,
          offset: Offset(0, 10),
        ),
      ];

  /// Subtle glow for primary CTA buttons.
  static List<BoxShadow> buttonGlow(Color accent) => [
        BoxShadow(
          color: accent.withValues(alpha: 0.25),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ];

  /// Linear gradient for primary hero cards.
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0F172A), // Deep Slate Obsidian
      Color(0xFF1E293B),
      Color(0xFF0B192C),
    ],
  );

  /// Subtle glass sheen across cards.
  static const LinearGradient cardSheen = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x08FFFFFF),
      Color(0x00FFFFFF),
    ],
  );
}

