import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/section_theme.dart';
import '../../../core/constants/string_constants.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/app_logger.dart';
import '../../blocs/emr/emr_bloc.dart';
import '../../widgets/chart_card.dart';
import '../../widgets/charts/bar_chart_widget.dart';
import '../../widgets/charts/pie_chart_widget.dart';
import '../../widgets/dashboard_scaffold.dart';
import '../../widgets/stat_card.dart';

class EmrScreen extends StatelessWidget {
  const EmrScreen({super.key});

  static const _tag = 'EmrScreen';

  @override
  Widget build(BuildContext context) {
    AppLogger.info(_tag, 'build()');
    return BlocConsumer<EmrBloc, EmrState>(
      listener: (context, state) {
        AppLogger.info(_tag, 'state changed: ${state.status}');
        if (state.status == EmrStatus.failure) {
          AppLogger.error(_tag, 'EMR load failed: ${state.errorMessage}');
        }
      },
      builder: (context, state) {
        return DashboardScaffold(
          theme: SectionTheme.emr,
          title: StringConstants.emrDashboard,
          children: [_body(context, state)],
        );
      },
    );
  }

  Widget _body(BuildContext context, EmrState state) {
    if (state.status == EmrStatus.loading || state.data == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    if (state.status == EmrStatus.failure) {
      return _errorView(state.errorMessage);
    }

    final data = state.data!;
    return Column(
      children: [
        StatCardRow(
          cards: [
            StatCard(
              icon: Icons.people_alt,
              iconColor: DashboardColors.iconBlue,
              value: '${data.totalPatients}',
              label: StringConstants.totalPatients,
            ),
            StatCard(
              icon: Icons.calendar_month,
              iconColor: DashboardColors.iconPink,
              value: '${data.appointments}',
              label: StringConstants.appointments,
            ),
            StatCard(
              icon: Icons.monitor_heart,
              iconColor: DashboardColors.iconGreen,
              value: '${data.activeCases}',
              label: StringConstants.activeCases,
            ),
          ],
        ),
        const Gap(16),
        ChartCard(
          title: StringConstants.monthlyPatientGrowth,
          child: BarChartWidget(
            groups: data.monthlyGrowth
                .map((p) =>
                    BarGroup(label: p.month, values: [p.patients.toDouble()]))
                .toList(),
            barColors: const [DashboardColors.iconBlue],
            barWidth: 22,
          ),
        ),
        const Gap(16),
        ChartCard(
          title: StringConstants.patientDistribution,
          child: PieChartWidget(
            slices: [
              PieSlice(
                label: StringConstants.outpatient,
                value: data.outpatientCount.toDouble(),
                color: DashboardColors.iconBlue,
              ),
              PieSlice(
                label: StringConstants.inpatient,
                value: data.inpatientCount.toDouble(),
                color: DashboardColors.iconPurple,
              ),
              PieSlice(
                label: StringConstants.emergency,
                value: data.emergencyCount.toDouble(),
                color: DashboardColors.iconRed,
              ),
            ],
            size: 180,
            showPercentLabels: true,
          ),
        ),
      ],
    );
  }

  Widget _errorView(String? msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 16),
      child: KStyles().reg(
        text: 'Failed to load EMR data\n${msg ?? ''}',
        size: 13,
        color: Colors.redAccent,
        textAlign: TextAlign.center,
      ),
    );
  }
}
