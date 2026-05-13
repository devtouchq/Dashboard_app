import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/section_theme.dart';
import '../../../core/constants/string_constants.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/app_logger.dart';
import '../../blocs/accounts/accounts_bloc.dart';
import '../../widgets/chart_card.dart';
import '../../widgets/charts/multi_line_chart.dart';
import '../../widgets/charts/pie_chart_widget.dart';
import '../../widgets/dashboard_scaffold.dart';
import '../../widgets/stat_card.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  static const _tag = 'AccountsScreen';

  static const _pieColors = [
    DashboardColors.iconBlue,
    DashboardColors.iconGreen,
    DashboardColors.iconAmber,
    DashboardColors.iconPurple,
    DashboardColors.iconPink,
  ];

  @override
  Widget build(BuildContext context) {
    AppLogger.info(_tag, 'build()');
    return BlocConsumer<AccountsBloc, AccountsState>(
      listener: (context, state) {
        AppLogger.info(_tag, 'state changed: ${state.status}');
        if (state.status == AccountsStatus.failure) {
          AppLogger.error(_tag, 'Accounts load failed: ${state.errorMessage}');
        }
      },
      builder: (context, state) {
        return DashboardScaffold(
          theme: SectionTheme.accounts,
          title: StringConstants.accountsDashboard,
          children: [_body(state)],
        );
      },
    );
  }

  Widget _body(AccountsState state) {
    if (state.status == AccountsStatus.loading || state.data == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    if (state.status == AccountsStatus.failure) {
      return _errorView(state.errorMessage);
    }

    final data = state.data!;
    return Column(
      children: [
        StatCardRow(
          cards: [
            StatCard(
              icon: Icons.attach_money,
              iconColor: DashboardColors.iconTeal,
              value: '\$${data.totalRevenue.toStringAsFixed(0)}',
              label: StringConstants.totalRevenue,
              trendText: '+${data.revenueTrendPercent.toStringAsFixed(0)}%',
              trendColor: DashboardColors.iconGreen,
            ),
            StatCard(
              icon: Icons.trending_down,
              iconColor: DashboardColors.iconOrange,
              value: '\$${data.expenses.toStringAsFixed(0)}',
              label: StringConstants.expenses,
              trendText: '+${data.expensesTrendPercent.toStringAsFixed(0)}%',
              trendColor: DashboardColors.iconOrange,
            ),
            StatCard(
              icon: Icons.show_chart,
              iconColor: DashboardColors.iconBlue,
              value: '\$${data.netProfit.toStringAsFixed(0)}',
              label: StringConstants.netProfit,
              trendText: '+${data.netProfitTrendPercent.toStringAsFixed(0)}%',
              trendColor: DashboardColors.iconGreen,
            ),
          ],
        ),
        const Gap(16),
        ChartCard(
          title: StringConstants.revenueVsExpenses,
          child: MultiLineChart(
            series: [
              LineSeries(
                name: StringConstants.revenueLabel,
                color: const Color(0xFF2DD4A0),
                values:
                    data.revenueVsExpenses.map((p) => p.revenue).toList(),
              ),
              LineSeries(
                name: StringConstants.expenses,
                color: const Color(0xFFE89F2C),
                values:
                    data.revenueVsExpenses.map((p) => p.expenses).toList(),
              ),
            ],
            xLabels: data.revenueVsExpenses.map((p) => p.month).toList(),
            height: 220,
          ),
        ),
        const Gap(16),
        ChartCard(
          title: StringConstants.expenseBreakdown,
          child: PieChartWidget(
            slices: List.generate(
              data.expenseBreakdown.length,
              (i) => PieSlice(
                label: data.expenseBreakdown[i].label,
                value: data.expenseBreakdown[i].amount,
                color: _pieColors[i % _pieColors.length],
              ),
            ),
            size: 180,
            donut: true,
            showPercentLabels: false,
          ),
        ),
      ],
    );
  }

  Widget _errorView(String? msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 16),
      child: KStyles().reg(
        text: 'Failed to load Accounts data\n${msg ?? ''}',
        size: 13,
        color: Colors.redAccent,
        textAlign: TextAlign.center,
      ),
    );
  }
}
