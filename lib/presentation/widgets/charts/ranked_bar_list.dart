import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/section_theme.dart';
import '../../../core/constants/text_styles.dart';

class RankedBarItem {
  final String label;
  final double value;
  final double? previousValue; // optional: dim bar for comparison

  const RankedBarItem({
    required this.label,
    required this.value,
    this.previousValue,
  });
}

/// Leaderboard-style horizontal chart.
/// Optionally shows a dim "previous period" bar behind the bright current bar.
class RankedBarList extends StatefulWidget {
  final List<RankedBarItem> items;
  final Color barColor;
  final double rowHeight;
  final bool showRank;
  final String currentLabel; // legend
  final String previousLabel; // legend

  const RankedBarList({
    super.key,
    required this.items,
    required this.barColor,
    this.rowHeight = 56,
    this.showRank = true,
    this.currentLabel = 'This month',
    this.previousLabel = 'Last month',
  });

  @override
  State<RankedBarList> createState() => _RankedBarListState();
}

class _RankedBarListState extends State<RankedBarList>
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
    _progress =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant RankedBarList old) {
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
    if (widget.items.isEmpty) return const SizedBox.shrink();

    // Scale bars against the highest value of either period so the comparison
    // is meaningful (a doctor whose prev count is huge looks smaller now).
    double maxVal = 0;
    for (final i in widget.items) {
      if (i.value > maxVal) maxVal = i.value;
      if (i.previousValue != null && i.previousValue! > maxVal) {
        maxVal = i.previousValue!;
      }
    }
    final hasPrev = widget.items.any((i) => i.previousValue != null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasPrev) ...[
          _legend(),
          const Gap(8),
        ],
        AnimatedBuilder(
          animation: _progress,
          builder: (context, _) {
            return Column(
              children: List.generate(widget.items.length, (i) {
                final start = (i / widget.items.length) * 0.45;
                final localT =
                    ((_progress.value - start) / 0.55).clamp(0.0, 1.0);
                return _row(i, widget.items[i], maxVal, localT);
              }),
            );
          },
        ),
      ],
    );
  }

  Widget _legend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _legendDot(color: widget.barColor, label: widget.currentLabel),
        const Gap(12),
        _legendDot(
          color: const Color.fromARGB(255, 250, 0, 0).withValues(alpha: 0.4),
          label: widget.previousLabel,
        ),
      ],
    );
  }

  Widget _legendDot({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 6,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const Gap(5),
        KStyles().reg(
          text: label,
          size: 10,
          color: DashboardColors.textOnDarkMuted,
        ),
      ],
    );
  }

  Widget _row(int i, RankedBarItem item, double maxVal, double t) {
    final fillNow = maxVal == 0 ? 0.0 : (item.value / maxVal);
    final fillPrev = (item.previousValue == null || maxVal == 0)
        ? 0.0
        : (item.previousValue! / maxVal);

    // Delta indicator
    final delta = item.previousValue == null
        ? 0
        : (item.value - item.previousValue!).round();
    final hasDelta = item.previousValue != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SizedBox(
        height: widget.rowHeight,
        child: Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Row(
            children: [
              if (widget.showRank) ...[
                _rankBadge(i + 1),
                const Gap(10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: KStyles().semiBold(
                            text: item.label,
                            size: 12,
                            color: DashboardColors.textOnDark,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Gap(8),
                        KStyles().bold(
                          text: item.value.toInt().toString(),
                          size: 13,
                          color: widget.barColor,
                        ),
                        if (hasDelta) ...[
                          const Gap(6),
                          _deltaChip(delta),
                        ],
                      ],
                    ),
                    const Gap(6),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        return SizedBox(
                          height: 16,
                          width: width,
                          child: Stack(
                            children: [
                              // Track
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              // Previous-month bar (dim, drawn first / behind)
                              if (item.previousValue != null)
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: width * fillPrev * t,
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent
                                          .withValues(alpha: 0.4),
                                      // widget.barColor
                                      //     .withValues(alpha: 0.28),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              // Current-month bar (bright, half the height,
                              // centered vertically so the dim bar shows above
                              // and below it like a "shadow").
                              Positioned(
                                left: 0,
                                top: 4,
                                bottom: 4,
                                child: Container(
                                  width: width * fillNow * t,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        widget.barColor.withValues(alpha: 0.9),
                                        widget.barColor,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: widget.barColor
                                            .withValues(alpha: 0.4),
                                        blurRadius: 5,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _deltaChip(int delta) {
    Color bg;
    Color fg;
    IconData icon;
    String text;

    if (delta > 0) {
      bg = const Color(0xFF10B981).withValues(alpha: 0.15);
      fg = const Color(0xFF34D399);
      icon = Icons.arrow_upward_rounded;
      text = '+$delta';
    } else if (delta < 0) {
      bg = const Color(0xFFEF4444).withValues(alpha: 0.15);
      fg = const Color(0xFFF87171);
      icon = Icons.arrow_downward_rounded;
      text = '$delta';
    } else {
      bg = Colors.white.withValues(alpha: 0.08);
      fg = DashboardColors.textOnDarkMuted;
      icon = Icons.remove_rounded;
      text = '0';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const Gap(2),
          KStyles().bold(
            text: text,
            size: 10,
            color: fg,
          ),
        ],
      ),
    );
  }

  Widget _rankBadge(int rank) {
    Color bg;
    Color fg;
    switch (rank) {
      case 1:
        bg = const Color(0xFFFFD700);
        fg = Colors.black;
        break;
      case 2:
        bg = const Color(0xFFC0C0C0);
        fg = Colors.black;
        break;
      case 3:
        bg = const Color(0xFFCD7F32);
        fg = Colors.white;
        break;
      default:
        bg = Colors.white.withValues(alpha: 0.1);
        fg = DashboardColors.textOnDarkSecondary;
    }
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: KStyles().bold(text: '$rank', size: 12, color: fg),
    );
  }
}
