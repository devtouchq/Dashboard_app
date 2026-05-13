import 'package:equatable/equatable.dart';

class StoreData extends Equatable {
  final int totalItems;
  final int lowStock;
  final int orders;
  final List<CategoryInventory> inventoryByCategory;
  final List<MonthlySalesPoint> monthlySales;

  const StoreData({
    required this.totalItems,
    required this.lowStock,
    required this.orders,
    required this.inventoryByCategory,
    required this.monthlySales,
  });

  StoreData copyWith({
    int? totalItems,
    int? lowStock,
    int? orders,
    List<CategoryInventory>? inventoryByCategory,
    List<MonthlySalesPoint>? monthlySales,
  }) {
    return StoreData(
      totalItems: totalItems ?? this.totalItems,
      lowStock: lowStock ?? this.lowStock,
      orders: orders ?? this.orders,
      inventoryByCategory: inventoryByCategory ?? this.inventoryByCategory,
      monthlySales: monthlySales ?? this.monthlySales,
    );
  }

  @override
  List<Object?> get props =>
      [totalItems, lowStock, orders, inventoryByCategory, monthlySales];
}

class CategoryInventory extends Equatable {
  final String category;
  final double inStock;
  final double sold;

  const CategoryInventory({
    required this.category,
    required this.inStock,
    required this.sold,
  });

  @override
  List<Object?> get props => [category, inStock, sold];
}

class MonthlySalesPoint extends Equatable {
  final String month;
  final double sales;

  const MonthlySalesPoint({required this.month, required this.sales});

  @override
  List<Object?> get props => [month, sales];
}
