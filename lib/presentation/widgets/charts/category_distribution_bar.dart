import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../data/models/store_data.dart';

/// Horizontal stacked-bar showing category share with inline percent labels.
class CategoryDistributionBar extends StatelessWidget {
  final List<CategorySlice> categories;
  final List<List<Color>> gradients;

  const CategoryDistributionBar({
    super.key,
    required this.categories,
    this.gradients = const [
      [Color(0xFF534AB7), Color(0xFF7F77DD)],
      [Color(0xFF1D9E75), Color(0xFF5DCAA5)],
      [Color(0xFFEF9F27), Color(0xFFFAC775)],
    ],
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 32,
        child: Row(
          children: List.generate(categories.length, (i) {
            final c = categories[i];
            final g = gradients[i % gradients.length];
            return Expanded(
              flex: c.percent.round(),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: g,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                alignment: Alignment.center,
                child: KStyles().semiBold(
                  text: '${c.percent.toStringAsFixed(0)}%',
                  size: 14,
                  color: AppColors.white,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
