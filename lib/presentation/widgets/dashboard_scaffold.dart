import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../core/constants/section_theme.dart';
import '../../core/constants/text_styles.dart';

/// Shared scaffold for every section dashboard.
/// Provides: full-screen gradient background, dark app bar with back arrow,
/// title + subtitle, and a scrollable content area.
class DashboardScaffold extends StatelessWidget {
  final SectionTheme theme;
  final String title;
  final List<Widget> children;
  final bool showBackButton;
  final List<Widget>? actions;

  const DashboardScaffold({
    super.key,
    required this.theme,
    required this.title,
    required this.children,
    this.showBackButton = true,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            children: [
              _appBar(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: children,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _appBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
      child: Row(
        children: [
          if (showBackButton)
            IconButton(
              icon: const Icon(Icons.arrow_back,
                  color: DashboardColors.textOnDark),
              onPressed: () => Navigator.pop(context),
            )
          else
            const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                KStyles().bold(
                  text: title,
                  size: 18,
                  color: DashboardColors.textOnDark,
                ),
                KStyles().reg(
                  text: theme.subtitle,
                  size: 12,
                  color: DashboardColors.textOnDarkMuted,
                ),
              ],
            ),
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}
