import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/utils/app_logger.dart';

/// Wraps a chart so a build-time exception in graphic doesn't take down
/// the whole screen. Shows a placeholder and logs the error with stack.
class SafeChartWrapper extends StatelessWidget {
  final Widget Function() builder;
  final String tag;
  final double height;
  final String fallbackMessage;

  const SafeChartWrapper({
    super.key,
    required this.builder,
    required this.tag,
    this.height = 100,
    this.fallbackMessage = 'No data to display',
  });

  @override
  Widget build(BuildContext context) {
    try {
      return builder();
    } catch (e, st) {
      AppLogger.error(
        'Chart/$tag',
        'Failed to build chart',
        error: e,
        stackTrace: st,
      );
      return _fallback();
    }
  }

  Widget _fallback() {
    return Container(
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.scaffoldBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.bar_chart_outlined,
            size: 24,
            color: AppColors.textMuted,
          ),
          const Gap(4),
          KStyles().reg(
            text: fallbackMessage,
            size: 10,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}
