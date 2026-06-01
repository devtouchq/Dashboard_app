import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/section_theme.dart';
import '../../../core/constants/text_styles.dart';

class BarGroup {
  final String label;
  final List<double> values;
  final Color? colorOverride;

  const BarGroup({
    required this.label,
    required this.values,
    this.colorOverride,
  });
}

class BarChartWidget extends StatefulWidget {
  final List<BarGroup> groups;
  final List<Color> barColors;
  final double barWidth;
  final double height;
  final double rotateLabels;

  const BarChartWidget({
    super.key,
    required this.groups,
    required this.barColors,
    this.barWidth = 14,
    this.height = 220,
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
    _progress =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant BarChartWidget old) {
    super.didUpdateWidget(old);
    if (old.groups != widget.groups) {
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
    if (widget.groups.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: KStyles().reg(
            text: 'No data',
            size: 12,
            color: DashboardColors.textOnDarkMuted,
          ),
        ),
      );
    }

    double maxVal = 0;
    for (final g in widget.groups) {
      for (final v in g.values) {
        if (v > maxVal) maxVal = v;
      }
    }
    final maxY = maxVal == 0 ? 1.0 : maxVal * 1.15;

    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _progress,
        builder: (context, _) {
          return BarChart(
            BarChartData(
              maxY: maxY,
              minY: 0,
              alignment: BarChartAlignment.spaceAround,
              barGroups: _buildGroups(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 4,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: Colors.white.withValues(alpha: 0.06),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                show: true,
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 38,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= widget.groups.length) {
                        return const SizedBox.shrink();
                      }
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        space: 6,
                        child: Transform.rotate(
                          angle: widget.rotateLabels,
                          child: KStyles().reg(
                            text: widget.groups[i].label,
                            size: 10,
                            color: DashboardColors.textOnDarkSecondary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 34,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const SizedBox.shrink();
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        space: 4,
                        child: KStyles().reg(
                          text: _formatAxis(value),
                          size: 9,
                          color: DashboardColors.textOnDarkMuted,
                        ),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  // fl_chart 0.69.2 uses getTooltipColor (function form)
                  getTooltipColor: (_) => const Color(0xFF1F2937),
                  getTooltipItem: (group, _, rod, __) {
                    return BarTooltipItem(
                      rod.toY.toStringAsFixed(0),
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<BarChartGroupData> _buildGroups() {
    return List.generate(widget.groups.length, (gi) {
      final g = widget.groups[gi];
      final rods = List.generate(g.values.length, (si) {
        final start = (gi / widget.groups.length) * 0.4;
        final localT = ((_progress.value - start) / 0.6).clamp(0.0, 1.0);
        final v = g.values[si] * localT;

        final color =
            g.colorOverride ?? widget.barColors[si % widget.barColors.length];

        return BarChartRodData(
          toY: v,
          width: widget.barWidth,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          color: color,
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [color.withValues(alpha: 0.7), color],
          ),
        );
      });

      return BarChartGroupData(
        x: gi,
        barRods: rods,
        barsSpace: 4,
      );
    });
  }

  String _formatAxis(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}k';
    return value.toStringAsFixed(0);
  }
}
