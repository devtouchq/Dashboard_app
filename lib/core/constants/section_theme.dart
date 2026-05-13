import 'package:flutter/material.dart';

/// Each section dashboard has its own brand color and dark gradient background.
/// Defines the visual identity for: Home, EMR, Accounts, Store, Bar, Lab,
/// Banquet, Restaurant, HR, Frontoffice.
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
  //  Home (deep purple)
  // ──────────────────────────────────────────────────────────
  static const home = SectionTheme(
    backgroundGradient: [Color(0xFF2E1454), Color(0xFF5B1B8F), Color(0xFF1A0938)],
    accent: Color(0xFFB57BFF),
    accentSoft: Color(0xFFE0CFFF),
    subtitle: "Here's your combined revenue overview",
  );

  // ──────────────────────────────────────────────────────────
  //  EMR (navy blue)
  // ──────────────────────────────────────────────────────────
  static const emr = SectionTheme(
    backgroundGradient: [Color(0xFF101E4A), Color(0xFF1B2E73), Color(0xFF0A1430)],
    accent: Color(0xFF4A8DFF),
    accentSoft: Color(0xFF8FB6FF),
    subtitle: 'Electronic Medical Records',
  );

  // ──────────────────────────────────────────────────────────
  //  Accounts (forest green)
  // ──────────────────────────────────────────────────────────
  static const accounts = SectionTheme(
    backgroundGradient: [Color(0xFF0E2E22), Color(0xFF115C3F), Color(0xFF08201A)],
    accent: Color(0xFF2DD4A0),
    accentSoft: Color(0xFF7EE3C3),
    subtitle: 'Financial Management',
  );

  // ──────────────────────────────────────────────────────────
  //  Store (purple)
  // ──────────────────────────────────────────────────────────
  static const store = SectionTheme(
    backgroundGradient: [Color(0xFF2A1245), Color(0xFF572A8E), Color(0xFF180929)],
    accent: Color(0xFFB57BFF),
    accentSoft: Color(0xFFD6B3FF),
    subtitle: 'Inventory & Supplies',
  );

  // ──────────────────────────────────────────────────────────
  //  Bar (warm brown/orange)
  // ──────────────────────────────────────────────────────────
  static const bar = SectionTheme(
    backgroundGradient: [Color(0xFF3A1810), Color(0xFF6B2E1A), Color(0xFF20100A)],
    accent: Color(0xFFFF8A3D),
    accentSoft: Color(0xFFFFB680),
    subtitle: 'Beverage Management',
  );

  // ──────────────────────────────────────────────────────────
  //  Lab (deep purple-blue)
  // ──────────────────────────────────────────────────────────
  static const lab = SectionTheme(
    backgroundGradient: [Color(0xFF1F1A4B), Color(0xFF3A2F7A), Color(0xFF120E2F)],
    accent: Color(0xFFA78BFA),
    accentSoft: Color(0xFFC9B7FF),
    subtitle: 'Lab Tests & Results',
  );

  // ──────────────────────────────────────────────────────────
  //  Banquet (deep maroon/pink)
  // ──────────────────────────────────────────────────────────
  static const banquet = SectionTheme(
    backgroundGradient: [Color(0xFF3A0D2A), Color(0xFF7A1953), Color(0xFF200818)],
    accent: Color(0xFFEC4899),
    accentSoft: Color(0xFFF8A8CC),
    subtitle: 'Event & Banquet Management',
  );

  // ──────────────────────────────────────────────────────────
  //  Restaurant (dark amber/brown)
  // ──────────────────────────────────────────────────────────
  static const restaurant = SectionTheme(
    backgroundGradient: [Color(0xFF3A2010), Color(0xFF6B4020), Color(0xFF1F100A)],
    accent: Color(0xFFE89F2C),
    accentSoft: Color(0xFFFCC97C),
    subtitle: 'Dining & Food Service',
  );

  // ──────────────────────────────────────────────────────────
  //  HR (dark teal)
  // ──────────────────────────────────────────────────────────
  static const hr = SectionTheme(
    backgroundGradient: [Color(0xFF0A2A2E), Color(0xFF134652), Color(0xFF051A1F)],
    accent: Color(0xFF2DD4A0),
    accentSoft: Color(0xFF7EE3C3),
    subtitle: 'Human Resources Management',
  );

  // ──────────────────────────────────────────────────────────
  //  Frontoffice (dark green-teal)
  // ──────────────────────────────────────────────────────────
  static const frontoffice = SectionTheme(
    backgroundGradient: [Color(0xFF0D2E26), Color(0xFF155A48), Color(0xFF051A14)],
    accent: Color(0xFF2DD4A0),
    accentSoft: Color(0xFF7EE3C3),
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

  // Stat card icon backgrounds (small colored square)
  static const Color iconBlue   = Color(0xFF3B82F6);
  static const Color iconGreen  = Color(0xFF10B981);
  static const Color iconPurple = Color(0xFF8B5CF6);
  static const Color iconPink   = Color(0xFFEC4899);
  static const Color iconOrange = Color(0xFFF97316);
  static const Color iconAmber  = Color(0xFFF59E0B);
  static const Color iconRed    = Color(0xFFEF4444);
  static const Color iconTeal   = Color(0xFF2DD4A0);
}
