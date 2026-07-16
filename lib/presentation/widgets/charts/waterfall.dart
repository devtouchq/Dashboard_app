// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter/material.dart';
// import 'package:gap/gap.dart';

// import '../../../core/constants/section_theme.dart';
// import '../../../core/constants/text_styles.dart';
// import '../../../core/utils/currency_utils.dart';

// /// One step in the waterfall — a single section's contribution.
// class WaterfallStep {
//   final String label;
//   final double value; // positive = gain (goes up), negative = loss (goes down)
//   final Color? colorOverride;

//   const WaterfallStep({
//     required this.label,
//     required this.value,
//     this.colorOverride,
//   });
// }

// /// Waterfall chart showing how each section's revenue adds up (or subtracts)
// /// to reach a final total.
// ///
// /// - Positive sections → green floating bars going UP from the previous total
// /// - Negative sections → red floating bars going DOWN from the previous total
// /// - Final "Total" bar → grounded from 0 to the net result
// /// - Sort order: biggest gains first, then biggest losses, then Total.
// ///
// /// This tells a clean story: "these are the wins, these are the losses,
// /// and this is the net."
// class WaterfallChartWidget extends StatefulWidget {
//   final List<WaterfallStep> steps;
//   final String currency;
//   final Color positiveColor;
//   final Color negativeColor;
//   final Color totalColor;
//   final double height;
//   final double barWidth;
//   final double rotateLabels;
//   final String totalLabel;

//   /// If true, sort steps: biggest positive → smallest positive →
//   /// biggest negative (by absolute value) → smallest negative.
//   /// If false, uses input order.
//   final bool sortByImpact;

//   const WaterfallChartWidget({
//     super.key,
//     required this.steps,
//     required this.currency,
//     this.positiveColor = const Color(0xFF4ADE80),
//     this.negativeColor = const Color(0xFFEF4444),
//     this.totalColor = const Color(0xFF60A5FA),
//     this.height = 320,
//     this.barWidth = 22,
//     this.rotateLabels = -0.5,
//     this.totalLabel = 'Total',
//     this.sortByImpact = true,
//   });

//   @override
//   State<WaterfallChartWidget> createState() => _WaterfallChartWidgetState();
// }

// class _WaterfallChartWidgetState extends State<WaterfallChartWidget>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _progress;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1400),
//     );
//     _progress =
//         CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
//     _controller.forward();
//   }

//   @override
//   void didUpdateWidget(covariant WaterfallChartWidget old) {
//     super.didUpdateWidget(old);
//     if (old.steps != widget.steps) {
//       _controller.forward(from: 0);
//     }
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Filter out zero-value steps — they'd render as invisible bars anyway.
//     final filtered =
//         widget.steps.where((s) => s.value != 0).toList(growable: false);

//     if (filtered.isEmpty) {
//       return SizedBox(
//         height: widget.height,
//         child: Center(
//           child: KStyles().reg(
//             text: 'No data',
//             size: 12,
//             color: DashboardColors.textOnDarkMuted,
//           ),
//         ),
//       );
//     }

//     // Sort: biggest positive → smallest positive → biggest negative (|v|) →
//     // smallest negative. This groups gains before losses, biggest impact first.
//     final sorted =
//         widget.sortByImpact ? _sortedByImpact(filtered) : filtered.toList();

//     // Compute the running cumulative sum and track min/max for y-axis.
//     // We also record each step's (fromY, toY) so building rods is trivial.
//     final positions = <_StepPosition>[];
//     double running = 0;
//     double minCum = 0;
//     double maxCum = 0;
//     for (final step in sorted) {
//       final from = running;
//       final to = running + step.value;
//       positions.add(_StepPosition(step: step, fromY: from, toY: to));
//       running = to;
//       if (running < minCum) minCum = running;
//       if (running > maxCum) maxCum = running;
//     }

//     final finalTotal = running;
//     // The Total bar starts at 0 and ends at the finalTotal.
//     if (finalTotal > maxCum) maxCum = finalTotal;
//     if (finalTotal < minCum) minCum = finalTotal;

//     // Y-axis padding.
//     final range = (maxCum - minCum);
//     final pad = range == 0 ? 1.0 : range * 0.15;
//     final minY = minCum - pad;
//     final maxY = maxCum + pad;

//     // Total bars = section steps + 1 for the Total column.
//     final totalBars = positions.length + 1;

//     return SizedBox(
//       height: widget.height,
//       child: AnimatedBuilder(
//         animation: _progress,
//         builder: (context, _) {
//           return BarChart(
//             BarChartData(
//               maxY: maxY,
//               minY: minY,
//               alignment: BarChartAlignment.spaceAround,
//               barGroups: _buildGroups(positions, finalTotal, totalBars),
//               gridData: FlGridData(
//                 show: true,
//                 drawVerticalLine: false,
//                 horizontalInterval: (maxY - minY) / 4,
//                 getDrawingHorizontalLine: (_) => FlLine(
//                   color: Colors.white.withValues(alpha: 0.06),
//                   strokeWidth: 1,
//                 ),
//               ),
//               // Solid line at y = 0 so the baseline is obvious even
//               // when there's both up-going and down-going bars.
//               extraLinesData: ExtraLinesData(
//                 horizontalLines: [
//                   HorizontalLine(
//                     y: 0,
//                     color: Colors.white.withValues(alpha: 0.28),
//                     strokeWidth: 1,
//                   ),
//                 ],
//               ),
//               borderData: FlBorderData(show: false),
//               titlesData: FlTitlesData(
//                 show: true,
//                 topTitles:
//                     const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                 rightTitles:
//                     const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                 bottomTitles: AxisTitles(
//                   sideTitles: SideTitles(
//                     showTitles: true,
//                     reservedSize: 44,
//                     getTitlesWidget: (value, meta) {
//                       final i = value.toInt();
//                       if (i < 0 || i >= totalBars) {
//                         return const SizedBox.shrink();
//                       }
//                       final label = i < positions.length
//                           ? positions[i].step.label
//                           : widget.totalLabel;
//                       return SideTitleWidget(
//                         axisSide: meta.axisSide,
//                         space: 6,
//                         child: Transform.rotate(
//                           angle: widget.rotateLabels,
//                           child: KStyles().reg(
//                             text: label,
//                             size: 10,
//                             color: DashboardColors.textOnDarkSecondary,
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//                 leftTitles: AxisTitles(
//                   sideTitles: SideTitles(
//                     showTitles: true,
//                     reservedSize: 46,
//                     getTitlesWidget: (value, meta) {
//                       if (value == 0) return const SizedBox.shrink();
//                       return SideTitleWidget(
//                         axisSide: meta.axisSide,
//                         space: 4,
//                         child: KStyles().reg(
//                           text: _formatAxis(value),
//                           size: 9,
//                           color: DashboardColors.textOnDarkMuted,
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               ),
//               barTouchData: BarTouchData(
//                 touchTooltipData: BarTouchTooltipData(
//                   getTooltipColor: (_) => const Color(0xFF1F2937),
//                   getTooltipItem: (group, groupIdx, rod, rodIdx) {
//                     // Show the delta for step bars, total for the Total bar.
//                     if (groupIdx < positions.length) {
//                       final step = positions[groupIdx].step;
//                       final sign = step.value >= 0 ? '+' : '';
//                       return BarTooltipItem(
//                         '${step.label}\n$sign${CurrencyUtils.format(step.value, widget.currency)}',
//                         const TextStyle(
//                           color: Colors.white,
//                           fontSize: 11,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       );
//                     }
//                     // Total bar
//                     return BarTooltipItem(
//                       '${widget.totalLabel}\n${CurrencyUtils.format(finalTotal, widget.currency)}',
//                       const TextStyle(
//                         color: Colors.white,
//                         fontSize: 11,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   /// Sort steps: positives descending, then negatives descending by |value|.
//   List<WaterfallStep> _sortedByImpact(List<WaterfallStep> input) {
//     final positives = input.where((s) => s.value > 0).toList()
//       ..sort((a, b) => b.value.compareTo(a.value));
//     final negatives = input.where((s) => s.value < 0).toList()
//       ..sort((a, b) => a.value.compareTo(b.value)); // most negative first
//     return [...positives, ...negatives];
//   }

//   List<BarChartGroupData> _buildGroups(
//       List<_StepPosition> positions, double finalTotal, int totalBars) {
//     final groups = <BarChartGroupData>[];

//     // Step bars — animate reveal left-to-right with slight stagger.
//     for (var i = 0; i < positions.length; i++) {
//       final p = positions[i];
//       final start = (i / totalBars) * 0.6;
//       final localT = ((_progress.value - start) / 0.5).clamp(0.0, 1.0);

//       // Interpolate the toY from fromY (start) toward the actual value.
//       final animatedTo = p.fromY + (p.toY - p.fromY) * localT;

//       final isNegative = p.step.value < 0;
//       final color = p.step.colorOverride ??
//           (isNegative ? widget.negativeColor : widget.positiveColor);

//       groups.add(BarChartGroupData(
//         x: i,
//         barsSpace: 4,
//         barRods: [
//           BarChartRodData(
//             fromY: p.fromY,
//             toY: animatedTo,
//             width: widget.barWidth,
//             borderRadius: BorderRadius.circular(3),
//             color: color,
//             gradient: LinearGradient(
//               begin: isNegative ? Alignment.topCenter : Alignment.bottomCenter,
//               end: isNegative ? Alignment.bottomCenter : Alignment.topCenter,
//               colors: [color.withValues(alpha: 0.7), color],
//             ),
//           ),
//         ],
//       ));
//     }

//     // Total bar — starts from 0 (grounded), reveals last.
//     final totalIdx = positions.length;
//     final start = (totalIdx / totalBars) * 0.6;
//     final localT = ((_progress.value - start) / 0.5).clamp(0.0, 1.0);
//     final animatedTotal = finalTotal * localT;

//     final totalIsNegative = finalTotal < 0;
//     final totalColor =
//         totalIsNegative ? widget.negativeColor : widget.totalColor;

//     groups.add(BarChartGroupData(
//       x: totalIdx,
//       barsSpace: 4,
//       barRods: [
//         BarChartRodData(
//           fromY: 0,
//           toY: animatedTotal,
//           width: widget.barWidth,
//           borderRadius: totalIsNegative
//               ? const BorderRadius.vertical(bottom: Radius.circular(3))
//               : const BorderRadius.vertical(top: Radius.circular(3)),
//           color: totalColor,
//           gradient: LinearGradient(
//             begin:
//                 totalIsNegative ? Alignment.topCenter : Alignment.bottomCenter,
//             end: totalIsNegative ? Alignment.bottomCenter : Alignment.topCenter,
//             colors: [totalColor.withValues(alpha: 0.7), totalColor],
//           ),
//         ),
//       ],
//     ));

//     return groups;
//   }

//   String _formatAxis(double value) {
//     final abs = value.abs();
//     final sign = value < 0 ? '-' : '';
//     if (abs >= 1000000) return '$sign${(abs / 1000000).toStringAsFixed(1)}M';
//     if (abs >= 1000) return '$sign${(abs / 1000).toStringAsFixed(0)}k';
//     return '$sign${abs.toStringAsFixed(0)}';
//   }
// }

// /// Legend widget you can place under the chart to explain the colors.
// class WaterfallLegend extends StatelessWidget {
//   final Color positiveColor;
//   final Color negativeColor;
//   final Color totalColor;
//   final String totalLabel;

//   const WaterfallLegend({
//     super.key,
//     this.positiveColor = const Color(0xFF4ADE80),
//     this.negativeColor = const Color(0xFFEF4444),
//     this.totalColor = const Color(0xFF60A5FA),
//     this.totalLabel = 'Total',
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Wrap(
//       spacing: 16,
//       runSpacing: 6,
//       alignment: WrapAlignment.center,
//       children: [
//         _legendItem(positiveColor, 'Gains'),
//         _legendItem(negativeColor, 'Losses'),
//         _legendItem(totalColor, totalLabel),
//       ],
//     );
//   }

//   Widget _legendItem(Color color, String label) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Container(
//           width: 10,
//           height: 10,
//           decoration: BoxDecoration(
//             color: color,
//             borderRadius: BorderRadius.circular(2),
//           ),
//         ),
//         const Gap(6),
//         KStyles().reg(
//           text: label,
//           size: 11,
//           color: DashboardColors.textOnDarkSecondary,
//         ),
//       ],
//     );
//   }
// }

// /// Internal — precomputed position of a single step (used for building
// /// bars and looking up hover/tooltip info).
// class _StepPosition {
//   final WaterfallStep step;
//   final double fromY;
//   final double toY;

//   _StepPosition({
//     required this.step,
//     required this.fromY,
//     required this.toY,
//   });
// }
