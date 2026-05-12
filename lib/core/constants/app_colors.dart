import 'package:flutter/material.dart';

class AppColors {
  // Brand colors (from the dashboard design)
  static const Color primaryColor = Color(0xFF1D9E75); // Teal/Green
  static const Color secondaryColor = Color(0xFF0F6E56); // Dark teal
  //sectionHeaderBg
  static const Color sectionHeaderBg =
      Color.fromARGB(255, 203, 208, 207); // Light teal

  // Section colors
  static const Color emrColor = Color(0xFFE2585A); // Coral - EMR
  static const Color accountsColor = Color(0xFF1D9E75); // Teal - Accounts
  static const Color storeColor = Color(0xFF534AB7); // Purple - Store

  static const Color hrColor = Color(0xFF2DA9A6); // teal
  static const Color restaurantColor = Color(0xFF4F8A4F); // forest green
  static const Color labColor = Color(0xFF1F1A4D); // coral
  static const Color barColor = Color.fromARGB(255, 33, 85, 134);

  // Base colors
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color red = Colors.red;
  static const Color grey = Colors.grey;
  static const Color yellow = Colors.yellow;
  static const Color green = Colors.green;
  static const Color transparent = Colors.transparent;

  // Background colors
  static const Color scaffoldBg = Color(0xFFF6F7FB);
  static const Color cardBg = Colors.white;

  // Text colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textLabel = Color(0xFF6B7280);

  // Border / divider
  static const Color borderColor = Color(0xFFEEF2F7);
  static const Color dividerColor = Color(0xFFF1F5F9);

  // Light tints
  static const Color lightGrey = Color.fromARGB(253, 220, 218, 218);
  static const Color clearRed = Color.fromARGB(255, 196, 34, 34);
  static const Color cancelRed = Color.fromARGB(255, 159, 76, 70);

  // Light metric backgrounds (used in EMR IP/OP/New/Repeat tiles)
  static const Color lmCoralBg = Color(0xFFFAECE7);
  static const Color lmCoralText = Color(0xFF712B13);
  static const Color lmAmberBg = Color(0xFFFAEEDA);
  static const Color lmAmberText = Color(0xFF633806);
  static const Color lmBlueBg = Color(0xFFE6F1FB);
  static const Color lmBlueText = Color(0xFF0C447C);
  static const Color lmGreenBg = Color(0xFFEAF3DE);
  static const Color lmGreenText = Color(0xFF27500A);

  // Hero card gradient stops (dark navy)
  static const Color heroDarkStart = Color(0xFF0F172A);
  static const Color heroDarkEnd = Color(0xFF1E293B);

  // Chart palette
  static const Color chartGreen = Color(0xFF10B981);
  static const Color chartRed = Color(0xFFF87171);
  static const Color chartPurple = Color(0xFFA78BFA);
  static const Color chartTeal = Color(0xFF37BFB8);
  static const Color chartNavy = Color(0xFF1F1A4D);
  static const Color chartAmber = Color(0xFFEF9F27);
  // Chart series colors — one per series in the home stacked area chart
  static const Color seriesAccounts = Color(0xFF10B981); // green
  static const Color seriesEmr = Color(0xFFF87171); // red
  static const Color seriesStore = Color(0xFFA78BFA); // purple
  static const Color seriesHr = Color(0xFF2DA9A6); // teal
  static const Color seriesRestaurant = Color(0xFF4F8A4F); // forest
  static const Color seriesLab = Color(0xFFEF9F27); // amber
  static const Color seriesBar = Color(0xFF3BA0FF); // sky blue

  // ──────────────────────────────────────────────────────────
  //  GRADIENT LISTS — these are what the metric cards consume
  // ──────────────────────────────────────────────────────────

  static const List<Color> gradientColors = [
    Color.fromARGB(202, 255, 255, 255),
    AppColors.primaryColor,
    AppColors.primaryColor,
  ];

  static const List<Color> heroGradient = [heroDarkStart, heroDarkEnd];

  static const List<Color> emrGradient = [
    Color(0xFFE2585A),
    Color(0xFF993C1D),
  ];

  static const List<Color> accountsGradient = [
    Color(0xFF0F6E56),
    Color(0xFF1D9E75),
  ];

  static const List<Color> storeGradient = [
    Color(0xFF3C3489),
    Color(0xFF534AB7),
  ];

  static const List<Color> amberGradient = [
    Color(0xFFEF9F27),
    Color(0xFF854F0B),
  ];

  static const List<Color> purpleGradient = [
    Color(0xFF534AB7),
    Color(0xFF3C3489),
  ];

  static const List<Color> navyGradient = [
    Color(0xFF1F1A4D),
    Color(0xFF26215C),
  ];

  static const List<Color> roseGradient = [
    Color(0xFFB85B6C),
    Color(0xFF993556),
  ];
}
