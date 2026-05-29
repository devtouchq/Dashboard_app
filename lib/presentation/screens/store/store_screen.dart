import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/section_theme.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../data/models/dashboard_data.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../widgets/dashboard_scaffold.dart';
import '../../widgets/stat_card.dart';

enum _StoreTab { sales, purchase, production }

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  static const _tag = 'StoreScreen';
  _StoreTab _active = _StoreTab.sales;

  @override
  Widget build(BuildContext context) {
    AppLogger.info(_tag, 'build()');
    return BlocBuilder<DashboardBloc, DashboardState>(
      buildWhen: (a, b) =>
          a.data?.store != b.data?.store ||
          a.data?.currency != b.data?.currency,
      builder: (context, state) {
        final data = state.data?.store;
        final currency = state.data?.currency.defaultCurrency ?? 'INR';
        return DashboardScaffold(
          theme: SectionTheme.store,
          title: 'Store Dashboard',
          children: data == null ? [_loading()] : [_content(data, currency)],
        );
      },
    );
  }

  Widget _loading() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );

  Widget _content(StoreData data, String currency) {
    String m(double v) => CurrencyUtils.format(v, currency);
    return Column(
      children: [
        StatCardRow(
          cards: [
            StatCard(
              icon: Icons.attach_money,
              iconColor: DashboardColors.iconPurple,
              value: m(data.totalRevenue),
              label: 'Revenue',
            ),
            StatCard(
              icon: Icons.payments_outlined,
              iconColor: DashboardColors.iconBlue,
              value: m(data.totalCollection),
              label: 'Collection',
            ),
            StatCard(
              icon: Icons.precision_manufacturing_outlined,
              iconColor: DashboardColors.iconTeal,
              value: data.wipPercentage,
              label: 'WIP',
            ),
          ],
        ),
        const Gap(20),
        _tabSwitcher(),
        const Gap(16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: KeyedSubtree(
            key: ValueKey(_active),
            child: _tabContent(data, m),
          ),
        ),
      ],
    );
  }

  Widget _tabSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          _tab(_StoreTab.sales, 'Sales', Icons.point_of_sale_outlined),
          _tab(_StoreTab.purchase, 'Purchase', Icons.shopping_bag_outlined),
          _tab(_StoreTab.production, 'Production',
              Icons.precision_manufacturing_outlined),
        ],
      ),
    );
  }

  Widget _tab(_StoreTab tab, String label, IconData icon) {
    final active = _active == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _active = tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? SectionTheme.store.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: active
                      ? Colors.white
                      : DashboardColors.textOnDarkSecondary),
              const Gap(6),
              KStyles().semiBold(
                text: label,
                size: 12,
                color:
                    active ? Colors.white : DashboardColors.textOnDarkSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabContent(StoreData data, String Function(double) m) {
    switch (_active) {
      case _StoreTab.sales:
        return Column(
          children: [
            _detail(Icons.summarize_outlined, DashboardColors.iconGreen,
                'Total Sales', m(data.sales.totalSales)),
            const Gap(10),
            _detail(Icons.location_on_outlined, DashboardColors.iconBlue,
                'Inside Kerala', m(data.sales.insideKerala)),
            const Gap(10),
            _detail(Icons.map_outlined, DashboardColors.iconPurple,
                'Outside Kerala', m(data.sales.outsideKerala)),
            const Gap(10),
            _detail(Icons.flight_takeoff_outlined, DashboardColors.iconAmber,
                'Export', m(data.sales.export)),
          ],
        );
      case _StoreTab.purchase:
        return Column(
          children: [
            _detail(Icons.shopping_bag_outlined, DashboardColors.iconPurple,
                'Total Purchase', m(data.purchaseSummary.totalPurchase)),
            const Gap(10),
            _detail(
                Icons.account_balance_wallet_outlined,
                DashboardColors.iconTeal,
                'Total Remittance',
                m(data.purchaseSummary.totalRemittance)),
            const Gap(10),
            _detail(Icons.hourglass_top_outlined, DashboardColors.iconOrange,
                'Pending', m(data.purchaseSummary.pending)),
          ],
        );
      case _StoreTab.production:
        return _detail(
          Icons.precision_manufacturing_outlined,
          DashboardColors.iconTeal,
          'Work in Progress',
          data.wipPercentage,
          large: true,
        );
    }
  }

  Widget _detail(IconData icon, Color color, String label, String value,
      {bool large = false}) {
    return Container(
      padding: EdgeInsets.all(large ? 20 : 14),
      decoration: BoxDecoration(
        color: DashboardColors.statCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DashboardColors.statCardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: large ? 52 : 42,
            height: large ? 52 : 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: large ? 26 : 22),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                KStyles().reg(
                  text: label,
                  size: 12,
                  color: DashboardColors.textOnDarkMuted,
                ),
                const Gap(4),
                KStyles().bold(
                  text: value,
                  size: large ? 26 : 20,
                  color: DashboardColors.textOnDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
