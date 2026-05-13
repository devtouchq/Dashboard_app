import 'package:equatable/equatable.dart';

class BarData extends Equatable {
  final int totalProducts;
  final double dailySales;
  final int orders;
  final List<WeeklyRevenuePoint> weeklyRevenue;
  final List<ProductMixSlice> productMix;

  const BarData({
    required this.totalProducts,
    required this.dailySales,
    required this.orders,
    required this.weeklyRevenue,
    required this.productMix,
  });

  BarData copyWith({
    int? totalProducts,
    double? dailySales,
    int? orders,
    List<WeeklyRevenuePoint>? weeklyRevenue,
    List<ProductMixSlice>? productMix,
  }) {
    return BarData(
      totalProducts: totalProducts ?? this.totalProducts,
      dailySales: dailySales ?? this.dailySales,
      orders: orders ?? this.orders,
      weeklyRevenue: weeklyRevenue ?? this.weeklyRevenue,
      productMix: productMix ?? this.productMix,
    );
  }

  @override
  List<Object?> get props =>
      [totalProducts, dailySales, orders, weeklyRevenue, productMix];
}

class WeeklyRevenuePoint extends Equatable {
  final String day;
  final double revenue;

  const WeeklyRevenuePoint({required this.day, required this.revenue});

  @override
  List<Object?> get props => [day, revenue];
}

class ProductMixSlice extends Equatable {
  final String label;
  final double percent;

  const ProductMixSlice({required this.label, required this.percent});

  @override
  List<Object?> get props => [label, percent];
}
