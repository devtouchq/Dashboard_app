import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/section_theme.dart';
import '../../../core/constants/string_constants.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../data/models/dashboard_data.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../widgets/chart_card.dart';
import '../../widgets/charts/bar_chart_widget.dart';
import '../accounts/accounts_screen.dart';
import '../banquet/banquet_screen.dart';
import '../bar/bar_screen.dart';
import '../emr/emr_screen.dart';
import '../frontoffice/frontoffice_screen.dart';
import '../hr/hr_screen.dart';
import '../lab/lab_screen.dart';
import '../restaurant/restaurant_screen.dart';
import '../store/store_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const _tag = 'HomeScreen';
  static const _colorRevenue = Color(0xFF4ADE80);

  @override
  void initState() {
    super.initState();
    AppLogger.info(_tag, 'initState — start polling');
    WidgetsBinding.instance.addObserver(this);
    context.read<DashboardBloc>().add(
          const DashboardPollingStarted(interval: Duration(seconds: 5)),
        );
  }

  @override
  void dispose() {
    AppLogger.info(_tag, 'dispose — stop polling');
    WidgetsBinding.instance.removeObserver(this);
    try {
      context.read<DashboardBloc>().add(const DashboardPollingStopped());
    } catch (_) {}
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      context.read<DashboardBloc>().add(const DashboardPollingStopped());
    } else if (state == AppLifecycleState.resumed) {
      context.read<DashboardBloc>().add(
            const DashboardPollingStarted(interval: Duration(seconds: 5)),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = SectionTheme.home;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: theme.backgroundGradient[0],
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.backgroundGradient,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: BlocBuilder<DashboardBloc, DashboardState>(
            builder: (context, state) {
              return Column(
                children: [
                  _topBar(state),
                  Expanded(child: _body(context, state, theme)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, DashboardState state, SectionTheme theme) {
    if (state.data == null) {
      if (state.status == DashboardStatus.failure) {
        return _errorView(context, state);
      }
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }
    final data = state.data!;
    final currency = data.currency.defaultCurrency;
    return RefreshIndicator(
      onRefresh: () async {
        context.read<DashboardBloc>().add(const DashboardRefreshed());
        await Future.delayed(const Duration(milliseconds: 600));
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _welcomeHero(theme, currency),
          const Gap(20),
          _revenueChart(data.overview),
          const Gap(14),
          _summaryCard(data.overview, currency),
          const Gap(22),
          _departmentsHeader(),
          const Gap(12),
          ..._departmentTiles(context, data, currency),
        ],
      ),
    );
  }

  Widget _errorView(BuildContext context, DashboardState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: Colors.white54, size: 40),
            const Gap(12),
            KStyles().reg(
              text: 'Failed to load\n${state.errorMessage ?? ''}',
              size: 13,
              color: Colors.redAccent,
              textAlign: TextAlign.center,
            ),
            const Gap(16),
            ElevatedButton(
              onPressed: () => context
                  .read<DashboardBloc>()
                  .add(const DashboardLoadRequested()),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(DashboardState state) {
    final currency = state.data?.currency.defaultCurrency ?? 'INR';
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.menu,
                color: DashboardColors.textOnDark, size: 26),
          ),
          Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  KStyles().bold(
                    text: StringConstants.dashboard,
                    size: 18,
                    color: DashboardColors.textOnDark,
                  ),
                  const Gap(8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: KStyles().semiBold(
                      text: '${CurrencyUtils.symbol(currency)} $currency',
                      size: 10,
                      color: DashboardColors.textOnDarkSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined,
                color: DashboardColors.textOnDark, size: 24),
          ),
          IconButton(
            onPressed: () {
              
            },
            icon: const Icon(Icons.person_outline,
                color: DashboardColors.textOnDark, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _welcomeHero(SectionTheme theme, String currency) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KStyles().bold(
          text: 'Welcome back!',
          size: 26,
          color: DashboardColors.textOnDark,
        ),
        const Gap(4),
        KStyles().reg(
          text: '${theme.subtitle} · ${CurrencyUtils.name(currency)}',
          size: 12,
          color: DashboardColors.textOnDarkSecondary,
        ),
      ],
    );
  }

  Widget _revenueChart(OverviewData overview) {
    final sections = overview.sectionsDaily;
    return ChartCard(
      title: "Today's Revenue by Section",
      child: BarChartWidget(
        groups: sections
            .map((s) => BarGroup(label: s.name, values: [s.totalRevenue]))
            .toList(),
        barColors: const [_colorRevenue],
        barWidth: 9,
        height: 280,
        rotateLabels: -0.5,
      ),
    );
  }

  Widget _summaryCard(OverviewData overview, String currency) {
    final revenue = overview.totalRevenue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: DashboardColors.statCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DashboardColors.statCardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _colorRevenue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.trending_up, color: _colorRevenue, size: 24),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KStyles().reg(
                  text: 'Total Revenue Today (All Sections)',
                  size: 11,
                  color: DashboardColors.textOnDarkMuted,
                ),
                const Gap(4),
                KStyles().bold(
                  text: CurrencyUtils.format(revenue, currency),
                  size: 22,
                  color: DashboardColors.textOnDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _departmentsHeader() {
    return KStyles().semiBold(
      text: StringConstants.department,
      size: 14,
      color: DashboardColors.textOnDark,
    );
  }

  /// Section navigation — no more `data` param. Each section screen
  /// reads from DashboardBloc itself so it picks up live polling updates.
  List<Widget> _departmentTiles(
      BuildContext context, DashboardData d, String currency) {
    return [
      _DeptTile(
        icon: Icons.monitor_heart_outlined,
        iconColor: DashboardColors.iconBlue,
        title: 'EMR',
        subtitle: '${d.emr.totalPatients} Patients',
        revenue: CurrencyUtils.format(d.emr.totalRevenue, currency),
        onTap: () => _push(context, const EmrScreen()),
      ),
      _DeptTile(
        icon: Icons.attach_money,
        iconColor: DashboardColors.iconGreen,
        title: 'Accounts',
        subtitle: '${d.accounts.totalReceipts.toInt()} Receipts',
        revenue: CurrencyUtils.format(d.accounts.totalRevenue, currency),
        onTap: () => _push(context, const AccountsScreen()),
      ),
      _DeptTile(
        icon: Icons.inventory_2_outlined,
        iconColor: DashboardColors.iconPurple,
        title: 'Store',
        subtitle: '${d.store.purchase.toInt()}  purchase',
        revenue: CurrencyUtils.format(d.store.totalRevenue, currency),
        onTap: () => _push(context, const StoreScreen()),
      ),
      _DeptTile(
        icon: Icons.local_bar_outlined,
        iconColor: DashboardColors.iconOrange,
        title: 'Bar',
        subtitle: '${d.bar.totalCollection.toInt()}  collection',
        revenue: CurrencyUtils.format(d.bar.totalRevenue, currency),
        onTap: () => _push(context, const BarScreen()),
      ),
      _DeptTile(
        icon: Icons.science_outlined,
        iconColor: DashboardColors.iconPurple,
        title: 'Lab',
        subtitle: '${d.lab.testCount.toInt()} Tests',
        revenue: CurrencyUtils.format(d.lab.totalRevenue, currency),
        onTap: () => _push(context, const LabScreen()),
      ),
      _DeptTile(
        icon: Icons.celebration_outlined,
        iconColor: DashboardColors.iconPink,
        title: 'Banquet',
        subtitle: '${d.banquet.totalFunctions.toInt()} Events',
        revenue: CurrencyUtils.format(d.banquet.totalRevenue, currency),
        onTap: () => _push(context, const BanquetScreen()),
      ),
      _DeptTile(
        icon: Icons.restaurant_outlined,
        iconColor: DashboardColors.iconAmber,
        title: 'Restaurant',
        subtitle: '${d.restaurant.totalPax.toInt()} Customers',
        revenue: CurrencyUtils.format(d.restaurant.totalRevenue, currency),
        onTap: () => _push(context, const RestaurantScreen()),
      ),
      _DeptTile(
        icon: Icons.groups_outlined,
        iconColor: DashboardColors.iconBlue,
        title: 'HR',
        subtitle: '${d.hr.totalPresent} Present',
        revenue: CurrencyUtils.format(d.hr.totalRevenue, currency),
        onTap: () => _push(context, const HrScreen()),
      ),
      _DeptTile(
        icon: Icons.meeting_room_outlined,
        iconColor: DashboardColors.iconTeal,
        title: 'Frontoffice',
        subtitle: '${d.frontoffice.totalCheckIn.toInt()} Check-ins',
        revenue: CurrencyUtils.format(d.frontoffice.totalRevenue, currency),
        onTap: () => _push(context, const FrontofficeScreen()),
      ),
    ];
  }

  /// IMPORTANT: forward the DashboardBloc to the new route so the
  /// section screen can watch it. Without this, the section screen
  /// can't find the provider above the route.
  void _push(BuildContext c, Widget screen) {
    final bloc = c.read<DashboardBloc>();
    Navigator.push(
      c,
      MaterialPageRoute(
        builder: (_) => BlocProvider<DashboardBloc>.value(
          value: bloc,
          child: screen,
        ),
      ),
    );
  }
}

class _DeptTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String revenue;
  final VoidCallback onTap;

  const _DeptTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.revenue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: DashboardColors.statCardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: DashboardColors.statCardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: Colors.white),
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
                      color: DashboardColors.textOnDark,
                    ),
                    const Gap(2),
                    KStyles().reg(
                      text: subtitle,
                      size: 11,
                      color: DashboardColors.textOnDarkMuted,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  KStyles().bold(
                    text: revenue,
                    size: 14,
                    color: DashboardColors.textOnDark,
                  ),
                  KStyles().reg(
                    text: StringConstants.revenueLabel,
                    size: 10,
                    color: DashboardColors.textOnDarkMuted,
                  ),
                ],
              ),
              const Gap(6),
              const Icon(Icons.chevron_right,
                  color: DashboardColors.textOnDarkMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
