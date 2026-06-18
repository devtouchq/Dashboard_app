import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/section_theme.dart';
import '../../../core/constants/string_constants.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/services/notification_center_service.dart';
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

/// Per-section visual config — icon, color, and the screen to open on tap.
/// Keyed by the section `Name` returned by the API.
class _SectionVisual {
  final IconData icon;
  final Color color;
  final Widget Function() screen;

  const _SectionVisual(this.icon, this.color, this.screen);
}

const Map<String, _SectionVisual> _sectionVisuals = {
  'EMR': _SectionVisual(
    Icons.monitor_heart_outlined,
    DashboardColors.iconBlue,
    EmrScreen.new,
  ),
  'Accounts': _SectionVisual(
    Icons.attach_money,
    DashboardColors.iconGreen,
    AccountsScreen.new,
  ),
  'Store': _SectionVisual(
    Icons.inventory_2_outlined,
    DashboardColors.iconPurple,
    StoreScreen.new,
  ),
  'Bar': _SectionVisual(
    Icons.local_bar_outlined,
    DashboardColors.iconOrange,
    BarScreen.new,
  ),
  'Lab': _SectionVisual(
    Icons.science_outlined,
    DashboardColors.iconPurple,
    LabScreen.new,
  ),
  'Banquet': _SectionVisual(
    Icons.celebration_outlined,
    DashboardColors.iconPink,
    BanquetScreen.new,
  ),
  'Restaurant': _SectionVisual(
    Icons.restaurant_outlined,
    DashboardColors.iconAmber,
    RestaurantScreen.new,
  ),
  'HR': _SectionVisual(
    Icons.groups_outlined,
    DashboardColors.iconBlue,
    HrScreen.new,
  ),
  'Frontoffice': _SectionVisual(
    Icons.meeting_room_outlined,
    DashboardColors.iconTeal,
    FrontofficeScreen.new,
  ),
};

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const _tag = 'HomeScreen';
  static const _colorRevenue = Color(0xFF4ADE80);

  late final StreamSubscription<int> _unreadSub;
  int _unreadCount = NotificationCenterService().unreadCount;

  @override
  void initState() {
    super.initState();
    AppLogger.info(_tag, 'initState — start polling');
    WidgetsBinding.instance.addObserver(this);

    _unreadSub = NotificationCenterService().stream.listen((count) {
      if (mounted) setState(() => _unreadCount = count);
    });

    context.read<DashboardBloc>().add(
          const DashboardPollingStarted(interval: Duration(seconds: 5)),
        );
  }

  @override
  void dispose() {
    AppLogger.info(_tag, 'dispose — stop polling');
    _unreadSub.cancel();
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
      NotificationCenterService().init().then((_) {
        if (mounted) {
          setState(
              () => _unreadCount = NotificationCenterService().unreadCount);
        }
      });
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
          child: BlocListener<AuthBloc, AuthState>(
            listenWhen: (a, b) =>
                a.status != b.status && b.status == AuthStatus.loggedOut,
            listener: (context, _) {
              AppLogger.info(_tag, 'auth → loggedOut, going to BaseUrl');
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const BaseUrlScreen()),
                (route) => false,
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

    // Active tiles: count > 0 OR revenue > 0.
    final activeTiles = data.overview.sectionTiles
        .where((t) => t.count != 0 || t.revenue != 0)
        .toList();

    final allEmpty = activeTiles.isEmpty;

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
          if (allEmpty) ...[
            _noActivityState(),
          ] else ...[
            _revenueChart(data.overview.sectionsDaily, activeTiles),
            const Gap(14),
            _summaryCard(data.overview, currency),
            const Gap(22),
            _departmentsHeader(),
            const Gap(12),
            ..._departmentTiles(context, activeTiles, currency),
          ],
        ],
      ),
    );
  }

  // ─── Department tiles — driven entirely by SectionTiles ──────────
  List<Widget> _departmentTiles(
      BuildContext context, List<SectionTile> tiles, String currency) {
    return tiles.map((tile) {
      final visual = _sectionVisuals[tile.name];
      if (visual == null) {
        // Unknown section name — render a neutral tile.
        return _DeptTile(
          icon: Icons.dashboard_outlined,
          iconColor: Colors.grey,
          title: tile.name,
          subtitle: '${_fmtCount(tile.count)} ${tile.countLabel}',
          revenue: CurrencyUtils.format(tile.revenue, currency),
          onTap: () {},
        );
      }
      return _DeptTile(
        icon: visual.icon,
        iconColor: visual.color,
        title: tile.name,
        subtitle: '${_fmtCount(tile.count)} ${tile.countLabel}',
        revenue: CurrencyUtils.format(tile.revenue, currency),
        onTap: () => _push(context, visual.screen()),
      );
    }).toList();
  }

  /// Drop trailing .0 on whole numbers — "1" not "1.0".
  String _fmtCount(double v) {
    if (v == v.truncate()) return v.toInt().toString();
    return v.toString();
  }

  Widget _noActivityState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 16),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: const Icon(Icons.beach_access_outlined,
                color: Colors.white54, size: 48),
          ),
          const Gap(20),
          KStyles().bold(
            text: 'No activity today',
            size: 18,
            color: DashboardColors.textOnDark,
          ),
          const Gap(8),
          KStyles().reg(
            text:
                "When your branches start logging activity, it'll show up here.",
            size: 12,
            color: DashboardColors.textOnDarkMuted,
            textAlign: TextAlign.center,
          ),
          const Gap(20),
          TextButton.icon(
            onPressed: () {
              context.read<DashboardBloc>().add(const DashboardRefreshed());
            },
            icon: const Icon(Icons.refresh,
                color: DashboardColors.textOnDarkSecondary, size: 16),
            label: KStyles().semiBold(
              text: 'Check again',
              size: 12,
              color: DashboardColors.textOnDarkSecondary,
            ),
          ),
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
              text: 'Failed to load\n Close the App and try again.',
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
          _bellWithBadge(),
          _profileMenu(context),
        ],
      ),
    );
  }

  Widget _bellWithBadge() {
    final hasUnread = _unreadCount > 0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: () async {
            await NotificationCenterService().markAllRead();
          },
          icon: const Icon(Icons.notifications_outlined,
              color: DashboardColors.textOnDark, size: 24),
          tooltip: hasUnread ? '$_unreadCount unread' : 'Notifications',
        ),
        if (hasUnread)
          Positioned(
            top: 6,
            right: 4,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: _unreadCount > 9 ? 4 : 5,
                vertical: 2,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: SectionTheme.home.backgroundGradient[0],
                  width: 1.5,
                ),
              ),
              child: Center(
                child: KStyles().bold(
                  text: _unreadCount > 9 ? '9+' : '$_unreadCount',
                  size: 9,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

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
        if (value == 'logout') _confirmLogout(context);
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
    final shouldLogout = await showDialog<bool>(
      context: context,
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

  /// Show only the SectionsDaily entries whose section is also in the
  /// active tiles. The daily list uses 'HrManager' and 'FrontOffice'
  /// while tiles use 'HR' and 'Frontoffice', so we normalize here.
  Widget _revenueChart(
      List<SectionDaily> daily, List<SectionTile> activeTiles) {
    String norm(String n) {
      if (n == 'HrManager') return 'HR';
      if (n == 'FrontOffice') return 'Frontoffice';
      return n;
    }

    final activeNames = activeTiles.map((t) => t.name).toSet();
    final filtered =
        daily.where((s) => activeNames.contains(norm(s.name))).toList();

    return ChartCard(
      title: "Today's Revenue by Section",
      child: BarChartWidget(
        groups: filtered
            .map((s) => BarGroup(label: s.name, values: [s.totalRevenue]))
            .toList(),
        barColors: const [_colorRevenue],
        barWidth: 9,
        height: 280,
        rotateLabels: -0.5,
      ),
    );
  }

  /// Summary = sum of TotalRevenue across all SectionsDaily entries.
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
