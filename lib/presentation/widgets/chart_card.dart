import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../core/constants/section_theme.dart';
import '../../core/constants/text_styles.dart';

/// Glassy container holding a chart with a title at the top.
/// Every chart in every dashboard sits inside one of these.
class ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const ChartCard({
    super.key,
    required this.title,
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: DashboardColors.statCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DashboardColors.statCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KStyles().semiBold(
            text: title,
            size: 14,
            color: DashboardColors.textOnDark,
          ),
          const Gap(14),
          child,
        ],
      ),
    );
  }
}
