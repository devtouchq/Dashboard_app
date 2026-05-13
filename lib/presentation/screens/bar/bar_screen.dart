import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/section_theme.dart';
import '../../../core/constants/string_constants.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/app_logger.dart';
import '../../blocs/bar/bar_bloc.dart';
import '../../widgets/chart_card.dart';
import '../../widgets/charts/bar_chart_widget.dart';
import '../../widgets/charts/pie_chart_widget.dart';
import '../../widgets/dashboard_scaffold.dart';
import '../../widgets/stat_card.dart';

class BarScreen extends StatelessWidget {
  const BarScreen({super.key});

  static const _tag = 'BarScreen';

  static const _pieColors = [
    DashboardColors.iconAmber,
    DashboardColors.iconRed,
    DashboardColors.iconPurple,
    DashboardColors.iconPink,
    DashboardColors.iconTeal,
  ];

  @override
  Widget build(BuildContext context) {
    AppLogger.info(_tag, 'build()');
    return BlocConsumer<BarBloc, BarState>(
      listener: (context, state) {
        AppLogger.info(_tag, 'state changed: ${state.status}');
        if (state.status == BarStatus.failure) {
          AppLogger.error(_tag, 'Bar load failed: ${state.errorMessage}');
        }
      },
      builder: (context, state) {
        return DashboardScaffold(
          theme: SectionTheme.bar,
          title: StringConstants.barDashboard,
          children: [_body(state)],
        );
      },
    );
  }

  Widget _body(BarState state) {
    if (state.status == BarStatus.loading || state.data == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    if (state.status == BarStatus.failure) {
      return _errorView(state.errorMessage);
    }

    final data = state.data!;
    return Column(
      children: [
        StatCardRow(
          cards: [
            StatCard(
              icon: Icons.local_bar_outlined,
              iconColor: DashboardColors.iconOrange,
              value: '${data.totalProducts}',
              label: StringConstants.totalProducts,
            ),
            StatCard(
              icon: Icons.attach_money,
              iconColor: DashboardColors.iconTeal,
              value: '\$${data.dailySales.toStringAsFixed(0)}',
              label: StringConstants.dailySales,
            ),
            StatCard(
              icon: Icons.receipt_long_outlined,
              iconColor: DashboardColors.iconPink,
              value: '${data.orders}',
              label: StringConstants.orders,
            ),
          ],
        ),
        const Gap(16),
        ChartCard(
          title: StringConstants.weeklyRevenue,
          child: BarChartWidget(
            groups: data.weeklyRevenue
                .map((p) => BarGroup(label: p.day, values: [p.revenue]))
                .toList(),
            barColors: const [Color(0xFFFF8A3D)],
            barWidth: 16,
          ),
        ),
        const Gap(16),
        ChartCard(
          title: StringConstants.productMix,
          child: PieChartWidget(
            slices: List.generate(
              data.productMix.length,
              (i) => PieSlice(
                label: data.productMix[i].label,
                value: data.productMix[i].percent,
                color: _pieColors[i % _pieColors.length],
              ),
            ),
            size: 180,
            showLegendValues: false,
          ),
        ),
      ],
    );
  }

  Widget _errorView(String? msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 16),
      child: KStyles().reg(
        text: 'Failed to load Bar data\n${msg ?? ''}',
        size: 13,
        color: Colors.redAccent,
        textAlign: TextAlign.center,
      ),
    );
  }
}
