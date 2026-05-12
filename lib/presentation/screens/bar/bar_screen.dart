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
import '../../widgets/safe_chart_wrapper.dart';

class BarScreen extends StatelessWidget {
  const BarScreen({super.key});

  static const _tag = 'BarScreen';

  // Sample data — replace with bloc + repository when API is ready.
  static const double _totalCollection = 10.00;

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
              bgcolor: AppColors.barColor.withValues(alpha: 0.1),
              title: StringConstants.bar,
              titleColor: AppColors.barColor,
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
                  _totalCollectionCard(),
                  _categorySalesCard(),
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
            icon: Icons.account_balance_wallet_outlined,
            label: StringConstants.totalCollection,
            value: '0.00',
            gradient: AppColors.roseGradient,
          ),
          MetricCard(
            icon: Icons.receipt_long_outlined,
            label: StringConstants.totalRevenue,
            value: '0.00',
            gradient: [Color(0xFF4F8A4F), Color(0xFF2F5A2F)],
          ),
        ],
      ),
    );
  }

  Widget _totalCollectionCard() {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitleRow(
            title: StringConstants.totalCollection,
            pillText: StringConstants.today,
          ),
          Container(
            height: 140,
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
                  Icons.local_bar_outlined,
                  size: 28,
                  color: AppColors.textMuted,
                ),
                const Gap(6),
                KStyles().reg(
                  text: '₹${_totalCollection.toStringAsFixed(2)}',
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const Gap(2),
                KStyles().reg(
                  text: 'No collection yet today',
                  size: 11,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _categorySalesCard() {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          const CardTitleRow(
            title: StringConstants.categoryWiseSales,
            pillText: StringConstants.today,
          ),
          SafeChartWrapper(
            tag: 'category_wise_sales',
            height: 180,
            builder: () => const _CategorySalesChart(),
          ),
        ],
      ),
    );
  }
}

class _CategorySalesChart extends StatelessWidget {
  const _CategorySalesChart();

  @override
  Widget build(BuildContext context) {
    // Sample timeline. Replace with API data.
    // All zeros by default — same empty-shape as the screenshot.
    final points = <Map<String, dynamic>>[
      {'time': '00:00', 'value': 0.0},
      {'time': '11 AM', 'value': 0.0},
      {'time': '03 PM', 'value': 0.0},
      {'time': '07 PM', 'value': 0.0},
      {'time': '11 PM', 'value': 0.0},
    ];

    final hasData = points.any((p) => (p['value'] as double) > 0);
    if (!hasData) {
      AppLogger.info('CategorySalesChart', 'No sales data, showing empty axis');
      return _emptyAxis(points);
    }

    return Chart(
      data: points,
      variables: {
        'time': Variable(
          accessor: (Map row) => row['time'] as String,
        ),
        'value': Variable(
          accessor: (Map row) => row['value'] as num,
        ),
      },
      marks: [
        AreaMark(
          shape: ShapeEncode(value: BasicAreaShape(smooth: true)),
          color: ColorEncode(
            value: AppColors.lmBlueText.withOpacity(0.15),
          ),
        ),
        LineMark(
          shape: ShapeEncode(value: BasicLineShape(smooth: true)),
          color: ColorEncode(value: AppColors.lmBlueText),
          size: SizeEncode(value: 2),
        ),
      ],
      axes: [
        Defaults.horizontalAxis
          ..label = LabelStyle(
            textStyle: TextStyle(
              fontFamily: FontConst().fontFamily,
              fontWeight: FontConst().regularFont,
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
        Defaults.verticalAxis
          ..label = LabelStyle(
            textStyle: TextStyle(
              fontFamily: FontConst().fontFamily,
              fontWeight: FontConst().regularFont,
              fontSize: 9,
              color: AppColors.textMuted,
            ),
          )
          ..grid = PaintStyle(strokeColor: AppColors.dividerColor),
      ],
    );
  }

  /// Empty grid with x-axis labels — matches the screenshot's "no data" look.
  Widget _emptyAxis(List<Map<String, dynamic>> points) {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F6FB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Y-axis labels column
                SizedBox(
                  width: 22,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(11, (i) {
                      final v = (10 - i) / 10.0;
                      return KStyles().reg(
                        text: v.toStringAsFixed(1),
                        size: 9,
                        color: AppColors.textMuted,
                      );
                    }),
                  ),
                ),
                const Gap(4),
                // Plot area with horizontal grid lines
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(11, (i) {
                      return Container(
                        height: 1,
                        color: AppColors.dividerColor,
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          const Gap(6),
          // X-axis labels
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: points
                  .map((p) => KStyles().reg(
                        text: p['time'] as String,
                        size: 9,
                        color: AppColors.textMuted,
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
