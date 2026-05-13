import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/section_theme.dart';
import '../../../core/constants/text_styles.dart';

class BarGroup {
  final String label;
  final List<double> values;
  const BarGroup({required this.label, required this.values});
}

class BarChartWidget extends StatefulWidget {
  final List<BarGroup> groups;
  final List<Color> barColors;
  final double height;
  final double? yMax;
  final double barWidth;
  final double rotateLabels;

  const BarChartWidget({
    super.key,
    required this.groups,
    required this.barColors,
    this.height = 220,
    this.yMax,
    this.barWidth = 14,
    this.rotateLabels = 0,
  });

  @override
  State<BarChartWidget> createState() => _BarChartWidgetState();
}

class _BarChartWidgetState extends State<BarChartWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _progress = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant BarChartWidget old) {
    super.didUpdateWidget(old);
    if (old.groups != widget.groups) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveYMax = widget.yMax ?? _autoYMax();

    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _progress,
        builder: (context, _) {
          final t = _progress.value.clamp(0.0, 1.0);

          return BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              minY: 0,
              maxY: effectiveYMax,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: effectiveYMax / 4,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: DashboardColors.chartGrid,
                  strokeWidth: 1,
                  dashArray: const [3, 4],
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: effectiveYMax / 4,
                    getTitlesWidget: (value, _) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: KStyles().reg(
                        text: value.toInt().toString(),
                        size: 10,
                        color: DashboardColors.chartAxisLabel,
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: widget.rotateLabels > 0 ? 50 : 28,
                    getTitlesWidget: (value, _) {
                      final i = value.toInt();
                      if (i < 0 || i >= widget.groups.length) {
                        return const SizedBox();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Transform.rotate(
                          angle: widget.rotateLabels,
                          child: KStyles().reg(
                            text: widget.groups[i].label,
                            size: 10,
                            color: DashboardColors.chartAxisLabel,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: List.generate(widget.groups.length, (i) {
                final g = widget.groups[i];
                // Staggered grow: each group starts a bit after the previous.
                // groups span their growth across [0..0.85] then settle.
                final groupStart = (i / widget.groups.length) * 0.4;
                final localT = ((t - groupStart) / 0.6).clamp(0.0, 1.0);

                return BarChartGroupData(
                  x: i,
                  barsSpace: 4,
                  barRods: List.generate(g.values.length, (j) {
                    return BarChartRodData(
                      toY: g.values[j] * localT,
                      color: widget.barColors[j % widget.barColors.length],
                      width: widget.barWidth,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(4)),
                    );
                  }),
                );
              }),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => Colors.black87,
                  getTooltipItem: (group, _, rod, __) {
                    // Show the real value, not the animating one
                    final realValue = widget.groups[group.x.toInt()]
                        .values[group.barRods.indexOf(rod)];
                    return BarTooltipItem(
                      realValue.toInt().toString(),
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    );
                  },
                ),
              ),
            ),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        },
      ),
    );
  }

  double _autoYMax() {
    double maxVal = 0;
    for (final g in widget.groups) {
      for (final v in g.values) {
        if (v > maxVal) maxVal = v;
      }
    }
    if (maxVal <= 0) return 100;
    if (maxVal < 10) return 10;
    if (maxVal < 100) return ((maxVal / 10).ceil() + 1) * 10;
    if (maxVal < 1000) return ((maxVal / 100).ceil() + 1) * 100;
    return ((maxVal / 1000).ceil() + 1) * 1000;
  }
}
