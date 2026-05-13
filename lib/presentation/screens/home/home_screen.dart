import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/section_theme.dart';
import '../../../core/constants/string_constants.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/di/injector.dart';
import '../../../core/utils/app_logger.dart';
import '../../blocs/accounts/accounts_bloc.dart';
import '../../blocs/banquet/banquet_bloc.dart';
import '../../blocs/bar/bar_bloc.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/emr/emr_bloc.dart';
import '../../blocs/frontoffice/frontoffice_bloc.dart';
import '../../blocs/hr/hr_bloc.dart';
import '../../blocs/lab/lab_bloc.dart';
import '../../blocs/restaurant/restaurant_bloc.dart';
import '../../blocs/store/store_bloc.dart';
import '../../widgets/chart_card.dart';
import '../../widgets/charts/multi_line_chart.dart';
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
          child: BlocConsumer<DashboardBloc, DashboardState>(
            listener: (context, state) {
              AppLogger.info(_tag, 'state changed: ${state.status}');
              if (state.status == DashboardStatus.failure) {
                AppLogger.error(_tag,
                    'Dashboard load failed: ${state.errorMessage}');
              }
            },
            builder: (context, state) {
              return Column(
                children: [
                  _topBar(),
                  Expanded(
                    child: _body(context, state, theme),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, DashboardState state, SectionTheme theme) {
    if (state.status == DashboardStatus.loading || state.data == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    if (state.status == DashboardStatus.failure) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: KStyles().reg(
            text: 'Failed to load: ${state.errorMessage ?? ''}',
            size: 14,
            color: Colors.redAccent,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        AppLogger.info(_tag, 'pull-to-refresh');
        context.read<DashboardBloc>().add(const DashboardRefreshed());
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _welcomeHero(theme),
          const Gap(20),
          _combinedRevenueChart(),
          const Gap(20),
          _departmentsHeader(),
          const Gap(12),
          ..._departmentTiles(context),
        ],
      ),
    );
  }

  Widget _topBar() {
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
              child: KStyles().bold(
                text: StringConstants.dashboard,
                size: 18,
                color: DashboardColors.textOnDark,
              ),
            ),
          ),
          Stack(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_outlined,
                    color: DashboardColors.textOnDark, size: 24),
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.person_outline,
                color: DashboardColors.textOnDark, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _welcomeHero(SectionTheme theme) {
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
          text: theme.subtitle,
          size: 13,
          color: DashboardColors.textOnDarkSecondary,
        ),
      ],
    );
  }

  Widget _combinedRevenueChart() {
    // Sample 6-month combined revenue data. Move to a model field later
    // once the dashboard repository returns monthly aggregates.
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];

    const series = [
      LineSeries(
        name: 'EMR',
        color: Color(0xFF4A8DFF),
        values: [2300, 2900, 2700, 3200, 3700, 3900],
      ),
      LineSeries(
        name: 'Accounts',
        color: Color(0xFF2DD4A0),
        values: [4000, 1500, 10000, 3900, 4800, 3900],
      ),
      LineSeries(
        name: 'Store',
        color: Color(0xFFB57BFF),
        values: [2200, 1900, 2200, 2300, 2000, 2500],
      ),
      LineSeries(
        name: 'Bar',
        color: Color(0xFFFF8A3D),
        values: [1900, 2100, 2200, 2300, 2500, 2700],
      ),
      LineSeries(
        name: 'Lab',
        color: Color(0xFFA78BFA),
        values: [2400, 2100, 2400, 2300, 2400, 2600],
      ),
    ];

    return const ChartCard(
      title: 'Combined Revenue (Last 6 Months)',
      child: MultiLineChart(
        series: series,
        xLabels: months,
        height: 260,
        yMax: 10500,
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

  List<Widget> _departmentTiles(BuildContext context) {
    return [
      _DeptTile(
        icon: Icons.monitor_heart_outlined,
        iconColor: DashboardColors.iconBlue,
        title: StringConstants.emr,
        subtitle: '248 Patients',
        revenue: '\$12,450',
        onTap: () => _openEmr(context),
      ),
      _DeptTile(
        icon: Icons.attach_money,
        iconColor: DashboardColors.iconGreen,
        title: StringConstants.accounts,
        subtitle: '156 Invoices',
        revenue: '\$45,230',
        onTap: () => _openAccounts(context),
      ),
      _DeptTile(
        icon: Icons.inventory_2_outlined,
        iconColor: DashboardColors.iconPurple,
        title: StringConstants.store,
        subtitle: '1,234 Items',
        revenue: '\$23,890',
        onTap: () => _openStore(context),
      ),
      _DeptTile(
        icon: Icons.local_bar_outlined,
        iconColor: DashboardColors.iconOrange,
        title: StringConstants.bar,
        subtitle: '89 Products',
        revenue: '\$8,650',
        onTap: () => _openBar(context),
      ),
      _DeptTile(
        icon: Icons.science_outlined,
        iconColor: DashboardColors.iconPurple,
        title: StringConstants.lab,
        subtitle: '156 Tests',
        revenue: '\$18,340',
        onTap: () => _openLab(context),
      ),
      _DeptTile(
        icon: Icons.celebration_outlined,
        iconColor: DashboardColors.iconPink,
        title: StringConstants.banquet,
        subtitle: '115 Events',
        revenue: '\$33,000',
        onTap: () => _openBanquet(context),
      ),
      _DeptTile(
        icon: Icons.restaurant_outlined,
        iconColor: DashboardColors.iconAmber,
        title: StringConstants.restaurant,
        subtitle: '85 Orders',
        revenue: '\$5,800',
        onTap: () => _openRestaurant(context),
      ),
      _DeptTile(
        icon: Icons.groups_outlined,
        iconColor: DashboardColors.iconBlue,
        title: StringConstants.hr,
        subtitle: '342 Staff',
        revenue: '\$24,500',
        onTap: () => _openHr(context),
      ),
      _DeptTile(
        icon: Icons.meeting_room_outlined,
        iconColor: DashboardColors.iconTeal,
        title: StringConstants.frontofficeFull,
        subtitle: '156 Check-ins',
        revenue: '\$8,200',
        onTap: () => _openFrontoffice(context),
      ),
    ];
  }

  // ─────────────────────────────────────────────────────────
  // Section openers — each provides its own bloc from auto_injector
  // and dispatches the initial load event.
  // ─────────────────────────────────────────────────────────

  void _openEmr(BuildContext c) {
    AppLogger.info(_tag, 'open EMR');
    Navigator.push(c, MaterialPageRoute(builder: (_) {
      return BlocProvider(
        create: (_) => autoInjector.get<EmrBloc>()..add(const EmrLoadRequested()),
        child: const EmrScreen(),
      );
    }));
  }

  void _openAccounts(BuildContext c) {
    AppLogger.info(_tag, 'open Accounts');
    Navigator.push(c, MaterialPageRoute(builder: (_) {
      return BlocProvider(
        create: (_) =>
            autoInjector.get<AccountsBloc>()..add(const AccountsLoadRequested()),
        child: const AccountsScreen(),
      );
    }));
  }

  void _openStore(BuildContext c) {
    AppLogger.info(_tag, 'open Store');
    Navigator.push(c, MaterialPageRoute(builder: (_) {
      return BlocProvider(
        create: (_) =>
            autoInjector.get<StoreBloc>()..add(const StoreLoadRequested()),
        child: const StoreScreen(),
      );
    }));
  }

  void _openBar(BuildContext c) {
    AppLogger.info(_tag, 'open Bar');
    Navigator.push(c, MaterialPageRoute(builder: (_) {
      return BlocProvider(
        create: (_) => autoInjector.get<BarBloc>()..add(const BarLoadRequested()),
        child: const BarScreen(),
      );
    }));
  }

  void _openLab(BuildContext c) {
    AppLogger.info(_tag, 'open Lab');
    Navigator.push(c, MaterialPageRoute(builder: (_) {
      return BlocProvider(
        create: (_) => autoInjector.get<LabBloc>()..add(const LabLoadRequested()),
        child: const LabScreen(),
      );
    }));
  }

  void _openBanquet(BuildContext c) {
    AppLogger.info(_tag, 'open Banquet');
    Navigator.push(c, MaterialPageRoute(builder: (_) {
      return BlocProvider(
        create: (_) =>
            autoInjector.get<BanquetBloc>()..add(const BanquetLoadRequested()),
        child: const BanquetScreen(),
      );
    }));
  }

  void _openRestaurant(BuildContext c) {
    AppLogger.info(_tag, 'open Restaurant');
    Navigator.push(c, MaterialPageRoute(builder: (_) {
      return BlocProvider(
        create: (_) => autoInjector.get<RestaurantBloc>()
          ..add(const RestaurantLoadRequested()),
        child: const RestaurantScreen(),
      );
    }));
  }

  void _openHr(BuildContext c) {
    AppLogger.info(_tag, 'open HR');
    Navigator.push(c, MaterialPageRoute(builder: (_) {
      return BlocProvider(
        create: (_) => autoInjector.get<HrBloc>()..add(const HrLoadRequested()),
        child: const HrScreen(),
      );
    }));
  }

  void _openFrontoffice(BuildContext c) {
    AppLogger.info(_tag, 'open Frontoffice');
    Navigator.push(c, MaterialPageRoute(builder: (_) {
      return BlocProvider(
        create: (_) => autoInjector.get<FrontofficeBloc>()
          ..add(const FrontofficeLoadRequested()),
        child: const FrontofficeScreen(),
      );
    }));
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
