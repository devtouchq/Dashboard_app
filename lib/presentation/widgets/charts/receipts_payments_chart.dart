import 'package:flutter/material.dart';
import 'package:graphic/graphic.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/font_styles.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/models/accounts_data.dart';

/// Two overlaid line/area charts: Receipts vs Payments.
class ReceiptsPaymentsChart extends StatelessWidget {
  final List<CashFlowPoint> points;
  final double height;

  const ReceiptsPaymentsChart({
    super.key,
    required this.points,
    this.height = 80,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      AppLogger.info('ReceiptsPaymentsChart', 'No points to plot');
      return _empty();
    }

    final hasData = points.any((p) => p.receipts > 0 || p.payments > 0);
    if (!hasData) {
      AppLogger.info('ReceiptsPaymentsChart', 'All zero values');
      return _empty();
    }

    final data = <Map<String, dynamic>>[];
    for (final p in points) {
      data.add({'label': p.label, 'value': p.receipts, 'series': 'Receipts'});
      data.add({'label': p.label, 'value': p.payments, 'series': 'Payments'});
    }

    return SizedBox(
      height: height,
      child: Chart(
        data: data,
        variables: {
          'label': Variable(
            accessor: (Map row) => row['label'] as String,
          ),
          'value': Variable(
            accessor: (Map row) => (row['value'] as num).toDouble(),
          ),
          'series': Variable(
            accessor: (Map row) => row['series'] as String,
          ),
        },
        marks: [
          AreaMark(
            position: Varset('label') * Varset('value') / Varset('series'),
            shape: ShapeEncode(value: BasicAreaShape(smooth: true)),
            color: ColorEncode(
              variable: 'series',
              values: [
                AppColors.accountsColor.withOpacity(0.3),
                AppColors.transparent,
              ],
            ),
          ),
          LineMark(
            position: Varset('label') * Varset('value') / Varset('series'),
            shape: ShapeEncode(value: BasicLineShape(smooth: true)),
            color: ColorEncode(
              variable: 'series',
              values: [AppColors.accountsColor, AppColors.emrColor],
            ),
            size: SizeEncode(value: 2),
          ),
        ],
        axes: [
          Defaults.horizontalAxis
            ..label = LabelStyle(
              textStyle: TextStyle(
                fontFamily: FontConst().fontFamily,
                fontWeight: FontConst().regularFont,
                fontSize: 8,
                color: AppColors.textMuted,
              ),
            ),
          Defaults.verticalAxis
            ..label = null
            ..grid = PaintStyle(strokeColor: AppColors.dividerColor),
        ],
      ),
    );
  }

  Widget _empty() {
    return Container(
      height: height,
      alignment: Alignment.center,
      child: KStyles().reg(
        text: 'No transactions yet today',
        size: 10,
        color: AppColors.textMuted,
      ),
    );
  }
}
