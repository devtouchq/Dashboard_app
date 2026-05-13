import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/section_theme.dart';
import '../../../core/constants/string_constants.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/app_logger.dart';
import '../../blocs/banquet/banquet_bloc.dart';
import '../../widgets/chart_card.dart';
import '../../widgets/charts/horizontal_bar_chart.dart';
import '../../widgets/charts/single_line_chart.dart';
import '../../widgets/dashboard_scaffold.dart';
import '../../widgets/stat_card.dart';

class BanquetScreen extends StatelessWidget {
  const BanquetScreen({super.key});

  static const _tag = 'BanquetScreen';

  @override
  Widget build(BuildContext context) {
    AppLogger.info(_tag, 'build()');
    return BlocConsumer<BanquetBloc, BanquetState>(
      listener: (context, state) {
        AppLogger.info(_tag, 'state changed: ${state.status}');
        if (state.status == BanquetStatus.failure) {
          AppLogger.error(_tag, 'Banquet load failed: ${state.errorMessage}');
        }
      },
      builder: (context, state) {
        return DashboardScaffold(
          theme: SectionTheme.banquet,
          title: StringConstants.banquetDashboard,
          children: [_body(state)],
        );
      },
    );
  }

  Widget _body(BanquetState state) {
    if (state.status == BanquetStatus.loading || state.data == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    if (state.status == BanquetStatus.failure) {
      return _errorView(state.errorMessage);
    }

    final data = state.data!;
    return Column(
      children: [
        StatCardRow(
          cards: [
            StatCard(
              icon: Icons.event_outlined,
              iconColor: DashboardColors.iconPink,
              value: '${data.totalEvents}',
              label: StringConstants.totalEvents,
            ),
            StatCard(
              icon: Icons.groups_outlined,
              iconColor: DashboardColors.iconPurple,
              value: '${data.thisMonth}',
              label: StringConstants.thisMonth,
            ),
            StatCard(
              icon: Icons.attach_money,
              iconColor: DashboardColors.iconGreen,
              value: '\$${(data.revenue / 1000).toStringAsFixed(0)}k',
              label: StringConstants.revenueLabel,
            ),
          ],
        ),
        const Gap(16),
        ChartCard(
          title: StringConstants.monthlyRevenueTrend,
          child: SingleLineChart(
            values: data.revenueTrend.map((p) => p.revenue).toList(),
            xLabels: data.revenueTrend.map((p) => p.month).toList(),
            lineColor: const Color(0xFFEC4899),
            height: 220,
          ),
        ),
        const Gap(16),
        ChartCard(
          title: StringConstants.eventsByType,
          child: HorizontalBarChart(
            items: data.eventsByType
                .map((e) =>
                    HBarItem(label: e.type, value: e.count.toDouble()))
                .toList(),
            barColor: const Color(0xFFEC4899),
            height: 240,
          ),
        ),
      ],
    );
  }

  Widget _errorView(String? msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 16),
      child: KStyles().reg(
        text: 'Failed to load Banquet data\n${msg ?? ''}',
        size: 13,
        color: Colors.redAccent,
        textAlign: TextAlign.center,
      ),
    );
  }
}
