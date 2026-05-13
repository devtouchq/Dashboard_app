import 'package:flutter/material.dart';
import 'package:graphic/graphic.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/font_styles.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/models/dashboard_data.dart';

/// Stacked area chart showing the daily revenue trend for all 9 sections.
class StackedAreaChart extends StatelessWidget {
  final List<TrendPoint> points;
  final double height;

  const StackedAreaChart({
    super.key,
    required this.points,
    this.height = 200,
  });

  // Bottom-to-top stack order. Smaller-value series first so they don't
  // get squeezed at the top.
  static const List<String> _seriesOrder = [
    'Banquet',
    'Bar',
    'HR',
    'Lab',
    'Frontoffice',
    'Restaurant',
    'Store',
    'EMR',
    'Accounts',
  ];

  // Colors aligned 1:1 with _seriesOrder above.
  static final List<Color> _seriesColors = [
    AppColors.seriesBanquet.withValues(alpha: 0.9),
    AppColors.seriesBar.withValues(alpha: 0.9),
    AppColors.seriesHr.withValues(alpha: 0.9),
    AppColors.seriesLab.withValues(alpha: 0.9),
    AppColors.seriesFrontoffice.withValues(alpha: 0.9),
    AppColors.seriesRestaurant.withValues(alpha: 0.9),
    AppColors.seriesStore.withValues(alpha: 0.9),
    AppColors.seriesEmr.withValues(alpha: 0.9),
    AppColors.seriesAccounts.withValues(alpha: 0.9),
  ];

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      AppLogger.info('StackedAreaChart', 'No points to plot');
      return _empty();
    }

    final hasData = points.any(
      (p) =>
          p.accounts > 0 ||
          p.emr > 0 ||
          p.store > 0 ||
          p.hr > 0 ||
          p.restaurant > 0 ||
          p.lab > 0 ||
          p.bar > 0 ||
          p.frontoffice > 0 ||
          p.banquet > 0,
    );
    if (!hasData) {
      AppLogger.info('StackedAreaChart', 'All zero values');
      return _empty();
    }

    final data = <Map<String, dynamic>>[];
    for (final p in points) {
      data.add({'day': p.day, 'value': p.banquet, 'series': 'Banquet'});
      data.add({'day': p.day, 'value': p.bar, 'series': 'Bar'});
      data.add({'day': p.day, 'value': p.hr, 'series': 'HR'});
      data.add({'day': p.day, 'value': p.lab, 'series': 'Lab'});
      data.add({'day': p.day, 'value': p.frontoffice, 'series': 'Frontoffice'});
      data.add({'day': p.day, 'value': p.restaurant, 'series': 'Restaurant'});
      data.add({'day': p.day, 'value': p.store, 'series': 'Store'});
      data.add({'day': p.day, 'value': p.emr, 'series': 'EMR'});
      data.add({'day': p.day, 'value': p.accounts, 'series': 'Accounts'});
    }

    AppLogger.info(
      'StackedAreaChart',
      'Plotting ${data.length} rows across ${points.length} days × 9 series',
    );

    return SizedBox(
      height: height,
      child: Chart(
        padding: (_) => const EdgeInsets.fromLTRB(0, 8, 0, 22),
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
            scale: OrdinalScale(values: _seriesOrder),
          ),
        },
        marks: [
          AreaMark(
            position: Varset('day') * Varset('value') / Varset('series'),
            shape: ShapeEncode(value: BasicAreaShape(smooth: true)),
            color: ColorEncode(
              variable: 'series',
              values: _seriesColors,
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
                fontSize: 10,
                color: const Color(0xFFCBD5E1),
              ),
            )
            ..line = null,
          Defaults.verticalAxis
            ..label = null
            ..line = null
            ..grid = PaintStyle(
              strokeColor: Colors.white.withValues(alpha: 0.06),
            ),
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
          fontSize: 11,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
