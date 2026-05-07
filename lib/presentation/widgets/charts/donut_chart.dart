import 'package:flutter/material.dart';
import 'package:graphic/graphic.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/app_logger.dart';

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

class DonutChart extends StatelessWidget {
  final List<DonutSlice> slices;
  final String centerText;
  final String centerSubText;
  final double size;

  const DonutChart({
    super.key,
    required this.slices,
    required this.centerText,
    required this.centerSubText,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    final total = slices.fold<double>(0, (sum, s) => sum + s.value);

    if (slices.isEmpty || total <= 0) {
      AppLogger.info(
        'DonutChart',
        'No data (slices=${slices.length}, total=$total). Showing empty ring.',
      );
      return _emptyRing();
    }

    final renderSlices = slices.length == 1
        ? [
            slices.first,
            const DonutSlice(
              label: '_pad',
              value: 0.0001,
              color: AppColors.transparent,
            ),
          ]
        : slices;

    final data =
        renderSlices.map((s) => {'label': s.label, 'value': s.value}).toList();
    final colors = renderSlices.map((s) => s.color).toList();

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Chart(
            data: data,
            variables: {
              'label': Variable(
                accessor: (Map row) => row['label'] as String,
              ),
              'value': Variable(
                accessor: (Map row) => row['value'] as num,
              ),
            },
            transforms: [
              Proportion(variable: 'value', as: 'percent'),
            ],
            marks: [
              IntervalMark(
                position: Varset('percent') / Varset('label'),
                color: ColorEncode(variable: 'label', values: colors),
                modifiers: [StackModifier()],
              ),
            ],
            coord: PolarCoord(transposed: true, dimCount: 1, startRadius: 0.7),
          ),
          _centerText(),
        ],
      ),
    );
  }

  Widget _emptyRing() {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.borderColor,
                width: size * 0.15,
              ),
            ),
          ),
          _centerText(),
        ],
      ),
    );
  }

  Widget _centerText() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        KStyles().bold(
          text: centerText,
          size: 14,
          color: AppColors.textPrimary,
        ),
        KStyles().reg(
          text: centerSubText,
          size: 9,
          color: AppColors.textSecondary,
        ),
      ],
    );
  }
}
