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
import '../../widgets/dashboard_scaffold.dart';
import '../../widgets/stat_card.dart';

class HrScreen extends StatelessWidget {
  const HrScreen({super.key});

  static const _tag = 'HrScreen';

  @override
  Widget build(BuildContext context) {
    AppLogger.info(_tag, 'build()');
    return BlocBuilder<DashboardBloc, DashboardState>(
      buildWhen: (a, b) => a.data?.hr != b.data?.hr,
      builder: (context, state) {
        final data = state.data?.hr;
        return DashboardScaffold(
          theme: SectionTheme.hr,
          title: 'HR Dashboard',
          children: data == null
              ? [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 80),
                    child: Center(
                        child: CircularProgressIndicator(color: Colors.white)),
                  )
                ]
              : [_content(data)],
        );
      },
    );
  }

  Widget _content(HrData data) {
    final total = data.totalPresent + data.totalAbsent;
    return Column(
      children: [
        StatCardRow(
          cards: [
            StatCard(
              icon: Icons.groups_outlined,
              iconColor: DashboardColors.iconBlue,
              value: '$total',
              label: 'Total Staff',
            ),
            StatCard(
              icon: Icons.person_outline,
              iconColor: DashboardColors.iconGreen,
              value: '${data.totalPresent}',
              label: 'Present',
            ),
            StatCard(
              icon: Icons.person_off_outlined,
              iconColor: DashboardColors.iconOrange,
              value: '${data.totalAbsent}',
              label: 'Absent',
            ),
          ],
        ),
        const Gap(16),
        ChartCard(
          title: 'Attendance',
          child: PieChartWidget(
            slices: [
              PieSlice(
                label: 'Present',
                value: data.totalPresent.toDouble(),
                color: DashboardColors.iconGreen,
              ),
              PieSlice(
                label: 'Absent',
                value: data.totalAbsent.toDouble(),
                color: DashboardColors.iconRed,
              ),
            ],
            size: 180,
            showPercentLabels: true,
          ),
        ),
        const Gap(12),
        Center(
          child: KStyles().reg(
            text: 'Last synced: ${data.lastSyncedTime}',
            size: 11,
            color: DashboardColors.textOnDarkMuted,
          ),
        ),
      ],
    );
  }
}
