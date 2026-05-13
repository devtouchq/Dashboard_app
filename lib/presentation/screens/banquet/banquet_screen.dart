import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/string_constants.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/app_logger.dart';
import '../../widgets/dashboard_app_bar.dart';

class BanquetScreen extends StatelessWidget {
  const BanquetScreen({super.key});

  static const _tag = 'BanquetScreen';

  // Sample data — replace with bloc + repository when API is ready.
  static const int _numberOfReservations = 0;
  static const int _numberOfFunctions = 0;
  static const double _totalRevenue = 0.00;

  @override
  Widget build(BuildContext context) {
    AppLogger.info(_tag, 'build()');
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            DashboardAppBar(
              title: StringConstants.banquet,
              titleColor: AppColors.banquetColor,
              showBackButton: true,
              onBack: () => Navigator.pop(context),
              actions: [
                AppBarIconButton(
                  icon: Icons.notifications_outlined,
                  onTap: () {},
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
                children: [
                  _tilesGrid(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tilesGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _BanquetTile(
                label: StringConstants.numberOfReservations,
                value: '$_numberOfReservations',
                icon: Icons.event_seat_outlined,
                bgColor: AppColors.banquetBlueBg,
                borderColor: AppColors.banquetBlueBorder,
              ),
            ),
            const Gap(10),
            Expanded(
              child: _BanquetTile(
                label: StringConstants.numberOfFunctions,
                value: '$_numberOfFunctions',
                icon: Icons.celebration_outlined,
                bgColor: AppColors.banquetPeachBg,
                borderColor: AppColors.banquetPeachBorder,
              ),
            ),
          ],
        ),
        const Gap(10),
        _BanquetTile(
          label: StringConstants.totalRevenue,
          value: _totalRevenue.toStringAsFixed(2),
          icon: Icons.show_chart,
          bgColor: AppColors.banquetGreenBg,
          borderColor: AppColors.banquetGreenBorder,
          isWide: true,
        ),
      ],
    );
  }
}

/// A banquet stat tile — colored background, dotted-ish border, an icon
/// avatar in the top-right corner, label on the left, then a small note
/// icon + value at the bottom.
class _BanquetTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color bgColor;
  final Color borderColor;
  final bool isWide;

  const _BanquetTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.bgColor,
    required this.borderColor,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      height: 120,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Stack(
        children: [
          // Top-right circular icon avatar
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 22, color: borderColor),
            ),
          ),
          // Label + value on the left
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: isWide ? double.infinity : 110,
                child: KStyles().bold(
                  text: label,
                  size: 14,
                  color: AppColors.textPrimary,
                  maxLines: 2,
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.sticky_note_2_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const Gap(6),
                  KStyles().bold(
                    text: value,
                    size: 16,
                    color: AppColors.textPrimary,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
