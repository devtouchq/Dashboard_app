import 'package:flutter/material.dart';

/// Each section dashboard has its own brand color and dark gradient background.
///
/// Color palette rationale — each section has a distinct HUE so tiles,
/// donut wedges, and headers are visually separable at a glance.
///
///   Home        — Purple
///   EMR         — Blue (medical/clinical)
///   Accounts    — Emerald green (money)
///   Store       — Violet (inventory)
///   Bar         — Deep orange
///   Lab         — Cyan (test tubes / clinical)
///   Banquet     — Pink/magenta
///   Restaurant  — Amber (warm dining)
///   HR          — Teal (people/organic)
///   Frontoffice — Lime green (welcoming)
class SectionTheme {
  final List<Color> backgroundGradient;
  final Color accent;
  final Color accentSoft;
  final String subtitle;

  const SectionTheme({
    required this.backgroundGradient,
    required this.accent,
    required this.accentSoft,
    required this.subtitle,
  });

  // ──────────────────────────────────────────────────────────
  //  Home — deep purple
  // ──────────────────────────────────────────────────────────
  static const home = SectionTheme(
    backgroundGradient: [
      Color(0xFF2E1454),
      Color(0xFF5B1B8F),
      Color(0xFF1A0938)
    ],
    accent: Color(0xFFB57BFF),
    accentSoft: Color(0xFFE0CFFF),
    subtitle: "Here's your combined revenue overview",
  );

  // ──────────────────────────────────────────────────────────
  //  EMR — navy blue
  // ──────────────────────────────────────────────────────────
  static const emr = SectionTheme(
    backgroundGradient: [
      Color(0xFF101E4A),
      Color(0xFF1B2E73),
      Color(0xFF0A1430)
    ],
    accent: Color(0xFF4A8DFF),
    accentSoft: Color(0xFF8FB6FF),
    subtitle: 'Electronic Medical Records',
  );

  // ──────────────────────────────────────────────────────────
  //  Accounts — emerald green
  // ──────────────────────────────────────────────────────────
  static const accounts = SectionTheme(
    backgroundGradient: [
      Color(0xFF0E2E22),
      Color(0xFF115C3F),
      Color(0xFF08201A)
    ],
    accent: Color(0xFF2DD4A0),
    accentSoft: Color(0xFF7EE3C3),
    subtitle: 'Financial Management',
  );

  // ──────────────────────────────────────────────────────────
  //  Store — indigo/violet (was purple, was clashing with Home)
  // ──────────────────────────────────────────────────────────
  static const store = SectionTheme(
    backgroundGradient: [
      Color(0xFF1E1A4E),
      Color(0xFF3F35A8),
      Color(0xFF120F30)
    ],
    accent: Color(0xFF6366F1), // indigo
    accentSoft: Color(0xFFA5B4FC),
    subtitle: 'Inventory & Supplies',
  );

  // ──────────────────────────────────────────────────────────
  //  Bar — deep orange
  // ──────────────────────────────────────────────────────────
  static const bar = SectionTheme(
    backgroundGradient: [
      Color(0xFF3A1810),
      Color(0xFF6B2E1A),
      Color(0xFF20100A)
    ],
    accent: Color(0xFFFF8A3D),
    accentSoft: Color(0xFFFFB680),
    subtitle: 'Beverage Management',
  );

  // ──────────────────────────────────────────────────────────
  //  Lab — cyan (was light purple, was clashing with Store)
  // ──────────────────────────────────────────────────────────
  static const lab = SectionTheme(
    backgroundGradient: [
      Color(0xFF0F2E3D),
      Color(0xFF196A82),
      Color(0xFF061B25)
    ],
    accent: Color(0xFF22D3EE), // cyan
    accentSoft: Color(0xFFA5F3FC),
    subtitle: 'Lab Tests & Results',
  );

  // ──────────────────────────────────────────────────────────
  //  Banquet — pink/magenta
  // ──────────────────────────────────────────────────────────
  static const banquet = SectionTheme(
    backgroundGradient: [
      Color(0xFF3A0D2A),
      Color(0xFF7A1953),
      Color(0xFF200818)
    ],
    accent: Color(0xFFEC4899),
    accentSoft: Color(0xFFF8A8CC),
    subtitle: 'Event & Banquet Management',
  );

  // ──────────────────────────────────────────────────────────
  //  Restaurant — amber
  // ──────────────────────────────────────────────────────────
  static const restaurant = SectionTheme(
    backgroundGradient: [
      Color(0xFF3A2010),
      Color(0xFF6B4020),
      Color(0xFF1F100A)
    ],
    accent: Color(0xFFE89F2C),
    accentSoft: Color(0xFFFCC97C),
    subtitle: 'Dining & Food Service',
  );

  // ──────────────────────────────────────────────────────────
  //  HR — teal (unchanged, but softened bg to differentiate from Frontoffice)
  // ──────────────────────────────────────────────────────────
  static const hr = SectionTheme(
    backgroundGradient: [
      Color(0xFF0A2A2E),
      Color(0xFF134652),
      Color(0xFF051A1F)
    ],
    accent: Color(0xFF14B8A6), // teal
    accentSoft: Color(0xFF5EEAD4),
    subtitle: 'Human Resources Management',
  );

  // ──────────────────────────────────────────────────────────
  //  Frontoffice — lime green (differentiated from Accounts + HR)
  // ──────────────────────────────────────────────────────────
  static const frontoffice = SectionTheme(
    backgroundGradient: [
      Color(0xFF1B3010),
      Color(0xFF3A6A20),
      Color(0xFF0E1A08)
    ],
    accent: Color(0xFF84CC16), // lime
    accentSoft: Color(0xFFBEF264),
    subtitle: 'Reception & Visitor Management',
  );
}

/// Shared colors used across all dashboards (text on dark, card glass effect).
class DashboardColors {
  // Text colors on dark backgrounds
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textOnDarkSecondary = Color(0xFFD4D4F0);
  static const Color textOnDarkMuted = Color(0xFF9CA3D4);

  // Stat card "glassy" overlay (used over the section gradient background)
  static Color statCardBg = Colors.white.withValues(alpha: 0.06);
  static Color statCardBorder = Colors.white.withValues(alpha: 0.08);

  // Chart grid line color on dark backgrounds
  static Color chartGrid = Colors.white.withValues(alpha: 0.07);
  static Color chartAxisLabel = const Color(0xFFA0A4D0);

  // Stat card icon backgrounds — one distinct color per section for
  // instant recognition on the home tile grid.
  static const Color iconBlue = Color(0xFF3B82F6); // EMR
  static const Color iconGreen = Color(0xFF10B981); // Accounts
  static const Color iconIndigo = Color(0xFF6366F1); // Store (was purple)
  static const Color iconCyan = Color(0xFF22D3EE); // Lab (was purple)
  static const Color iconPink = Color(0xFFEC4899); // Banquet
  static const Color iconOrange = Color(0xFFF97316); // Bar
  static const Color iconAmber = Color(0xFFF59E0B); // Restaurant
  static const Color iconTeal = Color(0xFF14B8A6); // HR
  static const Color iconLime = Color(0xFF84CC16); // Frontoffice
  static const Color iconRed = Color(0xFFEF4444); // negative / warning

  // Legacy alias kept so anything still importing `iconPurple` compiles.
  // Prefer iconIndigo (Store) or iconCyan (Lab) going forward.
  static const Color iconPurple = Color(0xFF8B5CF6);
}
