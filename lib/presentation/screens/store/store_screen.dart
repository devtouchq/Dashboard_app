import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/section_theme.dart';
import '../../../core/constants/string_constants.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/app_logger.dart';
import '../../blocs/store/store_bloc.dart';
import '../../widgets/chart_card.dart';
import '../../widgets/charts/bar_chart_widget.dart';
import '../../widgets/charts/single_line_chart.dart';
import '../../widgets/dashboard_scaffold.dart';
import '../../widgets/stat_card.dart';

class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  static const _tag = 'StoreScreen';

  @override
  Widget build(BuildContext context) {
    AppLogger.info(_tag, 'build()');
    return BlocConsumer<StoreBloc, StoreState>(
      listener: (context, state) {
        AppLogger.info(_tag, 'state changed: ${state.status}');
        if (state.status == StoreStatus.failure) {
          AppLogger.error(_tag, 'Store load failed: ${state.errorMessage}');
        }
      },
      builder: (context, state) {
        return DashboardScaffold(
          theme: SectionTheme.store,
          title: StringConstants.storeDashboard,
          children: [_body(state)],
        );
      },
    );
  }

  Widget _body(StoreState state) {
    if (state.status == StoreStatus.loading || state.data == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    if (state.status == StoreStatus.failure) {
      return _errorView(state.errorMessage);
    }

    final data = state.data!;
    return Column(
      children: [
        StatCardRow(
          cards: [
            StatCard(
              icon: Icons.inventory_2_outlined,
              iconColor: DashboardColors.iconPurple,
              value: '${data.totalItems}',
              label: StringConstants.totalItems,
            ),
            StatCard(
              icon: Icons.warning_amber,
              iconColor: DashboardColors.iconOrange,
              value: '${data.lowStock}',
              label: StringConstants.lowStock,
            ),
            StatCard(
              icon: Icons.shopping_cart_outlined,
              iconColor: DashboardColors.iconBlue,
              value: '${data.orders}',
              label: StringConstants.orders,
            ),
          ],
        ),
        const Gap(16),
        ChartCard(
          title: StringConstants.inventoryLevelsByCategory,
          child: BarChartWidget(
            groups: data.inventoryByCategory
                .map((c) => BarGroup(
                      label: c.category,
                      values: [c.inStock, c.sold],
                    ))
                .toList(),
            barColors: const [
              Color(0xFFB57BFF),
              Color(0xFFEC4899),
            ],
            barWidth: 10,
            rotateLabels: -0.35,
            height: 240,
          ),
        ),
        const Gap(16),
        ChartCard(
          title: StringConstants.monthlySalesTrend,
          child: SingleLineChart(
            values: data.monthlySales.map((p) => p.sales).toList(),
            xLabels: data.monthlySales.map((p) => p.month).toList(),
            lineColor: const Color(0xFFB57BFF),
            height: 200,
          ),
        ),
      ],
    );
  }

  Widget _errorView(String? msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 16),
      child: KStyles().reg(
        text: 'Failed to load Store data\n${msg ?? ''}',
        size: 13,
        color: Colors.redAccent,
        textAlign: TextAlign.center,
      ),
    );
  }
}
