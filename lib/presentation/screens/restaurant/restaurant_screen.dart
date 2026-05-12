import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/string_constants.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/app_logger.dart';
import '../../widgets/app_card.dart';
import '../../widgets/dashboard_app_bar.dart';
import '../../widgets/metric_card.dart';

class RestaurantScreen extends StatelessWidget {
  const RestaurantScreen({super.key});

  static const _tag = 'RestaurantScreen';

  // Sample data — replace with bloc + repository when API is ready.
  static const int _totalPax = 0;
  static const double _totalCollection = 0.00;
  static const int _runningTable = 0;

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
              bgcolor: AppColors.restaurantColor.withValues(alpha: 0.1),
              title: StringConstants.restaurant,
              titleColor: AppColors.restaurantColor,
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
            icon: Icons.people_alt_outlined,
            label: StringConstants.totalPax,
            value: '$_totalPax',
            gradient: AppColors.roseGradient,
          ),
          MetricCard(
            icon: Icons.receipt_long_outlined,
            label: StringConstants.totalRevenue,
            value: '0.00',
            gradient: AppColors.navyGradient,
          ),
          MetricCard(
            icon: Icons.account_balance_wallet_outlined,
            label: StringConstants.totalCollection,
            value: '0.00',
            gradient: AppColors.amberGradient,
          ),
          MetricCard(
            icon: Icons.table_restaurant_outlined,
            label: StringConstants.runningTable,
            value: '$_runningTable',
            gradient: AppColors.accountsGradient,
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
          // Empty-state placeholder — wire chart in once you have data.
          Container(
            height: 160,
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
}
