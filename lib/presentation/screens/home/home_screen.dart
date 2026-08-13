import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/section_theme.dart';
import '../../../core/constants/string_constants.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/di/local_storage_service.dart';
import '../../../core/di/injector.dart';
import '../../../core/services/notification_center_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../data/models/auth_data.dart';
import '../../../data/models/dashboard_data.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../widgets/chart_card.dart';
import '../../widgets/charts/donut.dart';
import '../accounts/accounts_screen.dart';
import '../banquet/banquet_screen.dart';
import '../bar/bar_screen.dart';
import '../base_url/base_url_screen.dart';
import '../chat/chat_screen.dart';
import '../emr/emr_screen.dart';
import '../frontoffice/frontoffice_screen.dart';
import '../hr/hr_screen.dart';
import '../lab/lab_screen.dart';
import '../restaurant/restaurant_screen.dart';
import '../store/store_screen.dart';

class _SectionVisual {
  final IconData icon;
  final Color color;
  final Widget Function() screen;

  const _SectionVisual(this.icon, this.color, this.screen);
}

const Map<String, _SectionVisual> _sectionVisuals = {
  'EMR': _SectionVisual(
    Icons.monitor_heart_outlined,
    DashboardColors.iconBlue, // blue — matches EMR section
    EmrScreen.new,
  ),
  'Accounts': _SectionVisual(
    Icons.attach_money,
    DashboardColors.iconGreen, // emerald — matches Accounts section
    AccountsScreen.new,
  ),
  'Store': _SectionVisual(
    Icons.inventory_2_outlined,
    DashboardColors.iconIndigo, // WAS iconPurple → now indigo
    StoreScreen.new,
  ),
  'Bar': _SectionVisual(
    Icons.local_bar_outlined,
    DashboardColors.iconOrange, // orange — matches Bar section
    BarScreen.new,
  ),
  'Lab': _SectionVisual(
    Icons.science_outlined,
    DashboardColors.iconCyan, // WAS iconPurple → now cyan
    LabScreen.new,
  ),
  'Banquet': _SectionVisual(
    Icons.celebration_outlined,
    DashboardColors.iconPink, // pink — matches Banquet section
    BanquetScreen.new,
  ),
  'Restaurant': _SectionVisual(
    Icons.restaurant_outlined,
    DashboardColors.iconAmber, // amber — matches Restaurant section
    RestaurantScreen.new,
  ),
  'HR': _SectionVisual(
    Icons.groups_outlined,
    DashboardColors.iconTeal, // WAS iconBlue → now teal (matches HR)
    HrScreen.new,
  ),
  'Frontoffice': _SectionVisual(
    Icons.meeting_room_outlined,
    DashboardColors.iconLime, // WAS iconTeal → now lime (matches Frontoffice)
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
  static const _colorNegative = Color(0xFFEF4444);

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  late final StreamSubscription<int> _unreadSub;
  int _unreadCount = NotificationCenterService().unreadCount;

  String? _selectedBranchValue;

  @override
  void initState() {
    super.initState();
    AppLogger.info(_tag, 'initState — start polling');
    WidgetsBinding.instance.addObserver(this);

    final storage = autoInjector.get<LocalStorageService>();
    _selectedBranchValue = storage.selectedBranch;

    _unreadSub = NotificationCenterService().stream.listen((count) {
      if (mounted) setState(() => _unreadCount = count);
    });

    context.read<DashboardBloc>().add(
          const DashboardPollingStarted(interval: Duration(seconds: 30)),
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
            const DashboardPollingStarted(interval: Duration(seconds: 30)),
          );
    }
  }

  Future<void> _onBranchChanged(Branch newBranch) async {
    AppLogger.info(_tag, 'branch switched → ${newBranch.text}');

    final storage = autoInjector.get<LocalStorageService>();
    await storage.setSelectedBranch(newBranch.value);

    if (!mounted) return;
    setState(() => _selectedBranchValue = newBranch.value);

    final bloc = context.read<DashboardBloc>();
    bloc.add(const DashboardPollingStopped());
    bloc.add(const DashboardLoadRequested());
    bloc.add(const DashboardPollingStarted(interval: Duration(seconds: 30)));

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    const theme = SectionTheme.home;
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(context),
      floatingActionButton: _chatFab(context),
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

  //*------------Chat floating action button--------
  Widget _chatFab(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ChatScreen()),
        );
      },
      backgroundColor: SectionTheme.home.accent,
      foregroundColor: Colors.white,
      elevation: 6,
      icon: const Icon(Icons.auto_awesome, size: 20),
      label: KStyles().semiBold(
        text: 'Ask AI',
        size: 13,
        color: Colors.white,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
//  Drawer with branch switcher
// ─────────────────────────────────────────────────────────────
  Widget _buildDrawer(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (a, b) => a.branches != b.branches,
      builder: (context, authState) {
        final branches = authState.branches;

        // Fallback: if drawer opens with no branches (edge cases like
        // bootstrap not firing, or a state reset), fire AuthBootstrapped
        // to force a fresh read from LocalStorageService.
        //
        // Fires post-frame so we don't dispatch during a build.
        if (branches.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              AppLogger.info(
                  _tag, 'drawer opened with empty branches — bootstrapping');
              context.read<AuthBloc>().add(const AuthBootstrapped());
            }
          });
        }

        return Drawer(
          backgroundColor: const Color(0xFF1F2937),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: SectionTheme.home.backgroundGradient[0]
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: const Icon(Icons.dashboard_outlined,
                            color: Colors.white, size: 22),
                      ),
                      const Gap(12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            KStyles().bold(
                              text: 'Ayurlive Dashboard',
                              size: 14,
                              color: DashboardColors.textOnDark,
                            ),
                            const Gap(2),
                            KStyles().reg(
                              text: 'Switch branch',
                              size: 11,
                              color: DashboardColors.textOnDarkMuted,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  color: Colors.white.withValues(alpha: 0.08),
                  height: 1,
                ),
                const Gap(12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: KStyles().semiBold(
                    text: 'BRANCH',
                    size: 10,
                    color: DashboardColors.textOnDarkMuted,
                  ),
                ),
                const Gap(8),
                if (branches.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white54,
                              ),
                            ),
                            const Gap(10),
                            KStyles().reg(
                              text: 'Loading branches...',
                              size: 12,
                              color: DashboardColors.textOnDarkMuted,
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: branches.length,
                      itemBuilder: (_, i) {
                        final b = branches[i];
                        final isSelected = b.value == _selectedBranchValue;
                        return _BranchTile(
                          branch: b,
                          isSelected: isSelected,
                          onTap: isSelected ? null : () => _onBranchChanged(b),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _body(BuildContext context, DashboardState state, SectionTheme theme) {
    // Loading — spinner regardless of stale data.
    if (state.status == DashboardStatus.loading || state.data == null) {
      if (state.status == DashboardStatus.failure) {
        return _errorView(context, state);
      }
      return _loadingView();
    }

    final data = state.data!;
    final currency = data.currency.defaultCurrency;

    // A tile is "active" if EITHER:
//   1. Its Overview.SectionTile has non-zero count/revenue, OR
//   2. The section's OWN detail object has any non-zero value.
//
// This catches cases like Accounts having TotalCheckIn=192 and
// TotalRevenueAllModules=311 even though SectionTile.revenue=0.
// Bar with everything = 0 is correctly hidden.
    final activeTiles = data.overview.sectionTiles.where((t) {
      final tileActive = t.count != 0 || t.revenue != 0;
      final sectionActive = data.hasActivityFor(t.name);
      return tileActive || sectionActive;
    }).toList();

    // Chart data: any daily section with non-zero revenue (positive OR negative).
    final dailyWithData =
        data.overview.sectionsDaily.where((s) => s.totalRevenue != 0).toList();

    // Summary: overall total (positive or negative — any non-zero counts).
    final totalRevenue = data.overview.totalRevenue;
    final hasSummaryData = totalRevenue != 0;

    // "Truly empty" means every source is empty. Only then show the
    // welcoming empty-state screen.
    final hasAnyData =
        activeTiles.isNotEmpty || dailyWithData.isNotEmpty || hasSummaryData;

    if (!hasAnyData) {
      return RefreshIndicator(
        onRefresh: () async {
          context.read<DashboardBloc>().add(const DashboardRefreshed());
          await Future.delayed(const Duration(milliseconds: 600));
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            _welcomeHero(theme, currency),
            const Gap(20),
            _noActivityState(),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<DashboardBloc>().add(const DashboardRefreshed());
        await Future.delayed(const Duration(milliseconds: 600));
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          _welcomeHero(theme, currency),
          const Gap(20),

          // Chart — only if we have daily data with non-zero revenue.
          if (dailyWithData.isNotEmpty) ...[
            _revenueChart(dailyWithData),
            const Gap(14),
          ],

          // Summary — always show if we have any data at all.
          _summaryCard(totalRevenue, currency),

          // Departments header + tiles — only if we have active tiles.
          if (activeTiles.isNotEmpty) ...[
            const Gap(22),
            _departmentsHeader(),
            const Gap(12),
            ..._departmentTiles(context, activeTiles, currency),
          ],
        ],
      ),
    );
  }

  Widget _loadingView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const Gap(14),
          KStyles().reg(
            text: 'Loading branch data...',
            size: 12,
            color: DashboardColors.textOnDarkMuted,
          ),
        ],
      ),
    );
  }

  List<Widget> _departmentTiles(
      BuildContext context, List<SectionTile> tiles, String currency) {
    return tiles.map((tile) {
      final visual = _sectionVisuals[tile.name];
      final revenue = tile.revenue;
// HR is attendance-focused, not revenue-generating. Hiding the
      // revenue column on the HR tile keeps the numbers meaningful
      // (Present-only) and avoids showing a redundant "₹0.00".
      final showRevenue = tile.name != 'HR';
      if (visual == null) {
        return _DeptTile(
          icon: Icons.dashboard_outlined,
          iconColor: Colors.grey,
          title: tile.name,
          subtitle: '${_fmtCount(tile.count)} ${tile.countLabel}',
          revenue: revenue,
          currency: currency,
          showRevenue: showRevenue,
          onTap: () {},
        );
      }
      return _DeptTile(
        icon: visual.icon,
        iconColor: visual.color,
        title: tile.name,
        subtitle: '${_fmtCount(tile.count)} ${tile.countLabel}',
        revenue: revenue,
        currency: currency,
        showRevenue: showRevenue,
        onTap: () => _push(context, visual.screen()),
      );
    }).toList();
  }

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
    final rawError = state.errorMessage ?? '';
    final firstLine = rawError.split('\n').first.trim();
    final display = firstLine.length > 200
        ? '${firstLine.substring(0, 200)}...'
        : firstLine;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, color: Colors.white54, size: 40),
          const Gap(12),
          KStyles().bold(
            text: 'Failed to load',
            size: 15,
            color: Colors.redAccent,
          ),
          const Gap(8),
          KStyles().reg(
            text: display,
            size: 12,
            color: DashboardColors.textOnDarkMuted,
            textAlign: TextAlign.center,
          ),
          const Gap(20),
          ElevatedButton.icon(
            onPressed: () => context
                .read<DashboardBloc>()
                .add(const DashboardLoadRequested()),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
          ),
        ],
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
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            icon: const Icon(Icons.menu,
                color: DashboardColors.textOnDark, size: 26),
            tooltip: 'Switch branch',
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
        //display the selected branch name in the welcome hero
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: KStyles().reg(
            text: 'Branch: ${_selectedBranchValue ?? 'N/A'}',
            size: 14,
            color: DashboardColors.textOnDarkSecondary,
          ),
        ),
        const Gap(2),

        KStyles().reg(
          text: '${theme.subtitle} · ${CurrencyUtils.name(currency)}',
          size: 12,
          color: DashboardColors.textOnDarkSecondary,
        ),
      ],
    );
  }

  /// Chart — expects a pre-filtered list of SectionDaily entries that
  /// have non-zero revenue. Doesn't depend on `activeTiles` anymore, so
  /// it still shows when the server returns daily data but no tile data
  /// (e.g. for the ALL aggregation).
  // Widget _revenueChart(List<SectionDaily> daily) {
  //   return ChartCard(
  //     title: "Today's Revenue by Section",
  //     child: BarChartWidget(
  //       groups: daily
  //           .map((s) => BarGroup(label: s.name, values: [s.totalRevenue]))
  //           .toList(),
  //       barColors: const [_colorRevenue],
  //       negativeColor: _colorNegative,
  //       barWidth: 9,
  //       height: 300,
  //       rotateLabels: -0.5,
  //     ),
  //   );
  // }
  //todo
  /// Donut chart of positive revenue by section, with a separate list
  /// below showing any negative (loss) sections. Uses each section's
  /// brand color from `_sectionVisuals` so the colors match the tiles.
  Widget _revenueChart(List<SectionDaily> daily) {
    String norm(String n) {
      if (n == 'HrManager') return 'HR';
      if (n == 'FrontOffice') return 'Frontoffice';
      return n;
    }

    // Build slices using each section's brand color. Fallback color
    // used for sections without an entry in _sectionVisuals.
    const fallbackColors = [
      Color(0xFF4ADE80),
      Color(0xFF60A5FA),
      Color(0xFFF59E0B),
      Color(0xFFA78BFA),
      Color(0xFFEC4899),
      Color(0xFF14B8A6),
    ];

    final slices = <DonutSlice>[];
    for (var i = 0; i < daily.length; i++) {
      final s = daily[i];
      final normName = norm(s.name);
      final brandColor = _sectionVisuals[normName]?.color ??
          fallbackColors[i % fallbackColors.length];

      slices.add(DonutSlice(
        label: s.name,
        value: s.totalRevenue,
        color: brandColor,
      ));
    }

    return ChartCard(
      title: "Today's Revenue by Section",
      child: DonutChartWidget(
        slices: slices,
        currency: _currencyForBloc(),
        negativeColor: _colorNegative,
        size: 200,
        centerSubtitle: 'Positive Revenue',
      ),
    );
  }

  /// Small helper — reads currency from the current DashboardBloc state.
  /// Extracted because DonutChartWidget needs to format currency itself.
  String _currencyForBloc() {
    final state = context.read<DashboardBloc>().state;
    return state.data?.currency.defaultCurrency ?? 'INR';
  }
  //todo
  /// Waterfall chart: shows how each section adds up (or subtracts) to
  /// the day's net revenue. Green bars for gains, red for losses, and a
  /// grounded blue bar at the end for the running total.
  // Widget _revenueChart(List<SectionDaily> daily) {
  //   final steps = daily
  //       .map((s) => WaterfallStep(label: s.name, value: s.totalRevenue))
  //       .toList();

  //   final currency = _currencyForBloc();

  //   return ChartCard(
  //     title: "Today's Revenue Breakdown",
  //     child: Column(
  //       children: [
  //         WaterfallChartWidget(
  //           steps: steps,
  //           currency: currency,
  //           positiveColor: _colorRevenue,
  //           negativeColor: _colorNegative,
  //           totalColor: const Color(0xFF60A5FA),
  //           height: 320,
  //           barWidth: 22,
  //           totalLabel: 'Net',
  //         ),
  //         const Gap(10),
  //         const WaterfallLegend(
  //           positiveColor: Color(0xFF4ADE80),
  //           negativeColor: Color(0xFFEF4444),
  //           totalColor: Color(0xFF60A5FA),
  //           totalLabel: 'Net',
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // /// Small helper — reads currency from the current DashboardBloc state.
  // String _currencyForBloc() {
  //   final state = context.read<DashboardBloc>().state;
  //   return state.data?.currency.defaultCurrency ?? 'INR';
  // }

  Widget _summaryCard(double revenue, String currency) {
    final isNegative = revenue < 0;
    final displayColor = isNegative ? _colorNegative : _colorRevenue;

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
              color: displayColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isNegative ? Icons.trending_down : Icons.trending_up,
              color: displayColor,
              size: 24,
            ),
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
                  color:
                      isNegative ? _colorNegative : DashboardColors.textOnDark,
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

class _BranchTile extends StatelessWidget {
  final Branch branch;
  final bool isSelected;
  final VoidCallback? onTap;

  const _BranchTile({
    required this.branch,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isSelected
        ? SectionTheme.home.backgroundGradient[0].withValues(alpha: 0.18)
        : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF4ADE80).withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.business_outlined,
                    size: 16,
                    color: isSelected
                        ? const Color(0xFF4ADE80)
                        : DashboardColors.textOnDarkMuted,
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      KStyles().semiBold(
                        text: branch.text,
                        size: 13,
                        color: DashboardColors.textOnDark,
                      ),
                      const Gap(2),
                      KStyles().reg(
                        text: branch.value,
                        size: 10,
                        color: DashboardColors.textOnDarkMuted,
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle,
                      color: Color(0xFF4ADE80), size: 18),
              ],
            ),
          ),
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
  final bool showRevenue;
  final double revenue;
  final String currency;
  final VoidCallback onTap;

  const _DeptTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.revenue,
    required this.currency,
    this.showRevenue = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isNegative = revenue < 0;
    const negativeColor = Color(0xFFEF4444);

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
              if (showRevenue) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    KStyles().bold(
                      text: CurrencyUtils.format(revenue, currency),
                      size: 14,
                      color: isNegative
                          ? negativeColor
                          : DashboardColors.textOnDark,
                    ),
                    KStyles().reg(
                      text: StringConstants.revenueLabel,
                      size: 10,
                      color: DashboardColors.textOnDarkMuted,
                    ),
                  ],
                ),
                const Gap(6),
              ],
              const Icon(Icons.chevron_right,
                  color: DashboardColors.textOnDarkMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
