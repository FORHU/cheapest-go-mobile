// GENERATED — do not edit by hand.
//
// V2's semantic roles, as stated in :root and .dark.
// Mirrored from FORHU/cheapestgo-app-v2 at 78c0c1026710e11a419b2df69c71219c7bdb0a9e
// Regenerate with: dart run tools/sync_design.dart
// See docs/adr/0002-tokens-and-copy-are-generated-from-a-pinned-v2-commit.md

import 'package:flutter/painting.dart';
import 'package:flutter/foundation.dart';

/// The role layer: what a colour is *for*, rather than which stop it is.
///
/// Read these through the theme extension rather than directly, so a widget asks for
/// `roles.primary` and gets the right one for the current theme.
@immutable
class V2Roles {
    const V2Roles({
        required this.accent,
        required this.accentForeground,
        required this.background,
        required this.border,
        required this.card,
        required this.cardForeground,
        required this.chart1,
        required this.chart2,
        required this.chart3,
        required this.chart4,
        required this.chart5,
        required this.destructive,
        required this.foreground,
        required this.input,
        required this.mapCardBg,
        required this.mapCardFg,
        required this.mapCardMuted,
        required this.mapCardWell,
        required this.muted,
        required this.mutedForeground,
        required this.pinBg,
        required this.pinFg,
        required this.pinLine,
        required this.popover,
        required this.popoverForeground,
        required this.primary,
        required this.primaryForeground,
        required this.ring,
        required this.secondary,
        required this.secondaryForeground,
        required this.sidebar,
        required this.sidebarAccent,
        required this.sidebarAccentForeground,
        required this.sidebarBorder,
        required this.sidebarForeground,
        required this.sidebarPrimary,
        required this.sidebarPrimaryForeground,
        required this.sidebarRing,
    });

    /// --accent
    final Color accent;
    /// --accent-foreground
    final Color accentForeground;
    /// --background
    final Color background;
    /// --border
    final Color border;
    /// --card
    final Color card;
    /// --card-foreground
    final Color cardForeground;
    /// --chart-1
    final Color chart1;
    /// --chart-2
    final Color chart2;
    /// --chart-3
    final Color chart3;
    /// --chart-4
    final Color chart4;
    /// --chart-5
    final Color chart5;
    /// --destructive
    final Color destructive;
    /// --foreground
    final Color foreground;
    /// --input
    final Color input;
    /// --map-card-bg
    final Color mapCardBg;
    /// --map-card-fg
    final Color mapCardFg;
    /// --map-card-muted
    final Color mapCardMuted;
    /// --map-card-well
    final Color mapCardWell;
    /// --muted
    final Color muted;
    /// --muted-foreground
    final Color mutedForeground;
    /// --pin-bg
    final Color pinBg;
    /// --pin-fg
    final Color pinFg;
    /// --pin-line
    final Color pinLine;
    /// --popover
    final Color popover;
    /// --popover-foreground
    final Color popoverForeground;
    /// --primary
    final Color primary;
    /// --primary-foreground
    final Color primaryForeground;
    /// --ring
    final Color ring;
    /// --secondary
    final Color secondary;
    /// --secondary-foreground
    final Color secondaryForeground;
    /// --sidebar
    final Color sidebar;
    /// --sidebar-accent
    final Color sidebarAccent;
    /// --sidebar-accent-foreground
    final Color sidebarAccentForeground;
    /// --sidebar-border
    final Color sidebarBorder;
    /// --sidebar-foreground
    final Color sidebarForeground;
    /// --sidebar-primary
    final Color sidebarPrimary;
    /// --sidebar-primary-foreground
    final Color sidebarPrimaryForeground;
    /// --sidebar-ring
    final Color sidebarRing;

    static const light = V2Roles(
        accent: Color(0xFF3B82F6),
        accentForeground: Color(0xFFFFFFFF),
        background: Color(0xFFFFFFFF),
        border: Color(0xFFE5E5E5),
        card: Color(0xFFFFFFFF),
        cardForeground: Color(0xFF0A0A0A),
        chart1: Color(0xFF2563EB),
        chart2: Color(0xFF3B82F6),
        chart3: Color(0xFF60A5FA),
        chart4: Color(0xFF93C5FD),
        chart5: Color(0xFFBFDBFE),
        destructive: Color(0xFFE7000B),
        foreground: Color(0xFF0A0A0A),
        input: Color(0xFFE5E5E5),
        mapCardBg: Color(0xFFFFFFFF),
        mapCardFg: Color(0xFF0F172A),
        mapCardMuted: Color(0xFF64748B),
        mapCardWell: Color(0xFFF1F5F9),
        muted: Color(0xFFF5F5F5),
        mutedForeground: Color(0xFF737373),
        pinBg: Color(0xFFFFFFFF),
        pinFg: Color(0xFF1E293B),
        pinLine: Color(0x29FFFFFF),
        popover: Color(0xFFFFFFFF),
        popoverForeground: Color(0xFF0A0A0A),
        primary: Color(0xFF2563EB),
        primaryForeground: Color(0xFFFFFFFF),
        ring: Color(0xFF60A5FA),
        secondary: Color(0xFFEFF6FF),
        secondaryForeground: Color(0xFF1E3A8A),
        sidebar: Color(0xFFF8FAFC),
        sidebarAccent: Color(0xFFEFF6FF),
        sidebarAccentForeground: Color(0xFF2563EB),
        sidebarBorder: Color(0xFFE5E5E5),
        sidebarForeground: Color(0xFF0A0A0A),
        sidebarPrimary: Color(0xFF2563EB),
        sidebarPrimaryForeground: Color(0xFFFFFFFF),
        sidebarRing: Color(0xFF3B82F6),
    );

    static const dark = V2Roles(
        accent: Color(0xFF60A5FA),
        accentForeground: Color(0xFF171717),
        background: Color(0xFF0A0A0A),
        border: Color(0x1AFFFFFF),
        card: Color(0xFF171717),
        cardForeground: Color(0xFFFAFAFA),
        chart1: Color(0xFF3B82F6),
        chart2: Color(0xFF60A5FA),
        chart3: Color(0xFF93C5FD),
        chart4: Color(0xFFBFDBFE),
        chart5: Color(0xFFDBEAFE),
        destructive: Color(0xFFFF6467),
        foreground: Color(0xFFFAFAFA),
        input: Color(0x26FFFFFF),
        mapCardBg: Color(0xFFFFFFFF),
        mapCardFg: Color(0xFF0F172A),
        mapCardMuted: Color(0xFF64748B),
        mapCardWell: Color(0xFFF1F5F9),
        muted: Color(0xFF262626),
        mutedForeground: Color(0xFFA1A1A1),
        pinBg: Color(0xFFFFFFFF),
        pinFg: Color(0xFF1E293B),
        pinLine: Color(0x29FFFFFF),
        popover: Color(0xFF171717),
        popoverForeground: Color(0xFFFAFAFA),
        primary: Color(0xFF3B82F6),
        primaryForeground: Color(0xFF171717),
        ring: Color(0xFF3B82F6),
        secondary: Color(0xFF262626),
        secondaryForeground: Color(0xFFFAFAFA),
        sidebar: Color(0xFF171717),
        sidebarAccent: Color(0xFF262626),
        sidebarAccentForeground: Color(0xFF3B82F6),
        sidebarBorder: Color(0x1AFFFFFF),
        sidebarForeground: Color(0xFFFAFAFA),
        sidebarPrimary: Color(0xFF3B82F6),
        sidebarPrimaryForeground: Color(0xFFFAFAFA),
        sidebarRing: Color(0xFF3B82F6),
    );
}
