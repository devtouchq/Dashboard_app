import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:graphic/graphic.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/font_styles.dart';
import '../../../core/constants/string_constants.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/app_logger.dart';
import '../../widgets/app_card.dart';
import '../../widgets/dashboard_app_bar.dart';
import '../../widgets/metric_card.dart';

class HrScreen extends StatelessWidget {
  const HrScreen({super.key});

  static const _tag = 'HrScreen';

  // Sample data — replace with bloc + repository when API is ready.
  static const int _totalPresent = 10;
  static const int _totalAbsent = 45;

  @override
  Widget build(BuildContext context) {
    AppLogger.info(_tag, 'build()');
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            DashboardAppBar(
              bgcolor: AppColors.hrColor.withValues(alpha: 0.1),
              title: StringConstants.hr,
              titleColor: AppColors.hrColor,
              showBackButton: true,
              onBack: () => Navigator.pop(context),
              actions: [
                AppBarIconButton(
                  icon: Icons.notifications_outlined,
                  onTap: () {},
                ),
              ],
            ),
            const Gap(50),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
                children: [
                  _metricsGrid(),
                  _employeeInfoCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricsGrid() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.5,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          MetricCard(
            icon: Icons.person,
            label: StringConstants.totalPresent,
            value: '$_totalPresent',
            gradient: AppColors.roseGradient,
          ),
          MetricCard(
            icon: Icons.person_off_outlined,
            label: StringConstants.totalAbsent,
            value: '$_totalAbsent',
            gradient: AppColors.navyGradient,
          ),
        ],
      ),
    );
  }

  Widget _employeeInfoCard() {
    return AppCard(
      color: AppColors.hrColor.withValues(alpha: 0.3),
      padding: const EdgeInsets.all(14),
      showBorder: true,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CardTitleRow(
            title: StringConstants.employeeInformation,
            pillText: StringConstants.today,
          ),
          _EmployeeBarChart(
            present: _totalPresent,
            absent: _totalAbsent,
          ),
        ],
      ),
    );
  }
}

class _EmployeeBarChart extends StatelessWidget {
  final int present;
  final int absent;

  const _EmployeeBarChart({
    required this.present,
    required this.absent,
  });

  @override
  Widget build(BuildContext context) {
    // Shorter chart + fewer Y ticks = tighter, less wasted space.
    const double chartHeight = 240;

    final total = present + absent;
    if (total <= 0) {
      AppLogger.info('HrChart', 'No employee data');
      return SizedBox(
        height: chartHeight,
        child: Center(
          child: KStyles().reg(
            text: 'No employee data',
            size: 12,
            color: AppColors.black.withValues(alpha: 0.7),
          ),
        ),
      );
    }

    final data = [
      {'label': StringConstants.present, 'value': present},
      {'label': StringConstants.absent, 'value': absent},
    ];

    // Round the max up to a clean number so the top tick isn't cluttered.
    // e.g. max=45 → top=50, max=120 → top=150, max=8 → top=10
    final maxVal = (present > absent ? present : absent).toDouble();
    final niceMax = _niceCeiling(maxVal);

    return SizedBox(
      height: chartHeight,
      child: Chart(
        data: data,
        variables: {
          'label': Variable(
            accessor: (Map row) => row['label'] as String,
          ),
          'value': Variable(
              accessor: (Map row) => (row['value'] as int).toDouble(),
              // Force the scale to 0..niceMax with only 3 tick marks
              // (start, middle, end) — far less visual noise.
              scale: LinearScale(
                min: 0,
                max: niceMax,
                tickCount: 5,
              )),
        },
        marks: [
          IntervalMark(
            color: ColorEncode(
              variable: 'label',
              values: const [AppColors.green, AppColors.chartNavy],
            ),
            shape: ShapeEncode(
              value: RectShape(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            label: LabelEncode(
              encoder: (tuple) => Label(
                tuple['value'].toString(),
                LabelStyle(
                  textStyle: TextStyle(
                    fontFamily: FontConst().fontFamily,
                    fontSize: 12,
                    fontWeight: FontConst().semiBoldFont,
                    color: AppColors.textPrimary,
                  ),
                  align: Alignment.topCenter,
                  offset: const Offset(0, -8),
                ),
              ),
            ),
          ),
        ],
        axes: [
          Defaults.horizontalAxis
            ..label = LabelStyle(
              textStyle: TextStyle(
                fontFamily: FontConst().fontFamily,
                fontWeight: FontConst().regularFont,
                fontSize: 11,
                color: AppColors.black.withValues(alpha: 0.7),
              ),
            ),
          Defaults.verticalAxis
            ..label = LabelStyle(
              textStyle: TextStyle(
                fontFamily: FontConst().fontFamily,
                fontWeight: FontConst().regularFont,
                fontSize: 9,
                color: AppColors.black.withValues(alpha: 0.7),
              ),
            )
            ..grid = PaintStyle(strokeColor: AppColors.dividerColor),
        ],
      ),
    );
  }

  /// Round max up to a "nice" number for the Y-axis top:
  /// 8 → 10, 45 → 50, 120 → 150, 850 → 1000.
  double _niceCeiling(double v) {
    if (v <= 0) return 10;
    if (v <= 10) return 10;
    if (v <= 50) return 50;
    if (v <= 100) return 100;
    // For larger values, round up to nearest 100.
    return ((v / 100).ceil() * 100).toDouble();
  }
}
