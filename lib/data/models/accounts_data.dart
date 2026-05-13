import 'package:equatable/equatable.dart';

class AccountsData extends Equatable {
  final double totalRevenue;
  final double expenses;
  final double netProfit;
  final double revenueTrendPercent;
  final double expensesTrendPercent;
  final double netProfitTrendPercent;
  final List<MonthlyRevenuePoint> revenueVsExpenses;
  final List<ExpenseSlice> expenseBreakdown;

  const AccountsData({
    required this.totalRevenue,
    required this.expenses,
    required this.netProfit,
    required this.revenueTrendPercent,
    required this.expensesTrendPercent,
    required this.netProfitTrendPercent,
    required this.revenueVsExpenses,
    required this.expenseBreakdown,
  });

  AccountsData copyWith({
    double? totalRevenue,
    double? expenses,
    double? netProfit,
    double? revenueTrendPercent,
    double? expensesTrendPercent,
    double? netProfitTrendPercent,
    List<MonthlyRevenuePoint>? revenueVsExpenses,
    List<ExpenseSlice>? expenseBreakdown,
  }) {
    return AccountsData(
      totalRevenue: totalRevenue ?? this.totalRevenue,
      expenses: expenses ?? this.expenses,
      netProfit: netProfit ?? this.netProfit,
      revenueTrendPercent: revenueTrendPercent ?? this.revenueTrendPercent,
      expensesTrendPercent: expensesTrendPercent ?? this.expensesTrendPercent,
      netProfitTrendPercent: netProfitTrendPercent ?? this.netProfitTrendPercent,
      revenueVsExpenses: revenueVsExpenses ?? this.revenueVsExpenses,
      expenseBreakdown: expenseBreakdown ?? this.expenseBreakdown,
    );
  }

  @override
  List<Object?> get props => [
        totalRevenue,
        expenses,
        netProfit,
        revenueTrendPercent,
        expensesTrendPercent,
        netProfitTrendPercent,
        revenueVsExpenses,
        expenseBreakdown,
      ];
}

class MonthlyRevenuePoint extends Equatable {
  final String month;
  final double revenue;
  final double expenses;

  const MonthlyRevenuePoint({
    required this.month,
    required this.revenue,
    required this.expenses,
  });

  @override
  List<Object?> get props => [month, revenue, expenses];
}

class ExpenseSlice extends Equatable {
  final String label;
  final double amount;

  const ExpenseSlice({required this.label, required this.amount});

  @override
  List<Object?> get props => [label, amount];
}
