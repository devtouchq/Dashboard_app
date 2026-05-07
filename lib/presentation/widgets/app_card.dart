import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/text_styles.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Gradient? gradient;
  final Color? color;
  final BorderRadius? borderRadius;
  final bool showBorder;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.gradient,
    this.color,
    this.borderRadius,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? (color ?? AppColors.cardBg) : null,
        borderRadius: borderRadius ?? BorderRadius.circular(14),
        border: (showBorder && gradient == null)
            ? Border.all(color: AppColors.borderColor)
            : null,
      ),
      child: child,
    );
  }
}

class CardTitleRow extends StatelessWidget {
  final String title;
  final String? pillText;
  final Color titleColor;
  final Color pillBgColor;
  final Color pillTextColor;

  const CardTitleRow({
    super.key,
    required this.title,
    this.pillText,
    this.titleColor = AppColors.textPrimary,
    this.pillBgColor = const Color(0xFFF3F4F6),
    this.pillTextColor = AppColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          KStyles().semiBold(text: title, size: 18, color: titleColor),
          const Spacer(),
          if (pillText != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: pillBgColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: KStyles().semiBold(
                text: pillText!,
                color: pillTextColor,
              ),
            ),
        ],
      ),
    );
  }
}
