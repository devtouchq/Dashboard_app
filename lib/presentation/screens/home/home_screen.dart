import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/section_theme.dart';
import '../../../core/constants/string_constants.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../data/models/dashboard_data.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../widgets/chart_card.dart';
import '../../widgets/charts/bar_chart_widget.dart';
import '../accounts/accounts_screen.dart';
import '../banquet/banquet_screen.dart';
import '../bar/bar_screen.dart';
import '../base_url/base_url_screen.dart';
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
    const theme = SectionTheme.home;
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
          // Listen for AuthBloc.loggedOut and navigate to BaseUrl screen.
          child: BlocListener<AuthBloc, AuthState>(
            listenWhen: (a, b) =>
                a.status != b.status && b.status == AuthStatus.loggedOut,
            listener: (context, _) {
              AppLogger.info(_tag, 'auth → loggedOut, going to BaseUrl');
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const BaseUrlScreen()),
                (route) => false, // wipe the entire navigation stack
              );
            },
            child: BlocBuilder<DashboardBloc, DashboardState>(
              builder: (context, state) {
                return Column(
                  children: [
                    _topBar(context, state),
                    Expanded(child: _body(context, state, theme)),
                  ],
                );
              },
            ),
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
              text:
                  'Failed to load\nPlease check your connection \n Close and Re-Open the app',
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

  Widget _topBar(BuildContext context, DashboardState state) {
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
          _profileMenu(context),
        ],
      ),
    );
  }

  /// Person icon → popup menu → Logout option.
  /// Selecting Logout opens a confirmation AlertDialog.
  Widget _profileMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.person_outline,
          color: DashboardColors.textOnDark, size: 24),
      tooltip: 'Profile',
      color: const Color(0xFF1F2937),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      onSelected: (value) {
        if (value == 'logout') {
          _confirmLogout(context);
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              const Icon(Icons.logout_rounded,
                  color: Color(0xFFFF8A8A), size: 18),
              const Gap(10),
              KStyles().semiBold(
                text: 'Logout',
                size: 13,
                color: DashboardColors.textOnDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    AppLogger.info(_tag, 'logout tap — showing confirm dialog');
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1F2937),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8A8A).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.logout_rounded,
                    color: Color(0xFFFF8A8A), size: 20),
              ),
              const Gap(12),
              KStyles().bold(
                text: 'Logout?',
                size: 16,
                color: DashboardColors.textOnDark,
              ),
            ],
          ),
          content: KStyles().reg(
            text:
                'Are you sure you want to logout? You will need to sign in again.',
            size: 13,
            color: DashboardColors.textOnDarkSecondary,
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: DashboardColors.textOnDarkSecondary,
              ),
              child: KStyles().semiBold(
                text: 'Cancel',
                size: 13,
                color: DashboardColors.textOnDarkSecondary,
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8A8A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: KStyles().semiBold(
                text: 'Logout',
                size: 13,
                color: Colors.white,
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true && context.mounted) {
      AppLogger.info(_tag, 'confirmed — dispatching LogoutRequested');
      // Stop polling so we don't fire dashboard requests during logout.
      context.read<DashboardBloc>().add(const DashboardPollingStopped());
      context.read<AuthBloc>().add(const LogoutRequested());
    }
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
