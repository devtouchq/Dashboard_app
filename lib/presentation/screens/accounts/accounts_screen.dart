import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/string_constants.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/app_logger.dart';
import '../../blocs/accounts/accounts_bloc.dart';
import '../../blocs/navigation/navigation_bloc.dart';
import '../../widgets/app_card.dart';
import '../../widgets/charts/donut_chart.dart';
import '../../widgets/charts/receipts_payments_chart.dart';
import '../../widgets/dashboard_app_bar.dart';
import '../../widgets/legend_dot.dart';
import '../../widgets/safe_chart_wrapper.dart';
import '../../widgets/section_header.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  static const _tag = 'AccountsScreen';

  @override
  Widget build(BuildContext context) {
    AppLogger.info(_tag, 'build()');
    return Column(
      children: [
        DashboardAppBar(
          title: StringConstants.accounts,
          titleColor: AppColors.accountsColor,
          showBackButton: true,
          onBack: () =>
              context.read<NavigationBloc>().add(const NavigationTabChanged(0)),
          actions: [
            AppBarIconButton(icon: Icons.notifications_outlined, onTap: () {}),
          ],
        ),
        Expanded(
          child: BlocConsumer<AccountsBloc, AccountsState>(
            listener: (context, state) {
              AppLogger.info(_tag, 'state changed: ${state.status}');
              if (state.status == AccountsStatus.failure) {
                AppLogger.error(
                  _tag,
                  'Accounts load failed: ${state.errorMessage}',
                );
              }
            },
            builder: (context, state) {
              if (state.status == AccountsStatus.loading ||
                  state.data == null) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.status == AccountsStatus.failure) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: KStyles().reg(
                      text:
                          'Failed to load accounts.\n${state.errorMessage ?? ''}',
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
                  context.read<AccountsBloc>().add(const AccountsRefreshed());
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
                  children: [
                    _heroCard(data),
                    _receiptsVsPaymentsCard(data),
                    SectionHeader(
                      title: StringConstants.frontoffice,
                      accentColor: AppColors.accountsColor,
                      leadingIcon: Icons.storefront_outlined,
                    ),
                    _frontofficeStrip(data),
                    _collectionDonutCard(data),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _heroCard(data) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      gradient: const LinearGradient(
        colors: AppColors.accountsGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      showBorder: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KStyles().reg(
            text: StringConstants.netPosition,
            size: 13,
            color: AppColors.white.withOpacity(0.9),
          ),
          const Gap(6),
          KStyles().bold(
            text: '₹6.04 Cr',
            size: 28,
            color: AppColors.white,
          ),
          const Gap(12),
          Row(
            children: [
              _heroStat(StringConstants.debiters, '+6,12,32,078'),
              Container(
                width: 1,
                height: 32,
                color: Colors.white.withOpacity(0.25),
                margin: const EdgeInsets.symmetric(horizontal: 14),
              ),
              _heroStat(StringConstants.crediters, '−68,17,071'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KStyles().reg(
          text: label,
          size: 11,
          color: AppColors.white.withOpacity(0.85),
        ),
        const Gap(2),
        KStyles().semiBold(
          text: value,
          size: 14,
          color: AppColors.white,
        ),
      ],
    );
  }

  Widget _receiptsVsPaymentsCard(data) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          const CardTitleRow(
            title: StringConstants.receiptsVsPayments,
            pillText: StringConstants.today,
          ),
          SafeChartWrapper(
            tag: 'receipts_vs_payments',
            height: 90,
            builder: () => ReceiptsPaymentsChart(points: data.cashFlow),
          ),
          const Gap(10),
          Row(
            children: [
              const LegendDot(
                color: AppColors.accountsColor,
                label: StringConstants.receipts,
              ),
              const Gap(16),
              const LegendDot(
                color: AppColors.emrColor,
                label: StringConstants.payments,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _frontofficeStrip(data) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          _strip('${data.checkIn}', StringConstants.checkIn,
              valueColor: AppColors.accountsColor, hasDivider: true),
          _strip('${data.currentGuests}', StringConstants.current,
              hasDivider: true),
          _strip('${data.expected}', StringConstants.expected,
              hasDivider: true),
          _strip('${data.checkOut}', StringConstants.checkOut),
        ],
      ),
    );
  }

  Widget _strip(String value, String label,
      {Color valueColor = AppColors.textPrimary, bool hasDivider = false}) {
    return Expanded(
      child: Container(
        decoration: hasDivider
            ? const BoxDecoration(
                border: Border(
                  right: BorderSide(color: AppColors.dividerColor),
                ),
              )
            : null,
        padding: const EdgeInsets.all(4),
        child: Column(
          children: [
            KStyles().bold(
              text: value,
              size: 20,
              color: valueColor,
            ),
            const Gap(2),
            KStyles().reg(
              text: label,
              size: 11,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _collectionDonutCard(data) {
    final allSlices = data.collectionSlices as List;
    AppLogger.info(
      _tag,
      'Building collection donut with ${allSlices.length} slices, '
      'total=${data.totalCollection}',
    );

    final colorByMode = {
      StringConstants.cheque: AppColors.emrColor,
      StringConstants.cash: AppColors.accountsColor,
      StringConstants.upi: AppColors.storeColor,
    };

    final donutSlices = <DonutSlice>[];
    for (final s in allSlices) {
      if (s.percent > 0) {
        donutSlices.add(
          DonutSlice(
            label: s.mode,
            value: s.percent.toDouble(),
            color: colorByMode[s.mode] ?? AppColors.grey,
          ),
        );
      }
    }

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          const CardTitleRow(
            title: StringConstants.totalCollection,
            pillText: StringConstants.today,
          ),
          Row(
            children: [
              SafeChartWrapper(
                tag: 'collection_donut',
                height: 100,
                builder: () => DonutChart(
                  slices: donutSlices,
                  centerText: '₹${data.totalCollection.toStringAsFixed(0)}',
                  centerSubText: StringConstants.collected,
                  size: 100,
                ),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  children: allSlices.map<Widget>((s) {
                    final isActive = s.percent > 0;
                    final color = colorByMode[s.mode] ?? AppColors.grey;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          LegendDot(
                            color: isActive ? color : const Color(0xFFE5E7EB),
                            label: s.mode,
                            textColor: isActive
                                ? AppColors.textSecondary
                                : AppColors.textMuted,
                          ),
                          const Spacer(),
                          KStyles().semiBold(
                            text: '${s.percent.toStringAsFixed(0)}%',
                            size: 13,
                            color: isActive
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
