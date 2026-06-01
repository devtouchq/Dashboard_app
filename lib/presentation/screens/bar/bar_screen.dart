import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/section_theme.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../data/models/dashboard_data.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../widgets/chart_card.dart';
import '../../widgets/charts/bar_chart_widget.dart';
import '../../widgets/dashboard_scaffold.dart';
import '../../widgets/stat_card.dart';

class BarScreen extends StatelessWidget {
  const BarScreen({super.key});

  static const _tag = 'BarScreen';

  // Color palette cycled through the category bars.
  // Each category gets its own color via colorOverride.
  static const _palette = <Color>[
    Color(0xFFE74C3C), // wine red
    Color(0xFFF39C12), // beer amber
    Color(0xFF8E44AD), // gin purple
    Color(0xFF16A085), // teal
    Color(0xFF3498DB), // blue
    Color(0xFFE67E22), // orange
    Color(0xFFD35400), // dark orange
    Color(0xFF27AE60), // green
  ];

  @override
  Widget build(BuildContext context) {
    AppLogger.info(_tag, 'build()');
    return BlocBuilder<DashboardBloc, DashboardState>(
      buildWhen: (a, b) =>
          a.data?.bar != b.data?.bar || a.data?.currency != b.data?.currency,
      builder: (context, state) {
        final data = state.data?.bar;
        final currency = state.data?.currency.defaultCurrency ?? 'INR';
        return DashboardScaffold(
          theme: SectionTheme.bar,
          title: 'Bar Dashboard',
          children: data == null ? [_loading()] : [_content(data, currency)],
        );
      },
    );
  }

  Widget _loading() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );

  Widget _content(BarData data, String currency) {
    return Column(
      children: [
        StatCardRow(
          cards: [
            StatCard(
              icon: Icons.attach_money,
              iconColor: DashboardColors.iconOrange,
              value: CurrencyUtils.format(data.totalRevenue, currency),
              label: 'Revenue',
            ),
            StatCard(
              icon: Icons.payments_outlined,
              iconColor: DashboardColors.iconTeal,
              value: CurrencyUtils.format(data.totalCollection, currency),
              label: 'Collection',
            ),
          ],
        ),
        const Gap(16),
        _categoryChart(data, currency),
        const Gap(16),
        // ChartCard(
        //   title: 'Revenue vs Collection',
        //   child: BarChartWidget(
        //     groups: [
        //       BarGroup(label: 'Revenue', values: [data.totalRevenue.abs()]),
        //       BarGroup(
        //           label: 'Collection', values: [data.totalCollection.abs()]),
        //     ],
        //     barColors: const [Color(0xFFFF8A3D)],
        //     barWidth: 40,
        //     height: 200,
        //   ),
        // ),
      ],
    );
  }

  /// Per-category bar chart built from the parsed
  /// hiddenTotalBarItemAmount / hiddenTotalBarItemCategory fields.
  Widget _categoryChart(BarData data, String currency) {
    if (data.itemTotals.isEmpty) {
      return ChartCard(
        title: 'Sales by Category',
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Center(
            child: KStyles().reg(
              text: 'No category data available',
              size: 12,
              color: DashboardColors.textOnDarkMuted,
            ),
          ),
        ),
      );
    }

    // Build a BarGroup per category with its assigned palette color.
    final groups = <BarGroup>[];
    for (var i = 0; i < data.itemTotals.length; i++) {
      final t = data.itemTotals[i];
      groups.add(BarGroup(
        label: t.category,
        values: [t.amount],
        colorOverride: _palette[i % _palette.length],
      ));
    }

    final topItem = data.itemTotals.first;

    return ChartCard(
      title: 'Sales by Category',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick takeaway line — names the top seller.
          Row(
            children: [
              const Icon(Icons.emoji_events_outlined,
                  color: Color(0xFFFFD700), size: 14),
              const Gap(4),
              Expanded(
                child: KStyles().reg(
                  text:
                      'Top seller: ${topItem.category} — ${CurrencyUtils.format(topItem.amount, currency)}',
                  size: 11,
                  color: DashboardColors.textOnDarkMuted,
                ),
              ),
            ],
          ),
          const Gap(10),
          // Legend chips — color + category name + amount.
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: List.generate(data.itemTotals.length, (i) {
              final t = data.itemTotals[i];
              final c = _palette[i % _palette.length];
              return _legendChip(
                color: c,
                label: t.category,
                amount: CurrencyUtils.format(t.amount, currency),
              );
            }),
          ),
          const Gap(14),
          BarChartWidget(
            groups: groups,
            barColors: const [Color(0xFFFF8A3D)], // fallback (unused)
            barWidth: 32,
            height: 240,
            rotateLabels: data.itemTotals.length > 5 ? -0.4 : 0,
          ),
        ],
      ),
    );
  }

  Widget _legendChip({
    required Color color,
    required String label,
    required String amount,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const Gap(6),
          KStyles().semiBold(
            text: label,
            size: 10,
            color: DashboardColors.textOnDark,
          ),
          const Gap(4),
          KStyles().reg(
            text: amount,
            size: 10,
            color: DashboardColors.textOnDarkMuted,
          ),
        ],
      ),
    );
  }
}
