import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/string_constants.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/app_logger.dart';
import '../../widgets/app_card.dart';
import '../../widgets/charts/donut_chart.dart';
import '../../widgets/dashboard_app_bar.dart';
import '../../widgets/legend_dot.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/safe_chart_wrapper.dart';

class FrontofficeScreen extends StatelessWidget {
  const FrontofficeScreen({super.key});

  static const _tag = 'FrontofficeScreen';

  // Sample data — replace with bloc + repository when API is ready.
  static const int _totalCheckIn = 120;
  static const int _currentGuest = 0;
  static const int _expectedArrival = 0;
  static const int _probableCheckOut = 0;
  static const double _totalCollection = 55146.00;
  static const double _totalRevenue = 101974.00;
  static const double _cashPercent = 8;   // approx slice from screenshot
  static const double _creditPercent = 92;

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
              title: StringConstants.frontofficeFull,
              titleColor: AppColors.frontofficeColor,
              showBackButton: true,
              onBack: () => Navigator.pop(context),
              actions: [
                AppBarIconButton(
                  icon: Icons.notifications_outlined,
                  onTap: () {},
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
                children: [
                  _statTilesGrid(),
                  const Gap(4),
                  _metricsRow(),
                  _totalCollectionCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statTilesGrid() {
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
          _StatTile(
            value: '$_totalCheckIn',
            label: StringConstants.totalCheckIn,
            icon: Icons.family_restroom,
          ),
          _StatTile(
            value: '$_currentGuest',
            label: StringConstants.currentGuest,
            icon: Icons.meeting_room_outlined,
          ),
          _StatTile(
            value: '$_expectedArrival',
            label: StringConstants.expectedArrival,
            icon: Icons.groups_outlined,
          ),
          _StatTile(
            value: '$_probableCheckOut',
            label: StringConstants.probableCheckOut,
            icon: Icons.exit_to_app_outlined,
          ),
        ],
      ),
    );
  }

  Widget _metricsRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.6,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          MetricCard(
            icon: Icons.account_balance_wallet_outlined,
            label: StringConstants.totalCollection,
            value: '55146.00',
            gradient: AppColors.navyGradient,
          ),
          MetricCard(
            icon: Icons.trending_up,
            label: StringConstants.totalRevenue,
            value: '101974.00',
            gradient: AppColors.roseGradient,
          ),
        ],
      ),
    );
  }

  Widget _totalCollectionCard() {
    final donutSlices = <DonutSlice>[];
    if (_cashPercent > 0) {
      donutSlices.add(const DonutSlice(
        label: 'Cash',
        value: _cashPercent,
        color: AppColors.frontofficeCash,
      ));
    }
    if (_creditPercent > 0) {
      donutSlices.add(const DonutSlice(
        label: StringConstants.employeeCredit,
        value: _creditPercent,
        color: AppColors.frontofficeCredit,
      ));
    }

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          const CardTitleRow(
            title: StringConstants.totalCollection,
            pillText: StringConstants.today,
          ),
          Row(
            children: [
              SafeChartWrapper(
                tag: 'frontoffice_collection_donut',
                height: 110,
                width: 110,
                builder: () => DonutChart(
                  slices: donutSlices,
                  centerText: '₹${_totalCollection.toStringAsFixed(0)}',
                  centerSubText: StringConstants.collected,
                  size: 110,
                ),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _legendRow(
                      color: AppColors.frontofficeCash,
                      label: 'Cash',
                      percent: _cashPercent,
                    ),
                    const Gap(8),
                    _legendRow(
                      color: AppColors.frontofficeCredit,
                      label: StringConstants.employeeCredit,
                      percent: _creditPercent,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendRow({
    required Color color,
    required String label,
    required double percent,
  }) {
    return Row(
      children: [
        LegendDot(color: color, label: label),
        const Spacer(),
        KStyles().semiBold(
          text: '${percent.toStringAsFixed(0)}%',
          size: 13,
          color: AppColors.textPrimary,
        ),
      ],
    );
  }
}

/// Light blue gradient stat tile with a circular icon avatar on the left
/// and a big value + label on the right — matches the Frontoffice screenshot.
class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.frontofficeTileStart,
            AppColors.frontofficeTileEnd,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 22, color: AppColors.frontofficeColor),
          ),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                KStyles().bold(
                  text: value,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
                const Gap(2),
                KStyles().semiBold(
                  text: label,
                  size: 12,
                  color: AppColors.textPrimary,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
