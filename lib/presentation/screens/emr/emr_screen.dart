import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/section_theme.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/models/dashboard_data.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../widgets/chart_card.dart';
import '../../widgets/charts/bar_chart_widget.dart';
import '../../widgets/charts/pie_chart_widget.dart';
import '../../widgets/charts/ranked_bar_list.dart';
import '../../widgets/dashboard_scaffold.dart';
import '../../widgets/stat_card.dart';

class EmrScreen extends StatelessWidget {
  const EmrScreen({super.key});

  static const _tag = 'EmrScreen';

  // Distinct colors for OP / IP / New / Repeater — reused for both
  // the stat cards and the bars so the eye can connect them quickly.
  static const _colorOP = DashboardColors.iconBlue;
  static const _colorIP = DashboardColors.iconPurple;
  static const _colorNew = DashboardColors.iconGreen;
  static const _colorRepeater = DashboardColors.iconPink;

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
    final ranked = [...data.doctorPatients]
      ..sort((a, b) => b.currMonthPatients.compareTo(a.currMonthPatients));

    final currMonth =
        ranked.isNotEmpty ? ranked.first.currMonthName : 'This Month';
    final prevMonth =
        ranked.isNotEmpty ? ranked.first.prevMonthName : 'Last Month';

    return Column(
      children: [
        // Row 1 — high-level counts
        //!-------total patients, advance amount, bill amount----------------
        StatCardRow(
          cards: [
            StatCard(
              icon: Icons.people_alt,
              iconColor: DashboardColors.iconBlue,
              value: '${data.totalPatients}',
              label: 'Total Patients',
            ),
            StatCard(
              //advance amount icon
              icon: Icons.attach_money_outlined,
              iconColor: DashboardColors.iconPink,
              value: '${data.opAdvanceAmount}',
              label: 'Advance Amount',
            ),
            StatCard(
              //bill amount icon
              icon: Icons.receipt_long_outlined,
              iconColor: DashboardColors.iconGreen,
              value: '${data.opBillAmount}',
              label: 'OP Bill Amount',
            ),
          ],
        ),
        const Gap(10),
        //!----------------total revenue, ip admitted----------------
        StatCardRow(
          cards: [
            StatCard(
              icon: Icons.monetization_on_outlined,
              iconColor: DashboardColors.iconBlue,
              value: '${data.totalRevenue}',
              label: 'Total Revenue',
            ),
            StatCard(
              icon: Icons.local_hospital_outlined,
              iconColor: DashboardColors.iconGreen,
              value: '${data.ipAdmittedAllTime}',
              label: 'Current Patients',
            ),
          ],
        ),
        const Gap(10),
        // Patient type breakdown chart, to visually connect with the OP/IP/New/Repeater stat cards below
        _patientTypeChart(data),
        const Gap(10),
        //  — OP / IP / New / Repeater breakdown
        StatCardRow(
          cards: [
            StatCard(
              icon: Icons.medical_services_outlined,
              iconColor: _colorOP,
              value: '${data.outpatientCount}',
              label: 'OP',
            ),
            StatCard(
              icon: Icons.airline_seat_individual_suite_outlined,
              iconColor: _colorIP,
              value: '${data.inpatientCount}',
              label: 'IP',
            ),
            StatCard(
              icon: Icons.person_add_alt_1_outlined,
              iconColor: _colorNew,
              value: '${data.newPatientCount}',
              label: 'New',
            ),
            StatCard(
              icon: Icons.repeat_rounded,
              iconColor: _colorRepeater,
              value: '${data.repeatPatientCount}',
              label: 'Repeater',
            ),
          ],
        ),

        const Gap(16),

        // Doctor ranking chart — only show if we have data, to avoid empty state
        if (ranked.isNotEmpty) _doctorChart(ranked, currMonth, prevMonth),

        const Gap(16),
        // Patient distribution pie chart — to visually
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

  /// 4-bar comparison chart: OP / IP / New / Repeater.
  /// Each bar uses `colorOverride` so it matches its stat card above.
  Widget _patientTypeChart(EmrData data) {
    return ChartCard(
      title: 'Patient Type Breakdown',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _legendDot('OP', _colorOP),
              _legendDot('IP', _colorIP),
              _legendDot('New', _colorNew),
              _legendDot('Repeater', _colorRepeater),
            ],
          ),
          const Gap(14),
          BarChartWidget(
            groups: [
              BarGroup(
                label: 'OP',
                values: [data.outpatientCount.toDouble()],
                colorOverride: _colorOP,
              ),
              BarGroup(
                label: 'IP',
                values: [data.inpatientCount.toDouble()],
                colorOverride: _colorIP,
              ),
              BarGroup(
                label: 'New',
                values: [data.newPatientCount.toDouble()],
                colorOverride: _colorNew,
              ),
              BarGroup(
                label: 'Repeater',
                values: [data.repeatPatientCount.toDouble()],
                colorOverride: _colorRepeater,
              ),
            ],
            barColors: const [_colorOP], // fallback (unused here)
            barWidth: 36,
            height: 220,
          ),
        ],
      ),
    );
  }

  Widget _legendDot(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const Gap(6),
        KStyles().semiBold(
          text: label,
          size: 11,
          color: DashboardColors.textOnDark,
        ),
      ],
    );
  }

  Widget _doctorChart(
      List<DoctorPatientCount> ranked, String currMonth, String prevMonth) {
    const barColor = Color(0xFF4A8DFF);
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
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _legendBlock(
                label: currMonth,
                color: barColor,
                suffix: '(Current)',
                bold: true,
              ),
              _legendBlock(
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

  Widget _legendBlock({
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
