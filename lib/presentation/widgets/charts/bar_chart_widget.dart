import 'dart:math' as math;

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

  /// Color used for bars whose value is negative.
  final Color negativeColor;

  const BarChartWidget({
    super.key,
    required this.groups,
    required this.barColors,
    this.barWidth = 14,
    this.height = 220,
    this.rotateLabels = 0,
    this.negativeColor = const Color(0xFFEF4444),
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

    // Scan for BOTH positive max and negative min.
    double maxPos = 0;
    double minNeg = 0;
    for (final g in widget.groups) {
      for (final v in g.values) {
        if (v > maxPos) maxPos = v;
        if (v < minNeg) minNeg = v;
      }
    }

    // Compute "nice" axis bounds — snaps to human-friendly round numbers
    // (100, 500, 1k, 5k, etc.) so labels are like 3.0M/3.5M/4.0M/4.5M,
    // never like 3.07M/4.09M that overlap and look messy.
    final bounds = _niceBounds(minNeg, maxPos);
    final maxY = bounds.maxY;
    final minY = bounds.minY;
    final interval = bounds.interval;

    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _progress,
        builder: (context, _) {
          return BarChart(
            BarChartData(
              maxY: maxY,
              minY: minY,
              alignment: BarChartAlignment.spaceAround,
              barGroups: _buildGroups(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: interval,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: Colors.white.withValues(alpha: 0.06),
                  strokeWidth: 1,
                ),
              ),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: 0,
                    color: Colors.white.withValues(alpha: 0.28),
                    strokeWidth: 1,
                  ),
                ],
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
                    reservedSize: 46,
                    // Force the interval so fl_chart doesn't add extra ticks
                    // near the axis top/bottom that cause label overlap.
                    interval: interval,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const SizedBox.shrink();
                      // Only show labels at our computed grid positions.
                      // fl_chart sometimes calls this at maxY too, causing
                      // the "4.0M vs 4.1M" overlap. Skip anything not on grid.
                      final rem = value.abs() % interval;
                      final tolerance = interval * 0.01;
                      if (rem > tolerance && (interval - rem) > tolerance) {
                        return const SizedBox.shrink();
                      }
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

        final rawValue = g.values[si];
        final v = rawValue * localT;

        final isNegative = rawValue < 0;
        final color = isNegative
            ? widget.negativeColor
            : (g.colorOverride ??
                widget.barColors[si % widget.barColors.length]);

        final borderRadius = isNegative
            ? const BorderRadius.vertical(bottom: Radius.circular(4))
            : const BorderRadius.vertical(top: Radius.circular(4));

        return BarChartRodData(
          toY: v,
          width: widget.barWidth,
          borderRadius: borderRadius,
          color: color,
          gradient: LinearGradient(
            begin: isNegative ? Alignment.topCenter : Alignment.bottomCenter,
            end: isNegative ? Alignment.bottomCenter : Alignment.topCenter,
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

  /// Compute human-friendly axis bounds and a grid interval that snaps
  /// to a round number. Prevents the "4.0M / 4.1M overlap" issue caused
  /// by using the raw data range with 15% padding.
  ///
  /// Examples:
  ///   min=0, max=3,556,357 → minY=0, maxY=4,000,000, interval=1,000,000
  ///   min=-360, max=598,125 → minY=-100,000, maxY=800,000, interval=200,000
  _NiceAxisBounds _niceBounds(double minVal, double maxVal) {
    // Nothing to plot — degenerate case.
    if (minVal == 0 && maxVal == 0) {
      return _NiceAxisBounds(minY: 0, maxY: 1, interval: 0.25);
    }

    // Target ~4 grid lines.
    final range = maxVal - minVal;
    final targetInterval = range / 4;

    // Round targetInterval up to a "nice" number: 1×10ⁿ, 2×10ⁿ, or 5×10ⁿ.
    final niceInterval = _niceCeil(targetInterval);

    // Snap max UP to the next multiple of niceInterval, min DOWN.
    final niceMax = (maxVal / niceInterval).ceil() * niceInterval;
    final niceMin = minVal >= 0
        ? 0.0
        : (minVal / niceInterval).floor() * niceInterval.toDouble();

    return _NiceAxisBounds(
      minY: niceMin.toDouble(),
      maxY: niceMax.toDouble(),
      interval: niceInterval,
    );
  }

  /// Rounds x UP to the nearest "nice" number of the form
  /// {1, 2, 5} × 10ⁿ. E.g. 823 → 1000, 2317 → 5000, 890000 → 1000000.
  double _niceCeil(double x) {
    if (x <= 0) return 1;
    final exp = (math.log(x) / math.ln10).floor();
    final magnitude = math.pow(10, exp).toDouble();
    final normalized = x / magnitude;
    double nice;
    if (normalized <= 1) {
      nice = 1;
    } else if (normalized <= 2) {
      nice = 2;
    } else if (normalized <= 5) {
      nice = 5;
    } else {
      nice = 10;
    }
    return nice * magnitude;
  }

  String _formatAxis(double value) {
    final abs = value.abs();
    final sign = value < 0 ? '-' : '';
    if (abs >= 1000000) {
      final m = abs / 1000000;
      // Show one decimal only when it's meaningful (e.g. 3.5M, not 4.0M).
      return m == m.roundToDouble()
          ? '$sign${m.toStringAsFixed(0)}M'
          : '$sign${m.toStringAsFixed(1)}M';
    }
    if (abs >= 1000) return '$sign${(abs / 1000).toStringAsFixed(0)}k';
    return '$sign${abs.toStringAsFixed(0)}';
  }
}

class _NiceAxisBounds {
  final double minY;
  final double maxY;
  final double interval;

  const _NiceAxisBounds({
    required this.minY,
    required this.maxY,
    required this.interval,
  });
}
