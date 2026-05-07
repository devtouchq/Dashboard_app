import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/text_styles.dart';

class LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final Color? textColor;

  const LegendDot({
    super.key,
    required this.color,
    required this.label,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const Gap(4),
        KStyles().med(
          text: label,
          size: 11,
          color: textColor ?? AppColors.textSecondary,
        ),
      ],
    );
  }
}
