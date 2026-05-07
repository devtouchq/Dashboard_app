import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/string_constants.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/app_logger.dart';
import '../../blocs/emr/emr_bloc.dart';
import '../../widgets/app_card.dart';
import '../../widgets/charts/patient_flow_chart.dart';
import '../../widgets/dashboard_app_bar.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/safe_chart_wrapper.dart';

class EmrScreen extends StatelessWidget {
  const EmrScreen({super.key});

  static const _tag = 'EmrScreen';

  @override
  Widget build(BuildContext context) {
    AppLogger.info(_tag, 'build()');
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            DashboardAppBar(
              title: StringConstants.emr,
              titleColor: AppColors.emrColor,
              showBackButton: true,
              onBack: () => Navigator.pop(context),
              actions: [
                AppBarIconButton(
                  icon: Icons.notifications_outlined,
                  onTap: () {},
                ),
              ],
            ),
            Expanded(
              child: BlocConsumer<EmrBloc, EmrState>(
                listener: (context, state) {
                  AppLogger.info(_tag, 'state changed: ${state.status}');
                  if (state.status == EmrStatus.failure) {
                    AppLogger.error(
                      _tag,
                      'EMR load failed: ${state.errorMessage}',
                    );
                  }
                },
                builder: (context, state) {
                  if (state.status == EmrStatus.loading || state.data == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.status == EmrStatus.failure) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: KStyles().reg(
                          text:
                              'Failed to load EMR data.\n${state.errorMessage ?? ''}',
                          size: 14,
                          color: AppColors.emrColor,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final data = state.data!;
                  return RefreshIndicator(
                    onRefresh: () async {
                      AppLogger.info(_tag, 'pull-to-refresh');
                      context.read<EmrBloc>().add(const EmrRefreshed());
                    },
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
                      children: [
                        _heroCard(data),
                        _metricsGrid(data),
                        _patientFlowCard(data),
                        _ipOpGrid(data),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroCard(data) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      gradient: const LinearGradient(
        colors: [Color(0xFFFEF2F2), Color(0xFFFEE2E2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      showBorder: false,
      child: Row(
        children: [
          SizedBox(
            width: 86,
            height: 86,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 86,
                  height: 86,
                  child: CircularProgressIndicator(
                    value: 0.85,
                    strokeWidth: 7,
                    backgroundColor: const Color(0xFFFECACA),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.emrColor,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    KStyles().bold(
                      text: '${data.currentPatients}',
                      size: 18,
                      color: const Color(0xFF7F1D1D),
                    ),
                    KStyles().reg(
                      text: 'current',
                      size: 10,
                      color: const Color(0xFF991B1B),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                KStyles().reg(
                  text: StringConstants.todaysStatus,
                  size: 13,
                  color: const Color(0xFF991B1B),
                ),
                const Gap(4),
                KStyles().bold(
                  text: '${data.currentPatients} ${StringConstants.patients}',
                  size: 22,
                  color: const Color(0xFF7F1D1D),
                  height: 1.1,
                ),
                const Gap(6),
                KStyles().reg(
                  text: StringConstants.inActiveCare,
                  size: 12,
                  color: const Color(0xFF991B1B),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricsGrid(data) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.5,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          MetricCard(
            icon: Icons.group,
            label: StringConstants.totalPatients,
            value: '${data.totalPatients}',
            gradient: AppColors.accountsGradient,
          ),
          MetricCard(
            icon: Icons.assignment_add,
            label: StringConstants.registration,
            value: '${data.registration}',
            gradient: AppColors.emrGradient,
          ),
          MetricCard(
            icon: Icons.medical_services_outlined,
            label: StringConstants.consultation,
            value: '${data.consultation}',
            gradient: AppColors.amberGradient,
          ),
          MetricCard(
            icon: Icons.bed_outlined,
            label: StringConstants.bedsOccupied,
            value: '${data.bedsOccupied}',
            gradient: AppColors.purpleGradient,
          ),
        ],
      ),
    );
  }

  Widget _patientFlowCard(data) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          const CardTitleRow(
            title: StringConstants.patientFlow,
            pillText: StringConstants.allTime,
          ),
          SafeChartWrapper(
            tag: 'patient_flow',
            height: 150,
            builder: () => PatientFlowBarChart(items: data.patientFlow),
          ),
        ],
      ),
    );
  }

  Widget _ipOpGrid(data) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        LightMetricCard(
          label: StringConstants.ip,
          value: '${data.ipPatients}',
          icon: Icons.bed_outlined,
          bgColor: AppColors.lmCoralBg,
          textColor: AppColors.lmCoralText,
        ),
        LightMetricCard(
          label: StringConstants.op,
          value: '${data.opPatients}',
          icon: Icons.meeting_room_outlined,
          bgColor: AppColors.lmAmberBg,
          textColor: AppColors.lmAmberText,
        ),
        LightMetricCard(
          label: StringConstants.newPatient,
          value: '${data.newPatients}',
          icon: Icons.person_add_alt,
          bgColor: AppColors.lmBlueBg,
          textColor: AppColors.lmBlueText,
        ),
        LightMetricCard(
          label: StringConstants.repeater,
          value: '${data.repeaterPatients}',
          icon: Icons.repeat,
          bgColor: AppColors.lmGreenBg,
          textColor: AppColors.lmGreenText,
        ),
      ],
    );
  }
}
