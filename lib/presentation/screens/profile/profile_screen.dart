import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/app_logger.dart';
import '../../widgets/app_card.dart';
import '../../widgets/dashboard_app_bar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _tag = 'ProfileScreen';

  @override
  Widget build(BuildContext context) {
    AppLogger.info(_tag, 'build()');

    return Column(
      children: [
        DashboardAppBar(
          greeting: 'Account',
          title: 'Profile',
          actions: [
            AppBarIconButton(icon: Icons.settings_outlined, onTap: () {}),
          ],
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
            children: [
              _profileHeader(),
              _statsRow(),
              const Gap(8),
              _sectionLabel('Account'),
              _settingsCard([
                _SettingItem(
                  icon: Icons.person_outline,
                  label: 'Personal information',
                  onTap: () {},
                ),
                _SettingItem(
                  icon: Icons.lock_outline,
                  label: 'Security & password',
                  onTap: () {},
                ),
                _SettingItem(
                  icon: Icons.business_outlined,
                  label: 'Branch & workspace',
                  onTap: () {},
                ),
              ]),
              _sectionLabel('Preferences'),
              _settingsCard([
                _SettingItem(
                  icon: Icons.notifications_outlined,
                  label: 'Notification settings',
                  onTap: () {},
                ),
                _SettingItem(
                  icon: Icons.language_outlined,
                  label: 'Language',
                  trailingText: 'English',
                  onTap: () {},
                ),
                _SettingItem(
                  icon: Icons.brightness_6_outlined,
                  label: 'Appearance',
                  trailingText: 'Light',
                  onTap: () {},
                ),
              ]),
              _sectionLabel('Support'),
              _settingsCard([
                _SettingItem(
                  icon: Icons.help_outline,
                  label: 'Help & support',
                  onTap: () {},
                ),
                _SettingItem(
                  icon: Icons.info_outline,
                  label: 'About Ayurliv',
                  onTap: () {},
                ),
                _SettingItem(
                  icon: Icons.logout,
                  label: 'Sign out',
                  isDestructive: true,
                  onTap: () {},
                ),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _profileHeader() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      gradient: const LinearGradient(
        colors: AppColors.heroGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      showBorder: false,
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.person,
              size: 32,
              color: AppColors.white,
            ),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                KStyles().bold(
                  text: 'Dr. Sunil Menon',
                  size: 18,
                  color: AppColors.white,
                ),
                const Gap(2),
                KStyles().reg(
                  text: 'Administrator · Kochi branch',
                  size: 12,
                  color: AppColors.white.withOpacity(0.75),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.edit_outlined,
              size: 16,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsRow() {
    return Row(
      children: [
        Expanded(child: _statCard('581', 'Patients today')),
        const Gap(10),
        Expanded(child: _statCard('₹2,227', 'Collected today')),
        const Gap(10),
        Expanded(child: _statCard('12', 'Pending tasks')),
      ],
    );
  }

  Widget _statCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          KStyles().bold(
            text: value,
            size: 16,
            color: AppColors.textPrimary,
          ),
          const Gap(4),
          KStyles().reg(
            text: label,
            size: 11,
            color: AppColors.textSecondary,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: KStyles().semiBold(
        text: text,
        size: 12,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _settingsCard(List<_SettingItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          return Column(
            children: [
              InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(i == 0 ? 14 : 0),
                  bottom:
                      Radius.circular(i == items.length - 1 ? 14 : 0),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.icon,
                        size: 20,
                        color: item.isDestructive
                            ? AppColors.emrColor
                            : AppColors.textSecondary,
                      ),
                      const Gap(14),
                      Expanded(
                        child: KStyles().med(
                          text: item.label,
                          size: 14,
                          color: item.isDestructive
                              ? AppColors.emrColor
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (item.trailingText != null) ...[
                        KStyles().reg(
                          text: item.trailingText!,
                          size: 12,
                          color: AppColors.textMuted,
                        ),
                        const Gap(6),
                      ],
                      if (!item.isDestructive)
                        const Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                    ],
                  ),
                ),
              ),
              if (i < items.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Divider(
                    height: 1,
                    thickness: 0.5,
                    color: AppColors.dividerColor,
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _SettingItem {
  final IconData icon;
  final String label;
  final String? trailingText;
  final bool isDestructive;
  final VoidCallback? onTap;

  const _SettingItem({
    required this.icon,
    required this.label,
    this.trailingText,
    this.isDestructive = false,
    this.onTap,
  });
}
