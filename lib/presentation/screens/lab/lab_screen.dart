import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/section_theme.dart';
import '../../../core/constants/string_constants.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/app_logger.dart';
import '../../blocs/lab/lab_bloc.dart';
import '../../widgets/chart_card.dart';
import '../../widgets/charts/horizontal_bar_chart.dart';
import '../../widgets/charts/single_line_chart.dart';
import '../../widgets/dashboard_scaffold.dart';
import '../../widgets/stat_card.dart';

class LabScreen extends StatelessWidget {
  const LabScreen({super.key});

  static const _tag = 'LabScreen';

  @override
  Widget build(BuildContext context) {
    AppLogger.info(_tag, 'build()');
    return BlocConsumer<LabBloc, LabState>(
      listener: (context, state) {
        AppLogger.info(_tag, 'state changed: ${state.status}');
        if (state.status == LabStatus.failure) {
          AppLogger.error(_tag, 'Lab load failed: ${state.errorMessage}');
        }
      },
      builder: (context, state) {
        return DashboardScaffold(
          theme: SectionTheme.lab,
          title: StringConstants.labDashboard,
          children: [_body(state)],
        );
      },
    );
  }

  Widget _body(LabState state) {
    if (state.status == LabStatus.loading || state.data == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    if (state.status == LabStatus.failure) {
      return _errorView(state.errorMessage);
    }

    final data = state.data!;
    return Column(
      children: [
        StatCardRow(
          cards: [
            StatCard(
              icon: Icons.science_outlined,
              iconColor: DashboardColors.iconPurple,
              value: '${data.totalTests}',
              label: StringConstants.totalTests,
            ),
            StatCard(
              icon: Icons.access_time,
              iconColor: DashboardColors.iconAmber,
              value: '${data.pending}',
              label: StringConstants.pending,
            ),
            StatCard(
              icon: Icons.check_circle_outline,
              iconColor: DashboardColors.iconGreen,
              value: '${data.completed}',
              label: StringConstants.completed,
            ),
          ],
        ),
        const Gap(16),
        ChartCard(
          title: StringConstants.monthlyTestsConducted,
          child: SingleLineChart(
            values:
                data.monthlyTests.map((p) => p.count.toDouble()).toList(),
            xLabels: data.monthlyTests.map((p) => p.month).toList(),
            lineColor: const Color(0xFFA78BFA),
            height: 200,
          ),
        ),
        const Gap(16),
        ChartCard(
          title: StringConstants.testsByType,
          child: HorizontalBarChart(
            items: data.testsByType
                .map((t) =>
                    HBarItem(label: t.type, value: t.count.toDouble()))
                .toList(),
            barColor: const Color(0xFFA78BFA),
            height: 220,
          ),
        ),
      ],
    );
  }

  Widget _errorView(String? msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 16),
      child: KStyles().reg(
        text: 'Failed to load Lab data\n${msg ?? ''}',
        size: 13,
        color: Colors.redAccent,
        textAlign: TextAlign.center,
      ),
    );
  }
}
