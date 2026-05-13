import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/font_styles.dart';
import '../../../core/constants/section_theme.dart';
import '../../../core/constants/text_styles.dart';

/// One labeled line on a multi-line chart.
class LineSeries {
  final String name;
  final Color color;
  final List<double> values;

  const LineSeries({
    required this.name,
    required this.color,
    required this.values,
  });
}

/// Multi-line chart with smooth draw-on animation.
class MultiLineChart extends StatefulWidget {
  final List<LineSeries> series;
  final List<String> xLabels;
  final double? yMax;
  final double height;
  final bool showLegend;

  const MultiLineChart({
    super.key,
    required this.series,
    required this.xLabels,
    this.yMax,
    this.height = 240,
    this.showLegend = true,
  });

  @override
  State<MultiLineChart> createState() => _MultiLineChartState();
}

class _MultiLineChartState extends State<MultiLineChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _progress = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant MultiLineChart old) {
    super.didUpdateWidget(old);
    // Replay if the data changed.
    if (old.series != widget.series) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveYMax = widget.yMax ?? _autoYMax();

    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: AnimatedBuilder(
            animation: _progress,
            builder: (context, _) {
              final t = _progress.value; // 0 → 1

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
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: effectiveYMax / 4,
                        getTitlesWidget: _yLabel,
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
                  lineBarsData: widget.series.map((s) {
                    return _toLineBarData(s, t);
                  }).toList(),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => Colors.black87,
                      getTooltipItems: (spots) {
                        return spots.map((spot) {
                          final s = widget.series[spot.barIndex];
                          return LineTooltipItem(
                            '${s.name}: ${spot.y.toStringAsFixed(0)}',
                            TextStyle(
                              fontFamily: FontConst().fontFamily,
                              color: s.color,
                              fontWeight: FontConst().semiBoldFont,
                              fontSize: 11,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
                // fl_chart's own swap animation for data changes
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              );
            },
          ),
        ),
        if (widget.showLegend) ...[
          const Gap(12),
          // Fade the legend in too.
          FadeTransition(
            opacity: _progress,
            child: Wrap(
              spacing: 14,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: widget.series.map(_legendItem).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _legendItem(LineSeries s) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 16, height: 2, color: s.color),
        const Gap(4),
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
        ),
        const Gap(4),
        Container(width: 16, height: 2, color: s.color),
        const Gap(6),
        KStyles().med(text: s.name, size: 11, color: s.color),
      ],
    );
  }

  Widget _yLabel(double value, TitleMeta meta) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: KStyles().reg(
        text: value.toInt().toString(),
        size: 10,
        color: DashboardColors.chartAxisLabel,
      ),
    );
  }

  /// Build a LineChartBarData with values scaled by `t` (0→1) for entry anim.
  /// At t=0 every point sits at y=0. At t=1 they're at their real value.
  LineChartBarData _toLineBarData(LineSeries s, double t) {
    return LineChartBarData(
      spots: List.generate(
        s.values.length,
        (i) => FlSpot(i.toDouble(), s.values[i] * t),
      ),
      isCurved: true,
      curveSmoothness: 0.3,
      color: s.color,
      barWidth: 2.5,
      dotData: FlDotData(
        show: true,
        // Dots fade in toward the end of the animation
        getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
          radius: 4 * t,
          color: s.color,
          strokeWidth: 2 * t,
          strokeColor: Colors.white,
        ),
      ),
    );
  }

  double _autoYMax() {
    double maxVal = 0;
    for (final s in widget.series) {
      for (final v in s.values) {
        if (v > maxVal) maxVal = v;
      }
    }
    if (maxVal <= 0) return 100;
    final magnitude = _magnitude(maxVal);
    final niceTop = ((maxVal / magnitude).ceil() + 1) * magnitude;
    return niceTop.toDouble();
  }

  double _magnitude(double v) {
    if (v < 10) return 1;
    if (v < 100) return 10;
    if (v < 1000) return 100;
    if (v < 10000) return 1000;
    return 10000;
  }
}
