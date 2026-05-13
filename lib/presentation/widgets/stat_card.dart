import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../core/constants/section_theme.dart';
import '../../core/constants/text_styles.dart';

/// Top-of-dashboard small stat card. Glassy card with a colored
/// icon square, big value, and small label.
///
/// Example:
///   StatCard(
///     icon: Icons.people, iconColor: DashboardColors.iconBlue,
///     value: '248', label: 'Total Patients',
///   )
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
      padding: const EdgeInsets.all(12),
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
          const Gap(10),
          KStyles().bold(
            text: value,
            size: 18,
            color: DashboardColors.textOnDark,
          ),
          const Gap(2),
          KStyles().reg(
            text: label,
            size: 11,
            color: DashboardColors.textOnDarkMuted,
          ),
          if (trendText != null) ...[
            const Gap(2),
            KStyles().med(
              text: trendText!,
              size: 10,
              color: trendColor ?? DashboardColors.iconGreen,
            ),
          ],
        ],
      ),
    );
  }
}

/// A row of 3 stat cards, evenly spaced. Used at the top of every dashboard.
class StatCardRow extends StatelessWidget {
  final List<StatCard> cards;

  const StatCardRow({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const Gap(10),
          Expanded(child: cards[i]),
        ],
      ],
    );
  }
}
