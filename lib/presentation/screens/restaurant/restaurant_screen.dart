import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/section_theme.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../data/models/dashboard_data.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../widgets/chart_card.dart';
import '../../widgets/charts/bar_chart_widget.dart';
import '../../widgets/dashboard_scaffold.dart';
import '../../widgets/stat_card.dart';

class RestaurantScreen extends StatelessWidget {
  const RestaurantScreen({super.key});

  static const _tag = 'RestaurantScreen';

  @override
  Widget build(BuildContext context) {
    AppLogger.info(_tag, 'build()');
    return BlocBuilder<DashboardBloc, DashboardState>(
      buildWhen: (a, b) =>
          a.data?.restaurant != b.data?.restaurant ||
          a.data?.currency != b.data?.currency,
      builder: (context, state) {
        final data = state.data?.restaurant;
        final currency = state.data?.currency.defaultCurrency ?? 'INR';
        return DashboardScaffold(
          theme: SectionTheme.restaurant,
          title: 'Restaurant Dashboard',
          children: data == null
              ? [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 80),
                    child: Center(
                        child: CircularProgressIndicator(color: Colors.white)),
                  )
                ]
              : [_content(data, currency)],
        );
      },
    );
  }

  Widget _content(RestaurantData data, String currency) {
    return Column(
      children: [
        StatCardRow(
          cards: [
            StatCard(
              icon: Icons.people_alt_outlined,
              iconColor: DashboardColors.iconOrange,
              value: '${data.totalPax.toInt()}',
              label: 'Total Pax',
            ),
            StatCard(
              icon: Icons.table_restaurant_outlined,
              iconColor: DashboardColors.iconBlue,
              value: '${data.runningTableCount.toInt()}',
              label: 'Running Tables',
            ),
            StatCard(
              icon: Icons.attach_money,
              iconColor: DashboardColors.iconGreen,
              value: CurrencyUtils.format(data.totalRevenue, currency),
              label: 'Revenue',
            ),
          ],
        ),
        const Gap(16),
        ChartCard(
          title: 'Revenue vs Collection',
          child: BarChartWidget(
            groups: [
              BarGroup(label: 'Revenue', values: [data.totalRevenue.abs()]),
              BarGroup(
                  label: 'Collection', values: [data.totalCollection.abs()]),
            ],
            barColors: const [Color(0xFFE89F2C)],
            barWidth: 40,
            height: 200,
          ),
        ),
      ],
    );
  }
}
