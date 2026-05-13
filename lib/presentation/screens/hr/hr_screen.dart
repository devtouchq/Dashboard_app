import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/section_theme.dart';
import '../../../core/constants/string_constants.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/app_logger.dart';
import '../../blocs/hr/hr_bloc.dart';
import '../../widgets/chart_card.dart';
import '../../widgets/charts/bar_chart_widget.dart';
import '../../widgets/charts/pie_chart_widget.dart';
import '../../widgets/dashboard_scaffold.dart';
import '../../widgets/stat_card.dart';

class HrScreen extends StatelessWidget {
  const HrScreen({super.key});

  static const _tag = 'HrScreen';

  static const _pieColors = [
    DashboardColors.iconBlue,
    DashboardColors.iconGreen,
    DashboardColors.iconAmber,
    DashboardColors.iconPurple,
  ];

  @override
  Widget build(BuildContext context) {
    AppLogger.info(_tag, 'build()');
    return BlocConsumer<HrBloc, HrState>(
      listener: (context, state) {
        AppLogger.info(_tag, 'state changed: ${state.status}');
        if (state.status == HrStatus.failure) {
          AppLogger.error(_tag, 'HR load failed: ${state.errorMessage}');
        }
      },
      builder: (context, state) {
        return DashboardScaffold(
          theme: SectionTheme.hr,
          title: StringConstants.hrDashboard,
          children: [_body(state)],
        );
      },
    );
  }

  Widget _body(HrState state) {
    if (state.status == HrStatus.loading || state.data == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    if (state.status == HrStatus.failure) {
      return _errorView(state.errorMessage);
    }

    final data = state.data!;
    return Column(
      children: [
        StatCardRow(
          cards: [
            StatCard(
              icon: Icons.groups_outlined,
              iconColor: DashboardColors.iconBlue,
              value: '${data.totalStaff}',
              label: StringConstants.totalStaff,
            ),
            StatCard(
              icon: Icons.person_outline,
              iconColor: DashboardColors.iconGreen,
              value: '${data.present}',
              label: StringConstants.present,
            ),
            StatCard(
              icon: Icons.person_off_outlined,
              iconColor: DashboardColors.iconOrange,
              value: '${data.onLeave}',
              label: StringConstants.onLeave,
            ),
          ],
        ),
        const Gap(16),
        ChartCard(
          title: StringConstants.attendanceRate,
          child: BarChartWidget(
            groups: data.attendanceRate
                .map((p) => BarGroup(
                      label: p.month,
                      values: [p.presentPercent, p.absentPercent],
                    ))
                .toList(),
            barColors: const [
              Color(0xFF2DD4A0),
              Color(0xFFEF4444),
            ],
            barWidth: 10,
            yMax: 100,
            height: 220,
          ),
        ),
        const Gap(16),
        ChartCard(
          title: StringConstants.staffByDepartment,
          child: PieChartWidget(
            slices: List.generate(
              data.staffByDepartment.length,
              (i) => PieSlice(
                label: data.staffByDepartment[i].label,
                value: data.staffByDepartment[i].percent,
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
        text: 'Failed to load HR data\n${msg ?? ''}',
        size: 13,
        color: Colors.redAccent,
        textAlign: TextAlign.center,
      ),
    );
  }
}
