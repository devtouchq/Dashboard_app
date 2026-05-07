import 'package:flutter/material.dart';
import 'package:graphic/graphic.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/font_styles.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/models/dashboard_data.dart';

/// Stacked area chart showing Accounts/EMR/Store trend over the week.
/// Built with the `graphic` package (Variant B).
class StackedAreaChart extends StatelessWidget {
  final List<TrendPoint> points;
  final double height;

  const StackedAreaChart({
    super.key,
    required this.points,
    this.height = 100,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      AppLogger.info('StackedAreaChart', 'No points to plot');
      return _empty();
    }

    final hasData = points.any(
      (p) => p.accounts > 0 || p.emr > 0 || p.store > 0,
    );
    if (!hasData) {
      AppLogger.info('StackedAreaChart', 'All zero values');
      return _empty();
    }

    // Reshape data into a long format expected by graphic stacking.
    final data = <Map<String, dynamic>>[];
    for (final p in points) {
      data.add({'day': p.day, 'value': p.accounts, 'series': 'Accounts'});
      data.add({'day': p.day, 'value': p.emr, 'series': 'EMR'});
      data.add({'day': p.day, 'value': p.store, 'series': 'Store'});
    }

    return SizedBox(
      height: height,
      child: Chart(
        data: data,
        variables: {
          'day': Variable(
            accessor: (Map row) => row['day'] as String,
          ),
          'value': Variable(
            accessor: (Map row) => row['value'] as num,
          ),
          'series': Variable(
            accessor: (Map row) => row['series'] as String,
          ),
        },
        marks: [
          AreaMark(
            position: Varset('day') * Varset('value') / Varset('series'),
            shape: ShapeEncode(value: BasicAreaShape(smooth: true)),
            color: ColorEncode(
              variable: 'series',
              values: [
                AppColors.chartGreen.withOpacity(0.5),
                AppColors.chartRed.withOpacity(0.5),
                AppColors.chartPurple.withOpacity(0.5),
              ],
            ),
            modifiers: [StackModifier()],
          ),
        ],
        coord: RectCoord(color: const Color(0x00000000)),
        axes: [
          Defaults.horizontalAxis
            ..label = LabelStyle(
              textStyle: TextStyle(
                fontFamily: FontConst().fontFamily,
                fontWeight: FontConst().regularFont,
                fontSize: 9,
                color: AppColors.textMuted,
              ),
            )
            ..line = null,
          Defaults.verticalAxis
            ..label = null
            ..line = null
            ..grid = PaintStyle(strokeColor: Colors.white.withOpacity(0.05)),
        ],
      ),
    );
  }

  Widget _empty() {
    return Container(
      height: height,
      alignment: Alignment.center,
      child: Text(
        'No trend data yet',
        style: TextStyle(
          fontFamily: FontConst().fontFamily,
          fontSize: 10,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
