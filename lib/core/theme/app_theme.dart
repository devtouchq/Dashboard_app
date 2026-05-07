import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/font_styles.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    final fontFamily = FontConst().fontFamily;

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.scaffoldBg,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primaryColor,
        secondary: AppColors.secondaryColor,
        surface: AppColors.cardBg,
      ),
      // Apply Roboto everywhere by default. Individual screens that use
      // KStyles will get the same family explicitly.
      textTheme: base.textTheme
          .apply(
            fontFamily: fontFamily,
            bodyColor: AppColors.textPrimary,
            displayColor: AppColors.textPrimary,
          ),
      primaryTextTheme: base.primaryTextTheme.apply(fontFamily: fontFamily),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontConst().semiBoldFont,
          fontSize: 17,
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.borderColor),
        ),
      ),
    );
  }
}
