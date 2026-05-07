import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/app_logger.dart';
import '../../widgets/dashboard_app_bar.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const _tag = 'NotificationsScreen';

  @override
  Widget build(BuildContext context) {
    AppLogger.info(_tag, 'build()');

    final notifications = _sampleNotifications();

    return Column(
      children: [
        DashboardAppBar(
          greeting: 'Inbox',
          title: 'Notifications',
          actions: [
            AppBarIconButton(icon: Icons.done_all, onTap: () {}),
          ],
        ),
        Expanded(
          child: notifications.isEmpty
              ? _emptyState()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const Gap(8),
                  itemBuilder: (_, i) => _NotificationTile(
                    item: notifications[i],
                  ),
                ),
        ),
      ],
    );
  }

  List<_NotificationItem> _sampleNotifications() {
    return const [
      _NotificationItem(
        title: 'New patient registered',
        message: 'Anil Kumar registered for OP consultation.',
        time: '2 min ago',
        category: _NotifCategory.emr,
        unread: true,
      ),
      _NotificationItem(
        title: 'Payment received',
        message: '₹4,500 collected via UPI from Priya R.',
        time: '15 min ago',
        category: _NotifCategory.accounts,
        unread: true,
      ),
      _NotificationItem(
        title: 'Low stock alert',
        message: 'Ashwagandha Tablets — only 12 units left.',
        time: '1 hour ago',
        category: _NotifCategory.store,
        unread: true,
      ),
      _NotificationItem(
        title: 'Bed assigned',
        message: 'Bed B-203 assigned to Ramesh M.',
        time: '3 hours ago',
        category: _NotifCategory.emr,
        unread: false,
      ),
      _NotificationItem(
        title: 'Daily report ready',
        message: 'Yesterday\'s collection report is ready for review.',
        time: 'Yesterday',
        category: _NotifCategory.accounts,
        unread: false,
      ),
    ];
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.notifications_off_outlined,
            size: 48,
            color: AppColors.textMuted,
          ),
          const Gap(12),
          KStyles().med(
            text: 'No notifications yet',
            size: 14,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

enum _NotifCategory { emr, accounts, store }

class _NotificationItem {
  final String title;
  final String message;
  final String time;
  final _NotifCategory category;
  final bool unread;

  const _NotificationItem({
    required this.title,
    required this.message,
    required this.time,
    required this.category,
    required this.unread,
  });
}

class _NotificationTile extends StatelessWidget {
  final _NotificationItem item;

  const _NotificationTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(item.category);
    final icon = _iconFor(item.category);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.unread
              ? color.withOpacity(0.3)
              : AppColors.borderColor,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: KStyles().semiBold(
                        text: item.title,
                        size: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (item.unread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.emrColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const Gap(4),
                KStyles().reg(
                  text: item.message,
                  size: 12,
                  color: AppColors.textSecondary,
                  maxLines: 2,
                ),
                const Gap(6),
                KStyles().reg(
                  text: item.time,
                  size: 11,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _colorFor(_NotifCategory c) {
    switch (c) {
      case _NotifCategory.emr:
        return AppColors.emrColor;
      case _NotifCategory.accounts:
        return AppColors.accountsColor;
      case _NotifCategory.store:
        return AppColors.storeColor;
    }
  }

  IconData _iconFor(_NotifCategory c) {
    switch (c) {
      case _NotifCategory.emr:
        return Icons.medical_services_outlined;
      case _NotifCategory.accounts:
        return Icons.account_balance_wallet_outlined;
      case _NotifCategory.store:
        return Icons.storefront_outlined;
    }
  }
}
