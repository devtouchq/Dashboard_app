import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:graphic/graphic.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/font_styles.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/models/emr_data.dart';

/// Vertical bar chart for the Patient Flow card on the EMR screen.
class PatientFlowBarChart extends StatelessWidget {
  final List<PatientFlowItem> items;
  final double height;

  const PatientFlowBarChart({
    super.key,
    required this.items,
    this.height = 140,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      AppLogger.info('PatientFlowChart', 'No items to plot');
      return _emptyState();
    }

    final total = items.fold<int>(0, (sum, e) => sum + e.value);
    if (total <= 0) {
      AppLogger.info(
          'PatientFlowChart', 'All values zero, rendering empty bars');
      return _zeroBars();
    }

    final data =
        items.map((e) => {'label': e.label, 'value': e.value}).toList();

    final colors = [
      AppColors.storeColor,
      AppColors.accountsColor,
      AppColors.chartAmber,
      AppColors.chartTeal,
      AppColors.emrColor,
    ];

    return SizedBox(
      height: height,
      child: Chart(
        data: data,
        variables: {
          'label': Variable(
            accessor: (Map row) => row['label'] as String,
          ),
          'value': Variable(
            accessor: (Map row) => (row['value'] as int).toDouble(),
          ),
        },
        marks: [
          IntervalMark(
            color: ColorEncode(variable: 'label', values: colors),
            shape: ShapeEncode(
              value: RectShape(borderRadius: BorderRadius.circular(6)),
            ),
            label: LabelEncode(
              encoder: (tuple) => Label(
                tuple['value'].toString(),
                LabelStyle(
                  textStyle: TextStyle(
                    fontFamily: FontConst().fontFamily,
                    fontSize: 10,
                    fontWeight: FontConst().semiBoldFont,
                    color: AppColors.textPrimary,
                  ),
                  align: Alignment.topCenter,
                  offset: const Offset(0, -8),
                ),
              ),
            ),
          ),
        ],
        axes: [
          Defaults.horizontalAxis
            ..label = LabelStyle(
              textStyle: TextStyle(
                fontFamily: FontConst().fontFamily,
                fontWeight: FontConst().regularFont,
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          Defaults.verticalAxis
            ..label = null
            ..grid = PaintStyle(strokeColor: AppColors.dividerColor),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      height: height,
      alignment: Alignment.center,
      child: KStyles().reg(
        text: 'No data',
        size: 10,
        color: AppColors.textMuted,
      ),
    );
  }

  Widget _zeroBars() {
    return SizedBox(
      height: height,
      child: Column(
        children: [
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: items
                .map((e) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        KStyles().semiBold(
                          text: '0',
                          size: 10,
                          color: AppColors.textPrimary,
                        ),
                        const Gap(2),
                        Container(
                          width: 28,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.borderColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ))
                .toList(),
          ),
          const Gap(6),
          Container(height: 1, color: AppColors.dividerColor),
          const Gap(6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: items
                .map((e) => KStyles().reg(
                      text: e.label,
                      size: 9,
                      color: AppColors.textSecondary,
                    ))
                .toList(),
          ),
          const Gap(4),
        ],
      ),
    );
  }
}
