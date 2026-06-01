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
              value: CurrencyUtils.format(data.totalRevenue, currency),
              label: 'Total Creditors',
            ),
            StatCard(
              icon: Icons.account_balance_wallet_outlined,
              iconColor: DashboardColors.iconRed,
              value: CurrencyUtils.format(data.totalDebitors, currency),
              label: 'Total Debtors',
            ),
          ],
        ),
        const Gap(15),
        StatCardRow(cards: [
          StatCard(
            icon: Icons.call_received,
            iconColor: DashboardColors.iconGreen,
            value: CurrencyUtils.format(data.totalReceipts, currency),
            label: 'Receipts',
          ),
          StatCard(
            icon: Icons.call_made,
            iconColor: DashboardColors.iconOrange,
            value: CurrencyUtils.format(data.totalPayments, currency),
            label: 'Payments',
          ),
        ]),
        const Gap(16),
        ChartCard(
          title: 'Receivables vs Collection',
          child: BarChartWidget(
            groups: [
              BarGroup(label: 'Debitors', values: [data.totalDebitors.abs()]),
              BarGroup(label: 'Receipts', values: [data.totalReceipts.abs()]),
              BarGroup(label: 'Payments', values: [data.totalPayments.abs()]),
              BarGroup(
                  label: 'Collection', values: [data.totalCollection.abs()]),
            ],
            barColors: const [Color(0xFF2DD4A0)],
            barWidth: 28,
            height: 220,
            rotateLabels: -0.3,
          ),
        ),
      ],
    );
  }
}
