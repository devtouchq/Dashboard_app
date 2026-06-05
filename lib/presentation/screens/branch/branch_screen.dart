import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/section_theme.dart';
import '../../../core/constants/string_constants.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/di/injector.dart';
import '../../../core/utils/app_logger.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../../data/models/auth_data.dart';
import '../home/home_screen.dart';

class BranchScreen extends StatefulWidget {
  const BranchScreen({super.key});

  @override
  State<BranchScreen> createState() => _BranchScreenState();
}

class _BranchScreenState extends State<BranchScreen>
    with TickerProviderStateMixin {
  static const _tag = 'BranchScreen';

  Branch? _selected;

  late AnimationController _entry;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  late Animation<double> _iconScale;

  @override
  void initState() {
    super.initState();
    AppLogger.info(_tag, 'init');

    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _fade = CurvedAnimation(parent: _entry, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entry, curve: Curves.easeOutCubic));
    _iconScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _entry, curve: Curves.elasticOut),
    );

    _entry.forward();
  }

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  void _continue() {
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(StringConstants.branchRequired),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    AppLogger.info(_tag, 'continue with branch ${_selected!.value}');
    context.read<AuthBloc>().add(BranchSelected(_selected!));
  }

  @override
  Widget build(BuildContext context) {
    const theme = SectionTheme.home;

    return Scaffold(
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
          child: BlocListener<AuthBloc, AuthState>(
            listenWhen: (prev, curr) => prev.status != curr.status,
            listener: (context, state) {
              if (state.status == AuthStatus.branchSelected) {
                AppLogger.info(_tag, 'branch saved → navigate to Home');
                Navigator.pushAndRemoveUntil(
                  context,
                  PageRouteBuilder(
                    transitionDuration: const Duration(milliseconds: 600),
                    pageBuilder: (_, __, ___) => BlocProvider<DashboardBloc>(
                      create: (_) => autoInjector.get<DashboardBloc>()
                        ..add(const DashboardLoadRequested()),
                      child: const HomeScreen(),
                    ),
                    transitionsBuilder: (_, anim, __, child) {
                      return FadeTransition(
                        opacity: anim,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                              CurvedAnimation(
                                  parent: anim, curve: Curves.easeOutCubic)),
                          child: child,
                        ),
                      );
                    },
                  ),
                  (_) => false,
                );
              }
            },
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final branches = state.branches;
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          const Gap(40),
                          ScaleTransition(
                            scale: _iconScale,
                            child: _icon(theme),
                          ),
                          const Gap(28),
                          FadeTransition(
                            opacity: _fade,
                            child: SlideTransition(
                              position: _slide,
                              child: Column(
                                children: [
                                  KStyles().bold(
                                    text: StringConstants.selectBranch,
                                    size: 26,
                                    color: DashboardColors.textOnDark,
                                  ),
                                  const Gap(6),
                                  KStyles().reg(
                                    text: StringConstants.chooseYourBranch,
                                    size: 13,
                                    color:
                                        DashboardColors.textOnDarkSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Gap(36),
                          FadeTransition(
                            opacity: _fade,
                            child: SlideTransition(
                              position: _slide,
                              child: _branchList(branches),
                            ),
                          ),
                          const Gap(24),
                          FadeTransition(
                            opacity: _fade,
                            child: _continueButton(),
                          ),
                          const Gap(24),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _icon(SectionTheme theme) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Icon(
        Icons.business_outlined,
        size: 40,
        color: theme.accentSoft,
      ),
    );
  }

  Widget _branchList(List<Branch> branches) {
    if (branches.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Center(
          child: KStyles().reg(
            text: 'No branches available',
            size: 13,
            color: DashboardColors.textOnDarkMuted,
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < branches.length; i++) ...[
          if (i > 0) const Gap(10),
          _BranchTile(
            branch: branches[i],
            selected: _selected == branches[i],
            entryDelay: 0.3 + (i * 0.08),
            entryController: _entry,
            onTap: () => setState(() => _selected = branches[i]),
          ),
        ],
      ],
    );
  }

  Widget _continueButton() {
    final enabled = _selected != null;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: enabled ? _continue : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: SectionTheme.home.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          disabledBackgroundColor:
              Colors.white.withValues(alpha: 0.1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            KStyles().semiBold(
              text: StringConstants.continueText,
              size: 15,
              color: enabled
                  ? Colors.white
                  : DashboardColors.textOnDarkMuted,
            ),
            const Gap(8),
            Icon(Icons.arrow_forward,
                size: 18,
                color:
                    enabled ? Colors.white : DashboardColors.textOnDarkMuted),
          ],
        ),
      ),
    );
  }
}

class _BranchTile extends StatelessWidget {
  final Branch branch;
  final bool selected;
  final double entryDelay; // 0..1
  final AnimationController entryController;
  final VoidCallback onTap;

  const _BranchTile({
    required this.branch,
    required this.selected,
    required this.entryDelay,
    required this.entryController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final endDelay = (entryDelay + 0.25).clamp(0.0, 1.0);
    final anim = CurvedAnimation(
      parent: entryController,
      curve: Interval(entryDelay, endDelay, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: anim,
      builder: (context, _) {
        return Opacity(
          opacity: anim.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - anim.value)),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: selected
                      ? SectionTheme.home.accent.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected
                        ? SectionTheme.home.accent
                        : Colors.white.withValues(alpha: 0.12),
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: selected
                            ? SectionTheme.home.accent
                            : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.location_city_outlined,
                        size: 20,
                        color: selected
                            ? Colors.white
                            : DashboardColors.textOnDarkMuted,
                      ),
                    ),
                    const Gap(14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          KStyles().semiBold(
                            text: branch.text,
                            size: 14,
                            color: DashboardColors.textOnDark,
                          ),
                          const Gap(2),
                          KStyles().reg(
                            text: branch.value,
                            size: 11,
                            color: DashboardColors.textOnDarkMuted,
                          ),
                        ],
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: selected
                          ? Icon(
                              Icons.check_circle,
                              key: const ValueKey('checked'),
                              color: SectionTheme.home.accent,
                              size: 22,
                            )
                          : const SizedBox(
                              key: ValueKey('unchecked'),
                              width: 22,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
