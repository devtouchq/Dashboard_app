import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/section_theme.dart';
import '../../../core/constants/text_styles.dart';

class PieSlice {
  final String label;
  final double value;
  final Color color;
  const PieSlice({
    required this.label,
    required this.value,
    required this.color,
  });
}

class PieChartWidget extends StatefulWidget {
  final List<PieSlice> slices;
  final double size;
  final bool donut;
  final bool showPercentLabels;
  final bool showLegendValues;

  const PieChartWidget({
    super.key,
    required this.slices,
    this.size = 180,
    this.donut = false,
    this.showPercentLabels = true,
    this.showLegendValues = true,
  });

  @override
  State<PieChartWidget> createState() => _PieChartWidgetState();
}

class _PieChartWidgetState extends State<PieChartWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _progress =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant PieChartWidget old) {
    super.didUpdateWidget(old);
    if (old.slices != widget.slices) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.slices.fold<double>(0, (sum, s) => sum + s.value);
    if (widget.slices.isEmpty || total <= 0) return _empty();

    return Column(
      children: [
        SizedBox(
          height: widget.size,
          child: AnimatedBuilder(
            animation: _progress,
            builder: (context, _) {
              final t = _progress.value;
              final radiusOuter =
                  widget.donut ? widget.size * 0.28 : widget.size * 0.5;
              return PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: widget.donut ? widget.size * 0.22 : 0,
                  // Rotate the pie in as it scales — like it's spinning in place
                  startDegreeOffset: -90 + (360 * (1 - t) * 0.25),
                  sections: widget.slices.map((s) {
                    final pct = (s.value / total) * 100;
                    return PieChartSectionData(
                      value: s.value,
                      color: s.color,
                      radius: radiusOuter * t,
                      title: widget.showPercentLabels && t > 0.7
                          ? '${pct.toStringAsFixed(0)}%'
                          : '',
                      titleStyle: TextStyle(
                        color: Colors.white.withValues(
                            alpha: ((t - 0.7) / 0.3).clamp(0.0, 1.0)),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                      titlePositionPercentageOffset: 0.6,
                    );
                  }).toList(),
                ),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              );
            },
          ),
        ),
        const Gap(14),
        FadeTransition(opacity: _progress, child: _legend(total)),
      ],
    );
  }

  Widget _legend(double total) {
    return Column(
      children: widget.slices.map((s) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: s.color, shape: BoxShape.circle),
              ),
              const Gap(8),
              Expanded(
                child: KStyles().reg(
                  text: s.label,
                  size: 12,
                  color: DashboardColors.textOnDarkSecondary,
                ),
              ),
              if (widget.showLegendValues)
                KStyles().semiBold(
                  text: s.value.toInt().toString(),
                  size: 12,
                  color: DashboardColors.textOnDark,
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _empty() {
    return SizedBox(
      height: widget.size,
      child: Center(
        child: KStyles().reg(
          text: 'No data',
          size: 12,
          color: DashboardColors.textOnDarkMuted,
        ),
      ),
    );
  }
}
