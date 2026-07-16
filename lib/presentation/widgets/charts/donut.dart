import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/section_theme.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/currency_utils.dart';

/// One entry in the donut chart. Positive `value` → wedge in the donut.
/// Negative `value` → shown in the "Losses" list below.
class DonutSlice {
  final String label;
  final double value;
  final Color color;

  const DonutSlice({
    required this.label,
    required this.value,
    required this.color,
  });
}

/// Donut chart that gracefully handles both positive and negative values.
///
/// - Positive slices form the donut. Wedge sizes are proportional to
///   each slice's contribution to the positive total.
/// - The center of the donut shows the sum of positive values.
/// - Negative slices are listed separately below the donut (they can't
///   be represented as wedges of a whole).
///
/// Interactive: tap a slice to see its value pop in the center.
class DonutChartWidget extends StatefulWidget {
  final List<DonutSlice> slices;
  final String currency;
  final Color negativeColor;
  final double size;

  /// Text shown in the center below the total. e.g. "positive revenue".
  final String centerSubtitle;

  const DonutChartWidget({
    super.key,
    required this.slices,
    required this.currency,
    this.negativeColor = const Color(0xFFEF4444),
    this.size = 200,
    this.centerSubtitle = 'Positive Revenue',
  });

  @override
  State<DonutChartWidget> createState() => _DonutChartWidgetState();
}

class _DonutChartWidgetState extends State<DonutChartWidget> {
  /// Index of the currently touched slice. -1 = none.
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
    // Split into positives (donut) and negatives (losses list).
    final positives =
        widget.slices.where((s) => s.value > 0).toList(growable: false);
    final negatives =
        widget.slices.where((s) => s.value < 0).toList(growable: false);

    final positiveSum = positives.fold<double>(0, (acc, s) => acc + s.value);
    final negativeSum = negatives.fold<double>(0, (acc, s) => acc + s.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (positives.isEmpty)
          _noPositivesFallback()
        else
          _donutSection(positives, positiveSum),
        if (positives.isNotEmpty && negatives.isNotEmpty) const Gap(20),
        if (negatives.isNotEmpty) _lossesSection(negatives, negativeSum),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Donut (positive slices)
  // ─────────────────────────────────────────────────────────────
  Widget _donutSection(List<DonutSlice> positives, double positiveSum) {
    return Column(
      children: [
        SizedBox(
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (event, pieResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieResponse == null ||
                            pieResponse.touchedSection == null) {
                          _touched = -1;
                          return;
                        }
                        _touched =
                            pieResponse.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: widget.size * 0.28,
                  startDegreeOffset: -90,
                  sections: _buildSections(positives, positiveSum),
                ),
              ),
              _centerLabel(positives, positiveSum),
            ],
          ),
        ),
        const Gap(36),
        _legend(positives, positiveSum),
      ],
    );
  }

  List<PieChartSectionData> _buildSections(
      List<DonutSlice> positives, double positiveSum) {
    return List.generate(positives.length, (i) {
      final s = positives[i];
      final isTouched = i == _touched;
      final percent = positiveSum == 0 ? 0.0 : (s.value / positiveSum) * 100;

      // Touched slice pops out slightly.
      final radius = isTouched ? (widget.size * 0.36) : (widget.size * 0.32);

      return PieChartSectionData(
        color: s.color,
        value: s.value,
        title: percent >= 8 ? '${percent.toStringAsFixed(0)}%' : '',
        radius: radius,
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        titlePositionPercentageOffset: 0.6,
      );
    });
  }

  /// Center label: either the total or the touched slice's value.
  Widget _centerLabel(List<DonutSlice> positives, double positiveSum) {
    // If a slice is touched, show its info; otherwise show the total.
    if (_touched >= 0 && _touched < positives.length) {
      final s = positives[_touched];
      return _CenterLabelContent(
        title: s.label,
        value: CurrencyUtils.format(s.value, widget.currency),
        subtitle: '${((s.value / positiveSum) * 100).toStringAsFixed(1)}%',
        valueColor: s.color,
      );
    }
    return _CenterLabelContent(
      title: 'Total',
      value: CurrencyUtils.format(positiveSum, widget.currency),
      subtitle: widget.centerSubtitle,
      valueColor: Colors.white,
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Legend (dots + labels beneath donut)
  // ─────────────────────────────────────────────────────────────
  Widget _legend(List<DonutSlice> positives, double positiveSum) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 14,
      runSpacing: 8,
      children: positives.asMap().entries.map((entry) {
        final i = entry.key;
        final s = entry.value;
        final isTouched = i == _touched;
        final percent = positiveSum == 0 ? 0.0 : (s.value / positiveSum) * 100;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: s.color,
                shape: BoxShape.circle,
                border: isTouched
                    ? Border.all(color: Colors.white, width: 1.5)
                    : null,
              ),
            ),
            const Gap(6),
            KStyles().reg(
              text: s.label,
              size: 11,
              color: DashboardColors.textOnDarkSecondary,
            ),
            const Gap(4),
            KStyles().semiBold(
              text: '${percent.toStringAsFixed(0)}%',
              size: 11,
              color: DashboardColors.textOnDark,
            ),
          ],
        );
      }).toList(),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Losses (negative slices)
  // ─────────────────────────────────────────────────────────────
  Widget _lossesSection(List<DonutSlice> negatives, double negativeSum) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: widget.negativeColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.negativeColor.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_down, color: widget.negativeColor, size: 16),
              const Gap(6),
              KStyles().semiBold(
                text: 'Losses',
                size: 12,
                color: widget.negativeColor,
              ),
              const Spacer(),
              KStyles().bold(
                text: CurrencyUtils.format(negativeSum, widget.currency),
                size: 13,
                color: widget.negativeColor,
              ),
            ],
          ),
          const Gap(10),
          ...negatives.map((s) => _lossRow(s)),
        ],
      ),
    );
  }

  Widget _lossRow(DonutSlice s) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: widget.negativeColor,
              shape: BoxShape.circle,
            ),
          ),
          const Gap(10),
          Expanded(
            child: KStyles().reg(
              text: s.label,
              size: 12,
              color: DashboardColors.textOnDark,
            ),
          ),
          KStyles().semiBold(
            text: CurrencyUtils.format(s.value, widget.currency),
            size: 12,
            color: widget.negativeColor,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Fallback when there are no positive slices
  // ─────────────────────────────────────────────────────────────
  Widget _noPositivesFallback() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.info_outline, color: Colors.white54, size: 20),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KStyles().semiBold(
                  text: 'No positive revenue yet',
                  size: 13,
                  color: DashboardColors.textOnDark,
                ),
                const Gap(2),
                KStyles().reg(
                  text:
                      'Positive sections will appear here as they log activity.',
                  size: 11,
                  color: DashboardColors.textOnDarkMuted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The stacked text inside the donut's center hole.
class _CenterLabelContent extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color valueColor;

  const _CenterLabelContent({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        KStyles().reg(
          text: title,
          size: 10,
          color: DashboardColors.textOnDarkMuted,
        ),
        const Gap(2),
        KStyles().bold(
          text: value,
          size: 16,
          color: valueColor,
        ),
        const Gap(2),
        KStyles().reg(
          text: subtitle,
          size: 9,
          color: DashboardColors.textOnDarkMuted,
        ),
      ],
    );
  }
}
