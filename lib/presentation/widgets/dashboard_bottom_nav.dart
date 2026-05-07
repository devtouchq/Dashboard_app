import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/text_styles.dart';

class DashboardBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const DashboardBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItemData(
        Icons.home_rounded,
        Icons.home_outlined,
        'Home',
      ),
      _NavItemData(
        Icons.notifications_rounded,
        Icons.notifications_outlined,
        'Notifications',
        showBadge: true,
      ),
      _NavItemData(
        Icons.person_rounded,
        Icons.person_outline,
        'Profile',
      ),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.borderColor)),
      ),
      padding: const EdgeInsets.only(top: 10, bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final item = items[i];
          final isActive = currentIndex == i;
          final color = isActive ? AppColors.primaryColor : AppColors.textMuted;

          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(i),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        isActive ? item.activeIcon : item.icon,
                        size: 24,
                        color: color,
                      ),
                      if (item.showBadge)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.emrColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.white,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Gap(4),
                  isActive
                      ? KStyles().semiBold(
                          text: item.label,
                          size: 11,
                          color: color,
                        )
                      : KStyles().reg(
                          text: item.label,
                          size: 11,
                          color: color,
                        ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItemData {
  final IconData activeIcon;
  final IconData icon;
  final String label;
  final bool showBadge;

  _NavItemData(
    this.activeIcon,
    this.icon,
    this.label, {
    this.showBadge = false,
  });
}
