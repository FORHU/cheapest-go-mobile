import 'package:flutter/material.dart';

/// Design tokens — corner radii.
class AppRadius {
  AppRadius._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double card = 18.0;
  static const double sheet = 24.0;
  static const double pill = 999.0;

  static BorderRadius get brSm => BorderRadius.circular(sm);
  static BorderRadius get brMd => BorderRadius.circular(md);
  static BorderRadius get brCard => BorderRadius.circular(card);
  static BorderRadius get brSheet => BorderRadius.circular(sheet);
  static BorderRadius get brPill => BorderRadius.circular(pill);
}

