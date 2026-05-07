import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/text_styles.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final Color accentColor;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final IconData? leadingIcon;

  const SectionHeader({
    super.key,
    required this.title,
    required this.accentColor,
    this.actionLabel,
    this.onActionTap,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 14, 2, 8),
      child: Row(
        children: [
          if (leadingIcon != null) ...[
            Icon(leadingIcon, size: 16, color: accentColor),
            const Gap(8),
          ] else ...[
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Gap(8),
          ],
          KStyles().semiBold(
            text: title,
            // size: 13,
            color: leadingIcon != null ? accentColor : AppColors.textPrimary,
          ),
          const Spacer(),
          if (actionLabel != null)
            GestureDetector(
              onTap: onActionTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: KStyles().med(
                  text: actionLabel!,
                  size: 12,
                  color: AppColors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
