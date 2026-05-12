import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/text_styles.dart';

class DashboardAppBar extends StatelessWidget {
  final String? greeting;
  final String title;
  final Color? titleColor;
  final bool showBackButton;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final Color? bgcolor;

  const DashboardAppBar({
    super.key,
    this.greeting,
    required this.title,
    this.titleColor,
    this.showBackButton = false,
    this.actions,
    this.onBack,
    this.bgcolor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bgcolor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            if (showBackButton) ...[
              _IconButton(
                icon: Icons.arrow_back,
                onTap: onBack ?? () => Navigator.maybePop(context),
              ),
              const Gap(10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (greeting != null) ...[
                    KStyles().reg(
                      text: greeting!,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const Gap(1),
                  ],
                  //display tile in center if no greeting,
                  if (greeting == null)
                    Center(
                      child: KStyles().bold(
                        text: title,
                        size: 22,
                        color: titleColor ?? AppColors.textPrimary,
                      ),
                    )
                  else
                    KStyles().bold(
                      text: title,
                      size: 22,
                      color: titleColor ?? AppColors.textPrimary,
                    ),
                ],
              ),
            ),
            if (actions != null)
              Row(
                children: [
                  for (var i = 0; i < actions!.length; i++) ...[
                    if (i > 0) const Gap(12),
                    actions![i],
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Widget? badge;

  const _IconButton({required this.icon, this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(icon, size: 16, color: const Color(0xFF475569)),
            ),
            if (badge != null) Positioned(top: 5, right: 6, child: badge!),
          ],
        ),
      ),
    );
  }
}

/// Public icon button used in app bar actions.
class AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool showBadge;

  const AppBarIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return _IconButton(
      icon: icon,
      onTap: onTap,
      badge: showBadge
          ? Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: AppColors.emrColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 1.5),
              ),
            )
          : null,
    );
  }
}
