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

class LabScreen extends StatelessWidget {
  const LabScreen({super.key});

  static const _tag = 'LabScreen';

  @override
  Widget build(BuildContext context) {
    AppLogger.info(_tag, 'build()');
    return BlocBuilder<DashboardBloc, DashboardState>(
      buildWhen: (a, b) =>
          a.data?.lab != b.data?.lab || a.data?.currency != b.data?.currency,
      builder: (context, state) {
        final data = state.data?.lab;
        final currency = state.data?.currency.defaultCurrency ?? 'INR';
        return DashboardScaffold(
          theme: SectionTheme.lab,
          title: 'Laboratory Dashboard',
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

  Widget _content(LabData data, String currency) {
    return Column(
      children: [
        StatCardRow(
          cards: [
            StatCard(
              icon: Icons.science_outlined,
              iconColor: DashboardColors.iconPurple,
              value: '${data.testCount.toInt()}',
              label: 'Total Tests',
            ),
            StatCard(
              icon: Icons.attach_money,
              iconColor: DashboardColors.iconGreen,
              value: CurrencyUtils.format(data.totalRevenue, currency),
              label: 'Revenue',
            ),
            StatCard(
              icon: Icons.payments_outlined,
              iconColor: DashboardColors.iconTeal,
              value: CurrencyUtils.format(data.totalCollection, currency),
              label: 'Collection',
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
            barColors: const [Color(0xFFA78BFA)],
            barWidth: 40,
            height: 200,
          ),
        ),
      ],
    );
  }
}
