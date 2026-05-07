import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/text_styles.dart';

/// Colored gradient metric card (used in EMR & Store grids)
class MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final List<Color> gradient;

  const MetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: AppColors.white),
          ),
          const Gap(6),
          KStyles().med(
            text: label,
            size: 15,
            color: AppColors.white.withOpacity(0.9),
          ),
          const Gap(2),
          KStyles().semiBold(text: value, size: 16, color: AppColors.white),
        ],
      ),
    );
  }
}

/// Light tinted metric tile (used for IP/OP/New/Repeater)
class LightMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color bgColor;
  final Color textColor;

  const LightMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              KStyles().med(text: label, color: textColor),
              const Gap(2),
              KStyles().semiBold(text: value, color: textColor),
            ],
          ),
          Positioned(
            right: -4,
            bottom: -4,
            child: Icon(
              icon,
              size: 36,
              color: textColor.withOpacity(0.15),
            ),
          ),
        ],
      ),
    );
  }
}
