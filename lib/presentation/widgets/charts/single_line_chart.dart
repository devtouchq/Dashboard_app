import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/section_theme.dart';
import '../../../core/constants/text_styles.dart';

class SingleLineChart extends StatefulWidget {
  final List<double> values;
  final List<String> xLabels;
  final Color lineColor;
  final bool fillBelow;
  final double height;
  final double? yMax;

  const SingleLineChart({
    super.key,
    required this.values,
    required this.xLabels,
    required this.lineColor,
    this.fillBelow = false,
    this.height = 200,
    this.yMax,
  });

  @override
  State<SingleLineChart> createState() => _SingleLineChartState();
}

class _SingleLineChartState extends State<SingleLineChart>
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
  void didUpdateWidget(covariant SingleLineChart old) {
    super.didUpdateWidget(old);
    if (old.values != widget.values) _controller.forward(from: 0);
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
          final t = _progress.value;
          return LineChart(
            LineChartData(
              minX: 0,
              maxX: (widget.xLabels.length - 1).toDouble(),
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
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                    reservedSize: 28,
                    interval: 1,
                    getTitlesWidget: (value, _) {
                      final i = value.toInt();
                      if (i < 0 || i >= widget.xLabels.length) {
                        return const SizedBox();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: KStyles().reg(
                          text: widget.xLabels[i],
                          size: 10,
                          color: DashboardColors.chartAxisLabel,
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                    widget.values.length,
                    (i) => FlSpot(i.toDouble(), widget.values[i] * t),
                  ),
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: widget.lineColor,
                  barWidth: 2.5,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                      radius: 4 * t,
                      color: widget.lineColor,
                      strokeWidth: 2 * t,
                      strokeColor: Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: widget.fillBelow,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        widget.lineColor.withValues(alpha: 0.4 * t),
                        widget.lineColor.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        },
      ),
    );
  }

  double _autoYMax() {
    double maxVal = 0;
    for (final v in widget.values) {
      if (v > maxVal) maxVal = v;
    }
    if (maxVal <= 0) return 100;
    if (maxVal < 10) return 10;
    if (maxVal < 100) return ((maxVal / 10).ceil() + 1) * 10;
    if (maxVal < 1000) return ((maxVal / 100).ceil() + 1) * 100;
    return ((maxVal / 1000).ceil() + 1) * 1000;
  }
}
