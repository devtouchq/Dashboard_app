import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/string_constants.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/app_logger.dart';
import '../../widgets/app_card.dart';
import '../../widgets/dashboard_app_bar.dart';
import '../../widgets/metric_card.dart';

class LabScreen extends StatelessWidget {
  const LabScreen({super.key});

  static const _tag = 'LabScreen';

  // Sample data — replace with bloc + repository when API is ready.
  static const int _totalTestCount = 10;
  static const double _totalCollection = 1000.00;

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
              bgcolor: AppColors.labColor.withValues(alpha: 0.1),
              title: StringConstants.lab,
              titleColor: AppColors.labColor,
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
                  _topMetrics(),
                  const Gap(10),
                  _bottomMetric(),
                  const Gap(12),
                  _totalCollectionCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topMetrics() {
    return const Row(
      children: [
        Expanded(
          child: AspectRatio(
            aspectRatio: 1.5,
            child: MetricCard(
              icon: Icons.science_outlined,
              label: StringConstants.totalTestCount,
              value: '$_totalTestCount',
              gradient: AppColors.roseGradient,
            ),
          ),
        ),
        Gap(10),
        Expanded(
          child: AspectRatio(
            aspectRatio: 1.5,
            child: MetricCard(
              icon: Icons.receipt_long_outlined,
              label: StringConstants.totalRevenue,
              value: '0.00',
              gradient: [Color(0xFF2DA9A6), Color(0xFF1B7572)],
            ),
          ),
        ),
      ],
    );
  }

  Widget _bottomMetric() {
    return SizedBox(
      width: double.infinity,
      child: AspectRatio(
        aspectRatio: 3.1, // wider since it's full width on its own row
        child: MetricCard(
          icon: Icons.account_balance_wallet_outlined,
          label: StringConstants.totalCollection,
          value: _totalCollection.toStringAsFixed(2),
          gradient: AppColors.amberGradient,
        ),
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
                  Icons.science_outlined,
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
                  text: 'No tests collected today',
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
