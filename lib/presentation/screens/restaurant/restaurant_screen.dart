import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/section_theme.dart';
import '../../../core/constants/string_constants.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/app_logger.dart';
import '../../blocs/restaurant/restaurant_bloc.dart';
import '../../widgets/chart_card.dart';
import '../../widgets/charts/pie_chart_widget.dart';
import '../../widgets/charts/single_line_chart.dart';
import '../../widgets/dashboard_scaffold.dart';
import '../../widgets/stat_card.dart';

class RestaurantScreen extends StatelessWidget {
  const RestaurantScreen({super.key});

  static const _tag = 'RestaurantScreen';

  static const _pieColors = [
    DashboardColors.iconAmber,
    DashboardColors.iconTeal,
    DashboardColors.iconPink,
    DashboardColors.iconBlue,
    DashboardColors.iconPurple,
  ];

  @override
  Widget build(BuildContext context) {
    AppLogger.info(_tag, 'build()');
    return BlocConsumer<RestaurantBloc, RestaurantState>(
      listener: (context, state) {
        AppLogger.info(_tag, 'state changed: ${state.status}');
        if (state.status == RestaurantStatus.failure) {
          AppLogger.error(
              _tag, 'Restaurant load failed: ${state.errorMessage}');
        }
      },
      builder: (context, state) {
        return DashboardScaffold(
          theme: SectionTheme.restaurant,
          title: StringConstants.restaurantDashboard,
          children: [_body(state)],
        );
      },
    );
  }

  Widget _body(RestaurantState state) {
    if (state.status == RestaurantStatus.loading || state.data == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    if (state.status == RestaurantStatus.failure) {
      return _errorView(state.errorMessage);
    }

    final data = state.data!;
    return Column(
      children: [
        StatCardRow(
          cards: [
            StatCard(
              icon: Icons.restaurant_outlined,
              iconColor: DashboardColors.iconOrange,
              value: '${data.dailyOrders}',
              label: StringConstants.dailyOrders,
            ),
            StatCard(
              icon: Icons.people_alt_outlined,
              iconColor: DashboardColors.iconBlue,
              value: '${data.customers}',
              label: StringConstants.customers,
            ),
            StatCard(
              icon: Icons.attach_money,
              iconColor: DashboardColors.iconGreen,
              value: '\$${(data.revenue / 1000).toStringAsFixed(1)}k',
              label: StringConstants.revenueLabel,
            ),
          ],
        ),
        const Gap(16),
        ChartCard(
          title: StringConstants.weeklySales,
          child: SingleLineChart(
            values: data.weeklySales.map((p) => p.sales).toList(),
            xLabels: data.weeklySales.map((p) => p.day).toList(),
            lineColor: const Color(0xFFE89F2C),
            fillBelow: true,
            height: 220,
          ),
        ),
        const Gap(16),
        ChartCard(
          title: StringConstants.salesByCategory,
          child: PieChartWidget(
            slices: List.generate(
              data.salesByCategory.length,
              (i) => PieSlice(
                label: data.salesByCategory[i].label,
                value: data.salesByCategory[i].percent,
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
        text: 'Failed to load Restaurant data\n${msg ?? ''}',
        size: 13,
        color: Colors.redAccent,
        textAlign: TextAlign.center,
      ),
    );
  }
}
