import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/section_theme.dart';
import '../../../core/constants/string_constants.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/app_logger.dart';
import '../../blocs/frontoffice/frontoffice_bloc.dart';
import '../../widgets/chart_card.dart';
import '../../widgets/charts/bar_chart_widget.dart';
import '../../widgets/charts/single_line_chart.dart';
import '../../widgets/dashboard_scaffold.dart';
import '../../widgets/stat_card.dart';

class FrontofficeScreen extends StatelessWidget {
  const FrontofficeScreen({super.key});

  static const _tag = 'FrontofficeScreen';

  @override
  Widget build(BuildContext context) {
    AppLogger.info(_tag, 'build()');
    return BlocConsumer<FrontofficeBloc, FrontofficeState>(
      listener: (context, state) {
        AppLogger.info(_tag, 'state changed: ${state.status}');
        if (state.status == FrontofficeStatus.failure) {
          AppLogger.error(
              _tag, 'Frontoffice load failed: ${state.errorMessage}');
        }
      },
      builder: (context, state) {
        return DashboardScaffold(
          theme: SectionTheme.frontoffice,
          title: StringConstants.frontofficeDashboard,
          children: [_body(state)],
        );
      },
    );
  }

  Widget _body(FrontofficeState state) {
    if (state.status == FrontofficeStatus.loading || state.data == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    if (state.status == FrontofficeStatus.failure) {
      return _errorView(state.errorMessage);
    }

    final data = state.data!;
    return Column(
      children: [
        StatCardRow(
          cards: [
            StatCard(
              icon: Icons.login_outlined,
              iconColor: DashboardColors.iconBlue,
              value: '${data.checkIns}',
              label: StringConstants.checkIns,
            ),
            StatCard(
              icon: Icons.access_time,
              iconColor: DashboardColors.iconAmber,
              value: '${data.inQueue}',
              label: StringConstants.inQueue,
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
          title: StringConstants.hourlyVisitorTraffic,
          child: SingleLineChart(
            values: data.hourlyTraffic
                .map((p) => p.visitors.toDouble())
                .toList(),
            xLabels: data.hourlyTraffic.map((p) => p.hour).toList(),
            lineColor: const Color(0xFF2DD4A0),
            height: 220,
          ),
        ),
        const Gap(16),
        ChartCard(
          title: StringConstants.inquiriesByType,
          child: BarChartWidget(
            groups: data.inquiriesByType
                .map((i) => BarGroup(
                      label: i.type.replaceAll(' ', '\n'),
                      values: [i.count.toDouble()],
                    ))
                .toList(),
            barColors: const [Color(0xFF2DD4A0)],
            barWidth: 28,
            rotateLabels: -0.25,
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
        text: 'Failed to load Frontoffice data\n${msg ?? ''}',
        size: 13,
        color: Colors.redAccent,
        textAlign: TextAlign.center,
      ),
    );
  }
}
