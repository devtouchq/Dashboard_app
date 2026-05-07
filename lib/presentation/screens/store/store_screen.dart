import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/string_constants.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/app_logger.dart';
import '../../blocs/store/store_bloc.dart';
import '../../widgets/app_card.dart';
import '../../widgets/charts/category_distribution_bar.dart';
import '../../widgets/dashboard_app_bar.dart';
import '../../widgets/legend_dot.dart';
import '../../widgets/metric_card.dart';

class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  static const _tag = 'StoreScreen';

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
              title: StringConstants.store,
              titleColor: AppColors.storeColor,
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
              child: BlocConsumer<StoreBloc, StoreState>(
                listener: (context, state) {
                  AppLogger.info(_tag, 'state changed: ${state.status}');
                  if (state.status == StoreStatus.failure) {
                    AppLogger.error(
                      _tag,
                      'Store load failed: ${state.errorMessage}',
                    );
                  }
                },
                builder: (context, state) {
                  if (state.status == StoreStatus.loading ||
                      state.data == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.status == StoreStatus.failure) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: KStyles().reg(
                          text:
                              'Failed to load store data.\n${state.errorMessage ?? ''}',
                          size: 14,
                          color: AppColors.emrColor,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final data = state.data!;
                  return RefreshIndicator(
                    onRefresh: () async {
                      AppLogger.info(_tag, 'pull-to-refresh');
                      context.read<StoreBloc>().add(const StoreRefreshed());
                    },
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
                      children: [
                        _heroCard(data),
                        _metricsGrid(data),
                        _categoryCard(data),
                        _quickActions(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroCard(data) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      gradient: const LinearGradient(
        colors: AppColors.storeGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      showBorder: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                KStyles().reg(
                  text: StringConstants.totalCollection,
                  size: 13,
                  color: AppColors.white.withOpacity(0.85),
                ),
                const Gap(4),
                KStyles().bold(
                  text: '₹${data.totalCollection.toStringAsFixed(2)}',
                  size: 26,
                  color: AppColors.white,
                ),
                const Gap(4),
                Row(
                  children: [
                    const Icon(
                      Icons.trending_up,
                      size: 14,
                      color: Color(0xFFA78BFA),
                    ),
                    const Gap(4),
                    KStyles().med(
                      text:
                          '+${data.trendChangePercent}% ${StringConstants.vsYesterday}',
                      size: 12,
                      color: const Color(0xFFA78BFA),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            height: 44,
            child: CustomPaint(painter: _SparklinePainter()),
          ),
        ],
      ),
    );
  }

  Widget _metricsGrid(data) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.5,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          MetricCard(
            icon: Icons.shopping_cart_outlined,
            label: StringConstants.purchase,
            value: data.purchase.toStringAsFixed(2),
            gradient: AppColors.navyGradient,
          ),
          MetricCard(
            icon: Icons.trending_up,
            label: StringConstants.revenue,
            value: data.revenue.toStringAsFixed(2),
            gradient: AppColors.roseGradient,
          ),
          MetricCard(
            icon: Icons.receipt_long_outlined,
            label: StringConstants.collection,
            value: data.collection.toStringAsFixed(0),
            gradient: AppColors.amberGradient,
          ),
          MetricCard(
            icon: Icons.credit_card_outlined,
            label: StringConstants.payments,
            value: data.payments.toStringAsFixed(2),
            gradient: AppColors.accountsGradient,
          ),
        ],
      ),
    );
  }

  Widget _categoryCard(data) {
    final colorMap = {
      'Medicines': AppColors.storeColor,
      'Surgical': AppColors.accountsColor,
      'Equipment': AppColors.chartAmber,
    };

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitleRow(
            title: StringConstants.categoryDistribution,
            pillText: StringConstants.last30Days,
          ),
          CategoryDistributionBar(categories: data.categories),
          const Gap(12),
          ...data.categories.map<Widget>((c) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  LegendDot(
                    color: colorMap[c.name] ?? AppColors.grey,
                    label: c.name,
                    textColor: AppColors.textSecondary,
                  ),
                  const Spacer(),
                  KStyles().semiBold(
                    text: '₹${c.amount.toStringAsFixed(0)}',
                    size: 13,
                    color: AppColors.textPrimary,
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _quickActions() {
    return Row(
      children: [
        Expanded(
          child: _quickActionTile(
            icon: Icons.add,
            label: StringConstants.newPurchase,
            iconBg: AppColors.accountsColor,
            cardBg: const Color(0xFFF0FDF4),
            borderColor: const Color(0xFFBBF7D0),
            labelColor: const Color(0xFF0F6E56),
          ),
        ),
        const Gap(10),
        Expanded(
          child: _quickActionTile(
            icon: Icons.file_upload_outlined,
            label: StringConstants.exportReport,
            iconBg: AppColors.chartAmber,
            cardBg: const Color(0xFFFEF3C7),
            borderColor: const Color(0xFFFCD34D),
            labelColor: const Color(0xFF854F0B),
          ),
        ),
      ],
    );
  }

  Widget _quickActionTile({
    required IconData icon,
    required String label,
    required Color iconBg,
    required Color cardBg,
    required Color borderColor,
    required Color labelColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: AppColors.white),
          ),
          const Gap(8),
          KStyles().semiBold(
            text: label,
            size: 13,
            color: labelColor,
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final points = [
      Offset(2, size.height * 0.75),
      Offset(size.width * 0.15, size.height * 0.7),
      Offset(size.width * 0.28, size.height * 0.55),
      Offset(size.width * 0.4, size.height * 0.62),
      Offset(size.width * 0.52, size.height * 0.45),
      Offset(size.width * 0.65, size.height * 0.38),
      Offset(size.width * 0.78, size.height * 0.25),
      Offset(size.width * 0.97, size.height * 0.2),
    ];

    final fillPath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    final fillPaint = Paint()
      ..color = AppColors.white.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      linePath.lineTo(p.dx, p.dy);
    }
    final linePaint = Paint()
      ..color = AppColors.white
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
