import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../core/constants/section_theme.dart';
import '../../core/constants/text_styles.dart';

class StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final String? trendText;
  final Color? trendColor;

  const StatCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.trendText,
    this.trendColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: DashboardColors.statCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DashboardColors.statCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const Gap(10),
          // FittedBox scales the value down if it's wider than the card.
          // alignment.centerLeft so it shrinks but stays left-aligned.
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: KStyles().bold(
                text: value,
                size: 18,
                color: DashboardColors.textOnDark,
              ),
            ),
          ),
          const Gap(4),
          KStyles().reg(
            text: label,
            size: 10,
            color: DashboardColors.textOnDarkMuted,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (trendText != null) ...[
            const Gap(4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.trending_up,
                  size: 11,
                  color: trendColor ?? DashboardColors.textOnDarkMuted,
                ),
                const Gap(3),
                KStyles().semiBold(
                  text: trendText!,
                  size: 10,
                  color: trendColor ?? DashboardColors.textOnDarkMuted,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A row of 2-3 StatCards laid out with equal flex.
class StatCardRow extends StatelessWidget {
  final List<StatCard> cards;

  const StatCardRow({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const Gap(10),
          Expanded(child: cards[i]),
        ],
      ],
    );
  }
}
