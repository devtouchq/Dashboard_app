import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/section_theme.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/models/dashboard_data.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../widgets/chart_card.dart';
import '../../widgets/charts/pie_chart_widget.dart';
import '../../widgets/charts/ranked_bar_list.dart';
import '../../widgets/dashboard_scaffold.dart';
import '../../widgets/stat_card.dart';

class EmrScreen extends StatelessWidget {
  const EmrScreen({super.key});

  static const _tag = 'EmrScreen';

  @override
  Widget build(BuildContext context) {
    AppLogger.info(_tag, 'build()');
    return BlocBuilder<DashboardBloc, DashboardState>(
      buildWhen: (a, b) => a.data?.emr != b.data?.emr,
      builder: (context, state) {
        final data = state.data?.emr;
        return DashboardScaffold(
          theme: SectionTheme.emr,
          title: 'EMR Dashboard',
          children: data == null ? [_loading()] : [_content(data)],
        );
      },
    );
  }

  Widget _loading() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );

  Widget _content(EmrData data) {
    // Rank by current-month patient count (the metric that drives incentives).
    final ranked = [...data.doctorPatients]
      ..sort((a, b) => b.currMonthPatients.compareTo(a.currMonthPatients));

    // Pull month names from the first record (all rows share the same months).
    final currMonth =
        ranked.isNotEmpty ? ranked.first.currMonthName : 'This Month';
    final prevMonth =
        ranked.isNotEmpty ? ranked.first.prevMonthName : 'Last Month';

    return Column(
      children: [
        StatCardRow(
          cards: [
            StatCard(
              icon: Icons.people_alt,
              iconColor: DashboardColors.iconBlue,
              value: '${data.totalPatients}',
              label: 'Total Patients',
            ),
            StatCard(
              icon: Icons.calendar_month,
              iconColor: DashboardColors.iconPink,
              value: '${data.appointments}',
              label: 'Appointments',
            ),
            StatCard(
              icon: Icons.local_hospital_outlined,
              iconColor: DashboardColors.iconGreen,
              value: '${data.ipAdmittedAllTime}',
              label: 'IP Admitted',
            ),
          ],
        ),
        const Gap(16),
        if (ranked.isNotEmpty) _doctorChart(ranked, currMonth, prevMonth),
        const Gap(16),
        ChartCard(
          title: 'Patient Distribution',
          child: PieChartWidget(
            slices: [
              PieSlice(
                label: 'Male',
                value: data.maleCount.toDouble(),
                color: DashboardColors.iconBlue,
              ),
              PieSlice(
                label: 'Female',
                value: data.femaleCount.toDouble(),
                color: DashboardColors.iconPink,
              ),
            ],
            size: 180,
            showPercentLabels: true,
          ),
        ),
      ],
    );
  }

  Widget _doctorChart(
      List<DoctorPatientCount> ranked, String currMonth, String prevMonth) {
    const barColor = Color(0xFF4A8DFF); // bold blue (current)
    return ChartCard(
      title: 'Patients per Doctor',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KStyles().reg(
            text:
                'Ranked by current-month patient count — for incentive tracking',
            size: 11,
            color: DashboardColors.textOnDarkMuted,
          ),
          const Gap(12),
          // Two-tone legend so users can read which bar is which month.
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _legendChip(
                label: currMonth,
                color: barColor,
                suffix: '(Current)',
                bold: true,
              ),
              _legendChip(
                label: prevMonth,
                color:
                    const Color.fromARGB(255, 250, 0, 0).withValues(alpha: 0.4),
                suffix: '(Previous)',
                bold: false,
              ),
            ],
          ),
          const Gap(14),
          RankedBarList(
            items: ranked
                .map((d) => RankedBarItem(
                      label: d.doctor,
                      value: d.currMonthPatients.toDouble(),
                      previousValue: d.prevMonthPatients.toDouble(),
                    ))
                .toList(),
            barColor: barColor,
            currentLabel: currMonth,
            previousLabel: prevMonth,
          ),
        ],
      ),
    );
  }

  Widget _legendChip({
    required String label,
    required Color color,
    required String suffix,
    required bool bold,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Gap(6),
          bold
              ? KStyles().semiBold(
                  text: label,
                  size: 11,
                  color: DashboardColors.textOnDark,
                )
              : KStyles().reg(
                  text: label,
                  size: 11,
                  color: DashboardColors.textOnDarkSecondary,
                ),
          const Gap(4),
          KStyles().reg(
            text: suffix,
            size: 10,
            color: DashboardColors.textOnDarkMuted,
          ),
        ],
      ),
    );
  }
}
