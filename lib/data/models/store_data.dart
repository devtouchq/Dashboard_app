import 'package:equatable/equatable.dart';

class CategorySlice extends Equatable {
  final String name; // Medicines / Surgical / Equipment
  final double amount;
  final double percent;

  const CategorySlice({
    required this.name,
    required this.amount,
    required this.percent,
  });

  CategorySlice copyWith({String? name, double? amount, double? percent}) {
    return CategorySlice(
      name: name ?? this.name,
      amount: amount ?? this.amount,
      percent: percent ?? this.percent,
    );
  }

  @override
  List<Object?> get props => [name, amount, percent];
}

class StoreData extends Equatable {
  final double totalCollection;
  final double trendChangePercent;
  final double purchase;
  final double revenue;
  final double collection;
  final double payments;
  final List<CategorySlice> categories;

  const StoreData({
    required this.totalCollection,
    required this.trendChangePercent,
    required this.purchase,
    required this.revenue,
    required this.collection,
    required this.payments,
    required this.categories,
  });

  StoreData copyWith({
    double? totalCollection,
    double? trendChangePercent,
    double? purchase,
    double? revenue,
    double? collection,
    double? payments,
    List<CategorySlice>? categories,
  }) {
    return StoreData(
      totalCollection: totalCollection ?? this.totalCollection,
      trendChangePercent: trendChangePercent ?? this.trendChangePercent,
      purchase: purchase ?? this.purchase,
      revenue: revenue ?? this.revenue,
      collection: collection ?? this.collection,
      payments: payments ?? this.payments,
      categories: categories ?? this.categories,
    );
  }

  @override
  List<Object?> get props => [
        totalCollection,
        trendChangePercent,
        purchase,
        revenue,
        collection,
        payments,
        categories,
      ];
}
