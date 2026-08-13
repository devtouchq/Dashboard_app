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

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  static const _tag = 'AccountsScreen';

  @override
  Widget build(BuildContext context) {
    AppLogger.info(_tag, 'build()');
    return BlocBuilder<DashboardBloc, DashboardState>(
      buildWhen: (a, b) =>
          a.data?.accounts != b.data?.accounts ||
          a.data?.currency != b.data?.currency,
      builder: (context, state) {
        final data = state.data?.accounts;
        final currency = state.data?.currency.defaultCurrency ?? 'INR';
        return DashboardScaffold(
          theme: SectionTheme.accounts,
          title: 'Accounts Dashboard',
          children: data == null ? [_loading()] : [_content(data, currency)],
        );
      },
    );
  }

  Widget _loading() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );

  Widget _content(AccountsData data, String currency) {
    return Column(
      children: [
        StatCardRow(
          cards: [
            StatCard(
              icon: Icons.account_balance_wallet_outlined,
              iconColor: DashboardColors.iconTeal,
              value: CurrencyUtils.format(data.totalCreditors, currency),
              label: 'Total Creditors',
            ),
            StatCard(
              icon: Icons.account_balance_wallet_outlined,
              iconColor: DashboardColors.iconRed,
              value: CurrencyUtils.format(data.totalDebitors, currency),
              label: 'Total Debitors',
            ),
          ],
        ),
        const Gap(15),
        StatCardRow(cards: [
          StatCard(
            icon: Icons.call_received,
            iconColor: DashboardColors.iconGreen,
            value: CurrencyUtils.format(data.totalReceipts, currency),
            label: 'Total Receipts',
          ),
          StatCard(
            icon: Icons.call_made,
            iconColor: DashboardColors.iconOrange,
            value: CurrencyUtils.format(data.totalPayments, currency),
            label: 'Total Payments',
          ),
        ]),
        const Gap(16),
        ChartCard(
          title: 'Accounts Overview',
          child: BarChartWidget(
            // Pass RAW values (including negatives). BarChartWidget draws
            // negative bars downward in red, so users can see that a
            // -3.5M creditor balance is NOT a positive number.
            //
            // Previously all values were .abs()'d, which made both positive
            // and negative numbers look the same on the chart. Sign matters
            // for accounting figures.
            groups: [
              BarGroup(label: 'Debitors', values: [data.totalDebitors]),
              BarGroup(label: 'Receipts', values: [data.totalReceipts]),
              BarGroup(label: 'Payments', values: [data.totalPayments]),
              BarGroup(label: 'Creditors', values: [data.totalCreditors]),
            ],
            barColors: const [Color(0xFF2DD4A0)],
            negativeColor: DashboardColors.iconRed,
            barWidth: 28,
            height: 240,
            rotateLabels: -0.3,
          ),
        ),
      ],
    );
  }
}
