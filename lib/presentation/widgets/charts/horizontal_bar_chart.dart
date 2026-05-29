import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/section_theme.dart';
import '../../../core/constants/text_styles.dart';

class HBarItem {
  final String label;
  final double value;
  const HBarItem({required this.label, required this.value});
}

class HorizontalBarChart extends StatefulWidget {
  final List<HBarItem> items;
  final Color barColor;
  final double height;

  const HorizontalBarChart({
    super.key,
    required this.items,
    required this.barColor,
    this.height = 200,
  });

  @override
  State<HorizontalBarChart> createState() => _HorizontalBarChartState();
}

class _HorizontalBarChartState extends State<HorizontalBarChart>
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
    _progress =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant HorizontalBarChart old) {
    super.didUpdateWidget(old);
    if (old.items != widget.items) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxVal = _autoMax();

    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _progress,
        builder: (context, _) {
          final t = _progress.value.clamp(0.0, 1.0);

          return BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxVal,
              minY: 0,
              // rotationQuarterTurns: 1,
              gridData: FlGridData(
                show: true,
                drawHorizontalLine: false,
                verticalInterval: maxVal / 4,
                getDrawingVerticalLine: (_) => FlLine(
                  color: DashboardColors.chartGrid,
                  strokeWidth: 1,
                  dashArray: const [3, 4],
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                show: true,
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    interval: maxVal / 4,
                    getTitlesWidget: (value, _) => Padding(
                      padding: const EdgeInsets.only(top: 6),
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
                    reservedSize: 80,
                    
                    getTitlesWidget: (value, _) {
                      final i = value.toInt();
                      if (i < 0 || i >= widget.items.length) {
                        return const SizedBox();
                      }
                      // Rotate label to vertical
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: KStyles().reg(
                            text: widget.items[i].label,
                            size: 11,
                            color: DashboardColors.textOnDarkSecondary,
                          ),
                        ),
                      );
                    },
                    //!-accoroding the documentation the reservation plan should be equal to teh ability of teh code an the 
                    //the number of teh person present he area is multipied by the people of the people and the people has to vote for the 
                    //the reservation of the plan they have made 
                  ),
                ),
              ),
              barGroups: List.generate(widget.items.length, (i) {
                // Staggered grow per bar
                final start = (i / widget.items.length) * 0.4;
                final localT = ((t - start) / 0.6).clamp(0.0, 1.0);
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: widget.items[i].value * localT,
                      color: widget.barColor,
                      width: 14,
                      borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(4)),
                    ),
                  ],
                );
              }),
            ),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        },
      ),
    );
  }

  double _autoMax() {
    double maxVal = 0;
    for (final i in widget.items) {
      if (i.value > maxVal) maxVal = i.value;
    }
    if (maxVal <= 0) return 1;
    if (maxVal < 10) return 10;
    if (maxVal < 100) return ((maxVal / 10).ceil() + 1) * 10;
    return ((maxVal / 100).ceil() + 1) * 100;
  }
}
