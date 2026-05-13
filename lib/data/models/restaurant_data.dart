import 'package:equatable/equatable.dart';

class RestaurantData extends Equatable {
  final int dailyOrders;
  final int customers;
  final double revenue;
  final List<WeeklySalesPoint> weeklySales;
  final List<CategorySalesSlice> salesByCategory;

  const RestaurantData({
    required this.dailyOrders,
    required this.customers,
    required this.revenue,
    required this.weeklySales,
    required this.salesByCategory,
  });

  RestaurantData copyWith({
    int? dailyOrders,
    int? customers,
    double? revenue,
    List<WeeklySalesPoint>? weeklySales,
    List<CategorySalesSlice>? salesByCategory,
  }) {
    return RestaurantData(
      dailyOrders: dailyOrders ?? this.dailyOrders,
      customers: customers ?? this.customers,
      revenue: revenue ?? this.revenue,
      weeklySales: weeklySales ?? this.weeklySales,
      salesByCategory: salesByCategory ?? this.salesByCategory,
    );
  }

  @override
  List<Object?> get props =>
      [dailyOrders, customers, revenue, weeklySales, salesByCategory];
}

class WeeklySalesPoint extends Equatable {
  final String day;
  final double sales;
  const WeeklySalesPoint({required this.day, required this.sales});
  @override
  List<Object?> get props => [day, sales];
}

class CategorySalesSlice extends Equatable {
  final String label;
  final double percent;
  const CategorySalesSlice({required this.label, required this.percent});
  @override
  List<Object?> get props => [label, percent];
}
