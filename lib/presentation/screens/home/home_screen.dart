import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/string_constants.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/app_logger.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../widgets/app_card.dart';
import '../../widgets/charts/donut_chart.dart';
import '../../widgets/charts/stacked_area_chart.dart';
import '../../widgets/dashboard_app_bar.dart';
import '../../widgets/legend_dot.dart';
import '../../widgets/safe_chart_wrapper.dart';
import '../../widgets/section_header.dart';
import '../accounts/accounts_screen.dart';
import '../banquet/banquet_screen.dart';
import '../bar/bar_screen.dart';
import '../emr/emr_screen.dart';
import '../frontoffice/frontoffice_screen.dart';
import '../hr/hr_screen.dart';
import '../lab/lab_screen.dart';
import '../restaurant/restaurant_screen.dart';
import '../store/store_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _tag = 'HomeScreen';

  @override
  Widget build(BuildContext context) {
    AppLogger.info(_tag, 'build()');
    return Column(
      children: [
        DashboardAppBar(
          greeting: StringConstants.welcomeBack,
          title: StringConstants.dashboard,
          actions: [
            AppBarIconButton(icon: Icons.search, onTap: () {}),
            AppBarIconButton(
              icon: Icons.notifications_outlined,
              onTap: () {},
              showBadge: true,
            ),
          ],
        ),
        Expanded(
          child: BlocConsumer<DashboardBloc, DashboardState>(
            listener: (context, state) {
              AppLogger.info(_tag, 'state changed: ${state.status}');
              if (state.status == DashboardStatus.failure) {
                AppLogger.error(
                  _tag,
                  'Dashboard load failed: ${state.errorMessage}',
                );
              }
            },
            builder: (context, state) {
              if (state.status == DashboardStatus.loading ||
                  state.data == null) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.status == DashboardStatus.failure) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: KStyles().reg(
                      text:
                          'Failed to load dashboard.\n${state.errorMessage ?? ''}',
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
                  context.read<DashboardBloc>().add(const DashboardRefreshed());
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
                  children: [
                    _heroCard(data),
                    const Gap(15),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.accountsColor.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          SectionHeader(
                            title: StringConstants.accounts,
                            accentColor: AppColors.sectionHeaderBg,
                            actionLabel: StringConstants.viewAll,
                            onActionTap: () => _openSection(
                              context,
                              const AccountsScreen(),
                              'Accounts',
                            ),
                          ),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _openSection(
                              context,
                              const AccountsScreen(),
                              'Accounts',
                            ),
                            child: _accountsRow(data),
                          ),
                        ],
                      ),
                    ),
                    const Gap(25),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.emrColor.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          SectionHeader(
                            title: StringConstants.emr,
                            accentColor: AppColors.sectionHeaderBg,
                            actionLabel: StringConstants.viewAll,
                            onActionTap: () =>
                                _openSection(context, const EmrScreen(), 'EMR'),
                          ),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () =>
                                _openSection(context, const EmrScreen(), 'EMR'),
                            child: _emrCard(data),
                          ),
                        ],
                      ),
                    ),
                    const Gap(25),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.storeColor.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          SectionHeader(
                            title: StringConstants.store,
                            accentColor: AppColors.sectionHeaderBg,
                            actionLabel: StringConstants.viewAll,
                            onActionTap: () => _openSection(
                                context, const StoreScreen(), 'Store'),
                          ),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _openSection(
                                context, const StoreScreen(), 'Store'),
                            child: _storeCard(data),
                          ),
                        ],
                      ),
                    ),
                    const Gap(25),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.hrColor.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          SectionHeader(
                            title: StringConstants.hr,
                            accentColor: AppColors.sectionHeaderBg,
                            actionLabel: StringConstants.viewAll,
                            onActionTap: () =>
                                _openSection(context, const HrScreen(), 'HR'),
                          ),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () =>
                                _openSection(context, const HrScreen(), 'HR'),
                            child: _simpleSectionTile(
                              icon: Icons.groups_outlined,
                              title: 'Attendance',
                              subtitle: '10 present · 45 absent',
                              accent: AppColors.hrColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(25),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color:
                            AppColors.restaurantColor.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          SectionHeader(
                            title: StringConstants.restaurant,
                            accentColor: AppColors.sectionHeaderBg,
                            actionLabel: StringConstants.viewAll,
                            onActionTap: () => _openSection(context,
                                const RestaurantScreen(), 'Restaurant'),
                          ),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _openSection(context,
                                const RestaurantScreen(), 'Restaurant'),
                            child: _simpleSectionTile(
                              icon: Icons.restaurant_outlined,
                              title: 'Restaurant',
                              subtitle: '5 pax · ₹10.00 collected',
                              accent: AppColors.restaurantColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(25),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.labColor.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          SectionHeader(
                            title: StringConstants.lab,
                            accentColor: AppColors.sectionHeaderBg,
                            actionLabel: StringConstants.viewAll,
                            onActionTap: () =>
                                _openSection(context, const LabScreen(), 'Lab'),
                          ),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () =>
                                _openSection(context, const LabScreen(), 'Lab'),
                            child: _simpleSectionTile(
                              icon: Icons.science_outlined,
                              title: 'Lab',
                              subtitle: '8 tests · ₹20.00 collected',
                              accent: AppColors.labColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(25),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.barColor.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          SectionHeader(
                            title: StringConstants.bar,
                            accentColor: AppColors.sectionHeaderBg,
                            actionLabel: StringConstants.viewAll,
                            onActionTap: () =>
                                _openSection(context, const BarScreen(), 'Bar'),
                          ),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () =>
                                _openSection(context, const BarScreen(), 'Bar'),
                            child: _simpleSectionTile(
                              icon: Icons.local_bar_outlined,
                              title: 'Bar',
                              subtitle: '₹10.00 today',
                              accent: AppColors.barColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(25),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color:
                            AppColors.frontofficeColor.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          SectionHeader(
                            title: StringConstants.frontofficeFull,
                            accentColor: AppColors.sectionHeaderBg,
                            actionLabel: StringConstants.viewAll,
                            onActionTap: () => _openSection(context,
                                const FrontofficeScreen(), 'Frontoffice'),
                          ),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _openSection(context,
                                const FrontofficeScreen(), 'Frontoffice'),
                            child: _simpleSectionTile(
                              icon: Icons.meeting_room_outlined,
                              title: 'Frontoffice',
                              subtitle: '120 check-ins · ₹55,146 collected',
                              accent: AppColors.frontofficeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(25),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.banquetColor.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          SectionHeader(
                            title: StringConstants.banquet,
                            accentColor: AppColors.sectionHeaderBg,
                            actionLabel: StringConstants.viewAll,
                            onActionTap: () => _openSection(
                                context, const BanquetScreen(), 'Banquet'),
                          ),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _openSection(
                                context, const BanquetScreen(), 'Banquet'),
                            child: _simpleSectionTile(
                              icon: Icons.celebration_outlined,
                              title: 'Banquet',
                              subtitle: '0 reservations · 0 functions',
                              accent: AppColors.banquetColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _simpleSectionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                KStyles().semiBold(
                  text: title,
                  size: 14,
                  color: AppColors.textPrimary,
                ),
                const Gap(2),
                KStyles().reg(
                  text: subtitle,
                  size: 12,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            size: 20,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }

  void _openSection(BuildContext context, Widget screen, String name) {
    AppLogger.info(_tag, 'open section → $name');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Widget _heroCard(data) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      gradient: const LinearGradient(
        colors: AppColors.heroGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    KStyles().med(
                      text: StringConstants.combinedRevenue,
                      //size: 13,
                      color: AppColors.white.withValues(alpha: 0.75),
                    ),
                    const Gap(4),
                    KStyles().bold(
                      text: '₹${data.combinedRevenue.toStringAsFixed(0)}',
                      size: 28,
                      color: AppColors.white,
                    ),
                    const Gap(4),
                    Row(
                      children: [
                        const Icon(
                          Icons.trending_up,
                          size: 14,
                          color: Color(0xFF34D399),
                        ),
                        const Gap(4),
                        KStyles().med(
                          text:
                              '+${data.trendChangePercent}% ${StringConstants.vsLastWeek}',
                          size: 12,
                          color: const Color(0xFF34D399),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: KStyles().med(
                  text: '7 days',
                  size: 11,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
          const Gap(14),
          const Wrap(
            spacing: 14, // gap between dots on the same row
            runSpacing: 8, // gap between rows when they wrap
            children: [
              LegendDot(
                color: AppColors.seriesAccounts,
                label: 'Accounts',
                textColor: Color(0xFFCBD5E1),
              ),
              LegendDot(
                color: AppColors.seriesEmr,
                label: 'EMR',
                textColor: Color(0xFFCBD5E1),
              ),
              LegendDot(
                color: AppColors.seriesStore,
                label: 'Store',
                textColor: Color(0xFFCBD5E1),
              ),
              LegendDot(
                color: AppColors.seriesHr,
                label: 'HR',
                textColor: Color(0xFFCBD5E1),
              ),
              LegendDot(
                color: AppColors.seriesRestaurant,
                label: 'Restaurant',
                textColor: Color(0xFFCBD5E1),
              ),
              LegendDot(
                color: AppColors.seriesLab,
                label: 'Lab',
                textColor: Color(0xFFCBD5E1),
              ),
              LegendDot(
                color: AppColors.seriesBar,
                label: 'Bar',
                textColor: Color(0xFFCBD5E1),
              ),
              LegendDot(
                color: AppColors.seriesFrontoffice,
                label: 'Frontoffice',
                textColor: Color(0xFFCBD5E1),
              ),
              LegendDot(
                color: AppColors.seriesBanquet,
                label: 'Banquet',
                textColor: Color(0xFFCBD5E1),
              ),
            ],
          ),
          const Gap(8),
          Center(
            child: SafeChartWrapper(
              tag: 'home_stacked_area',
              height: 180,
              width: 350,
              builder: () => StackedAreaChart(points: data.trend),
            ),
          ),
        ],
      ),
    );
  }

  Widget _accountsRow(data) {
    return Row(
      children: [
        Expanded(
          child: _miniCard(
            label: StringConstants.receipts,
            value: data.receipts.toStringAsFixed(2),
            valueColor: AppColors.textPrimary,
          ),
        ),
        const Gap(10),
        Expanded(
          child: _miniCard(
            label: StringConstants.payments,
            value: data.payments.toStringAsFixed(2),
            valueColor: AppColors.textPrimary,
          ),
        ),
        const Gap(10),
        Expanded(
          child: _miniCard(
            label: StringConstants.crediters,
            value: '−68.17 L',
            valueColor: AppColors.emrColor,
          ),
        ),
      ],
    );
  }

  Widget _miniCard({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          KStyles().med(
            text: label,
            // size: 11,
            color: AppColors.textSecondary,
            textAlign: TextAlign.center,
          ),
          const Gap(6),
          KStyles().semiBold(text: value, size: 15, color: valueColor),
        ],
      ),
    );
  }

  Widget _emrCard(data) {
    final genderSlices = <DonutSlice>[];
    if (data.malePatients > 0) {
      genderSlices.add(DonutSlice(
        label: StringConstants.male,
        value: data.malePatients.toDouble(),
        color: AppColors.chartNavy,
      ));
    }
    if (data.femalePatients > 0) {
      genderSlices.add(DonutSlice(
        label: StringConstants.female,
        value: data.femalePatients.toDouble(),
        color: AppColors.chartTeal,
      ));
    }

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          SafeChartWrapper(
            tag: 'home_gender_donut',
            height: 100,
            builder: () => DonutChart(
              slices: genderSlices,
              centerText: data.currentPatients.toString(),
              centerSubText: StringConstants.patients,
              size: 90,
            ),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              children: [
                _genderRow(
                  AppColors.chartNavy,
                  StringConstants.male,
                  data.malePatients.toString(),
                ),
                const Gap(4),
                _genderRow(
                  AppColors.chartTeal,
                  StringConstants.female,
                  data.femalePatients.toString(),
                ),
                const Gap(10),
                Row(
                  children: [
                    _smallBadge('IP ${data.ipPatients}', AppColors.lmCoralBg,
                        AppColors.lmCoralText),
                    const Gap(8),
                    _smallBadge('OP ${data.opPatients}', AppColors.lmAmberBg,
                        AppColors.lmAmberText),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _genderRow(Color dotColor, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          LegendDot(color: dotColor, label: label),
          const Spacer(),
          KStyles().semiBold(
            text: value,
            size: 13,
            color: AppColors.textPrimary,
          ),
        ],
      ),
    );
  }

  Widget _smallBadge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: KStyles().med(text: text, size: 11, color: fg),
    );
  }

  Widget _storeCard(data) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    KStyles().med(
                      text: StringConstants.totalCollection,
                      // size: 11,
                      color: AppColors.textSecondary,
                    ),
                    const Gap(2),
                    KStyles().bold(
                      text: '₹${data.totalCollection.toStringAsFixed(0)}',
                      size: 22,
                      color: AppColors.textPrimary,
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 80,
                height: 36,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(6, (i) {
                    final heights = [16.0, 20.0, 24.0, 18.0, 28.0, 32.0];
                    final opacity = 0.4 + i * 0.1;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: Container(
                        width: 8,
                        height: heights[i],
                        decoration: BoxDecoration(
                          color:
                              AppColors.storeColor.withValues(alpha: opacity),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(
              color: AppColors.borderColor,
              height: 1,
              thickness: 0.5,
            ),
          ),
          Row(
            children: [
              _statTile('${data.storePurchase}', StringConstants.purchase),
              _statTile('${data.storeRevenue}', StringConstants.revenue),
              _statTile('${data.storeCollection}', StringConstants.collection),
              _statTile('${data.storePayments}', StringConstants.payments),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statTile(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          KStyles().semiBold(
            text: value,
            size: 14,
            color: AppColors.textPrimary,
          ),
          const Gap(2),
          KStyles().med(
            text: label,
            size: 12,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}
