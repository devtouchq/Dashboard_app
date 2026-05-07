import 'package:equatable/equatable.dart';

/// Single point on the combined trend chart used on the Home hero.
class TrendPoint extends Equatable {
  final String day; // e.g. Mon, Tue
  final double accounts;
  final double emr;
  final double store;

  const TrendPoint({
    required this.day,
    required this.accounts,
    required this.emr,
    required this.store,
  });

  TrendPoint copyWith({
    String? day,
    double? accounts,
    double? emr,
    double? store,
  }) {
    return TrendPoint(
      day: day ?? this.day,
      accounts: accounts ?? this.accounts,
      emr: emr ?? this.emr,
      store: store ?? this.store,
    );
  }

  @override
  List<Object?> get props => [day, accounts, emr, store];
}

/// Combined dashboard summary used on Home screen.
class DashboardData extends Equatable {
  final double combinedRevenue;
  final double trendChangePercent;
  final List<TrendPoint> trend;

  // Accounts mini summary
  final double receipts;
  final double payments;
  final double crediters;
  final double debiters;

  // EMR mini summary
  final int currentPatients;
  final int malePatients;
  final int femalePatients;
  final int ipPatients;
  final int opPatients;

  // Store mini summary
  final double totalCollection;
  final int storePurchase;
  final int storeRevenue;
  final int storeCollection;
  final int storePayments;

  const DashboardData({
    required this.combinedRevenue,
    required this.trendChangePercent,
    required this.trend,
    required this.receipts,
    required this.payments,
    required this.crediters,
    required this.debiters,
    required this.currentPatients,
    required this.malePatients,
    required this.femalePatients,
    required this.ipPatients,
    required this.opPatients,
    required this.totalCollection,
    required this.storePurchase,
    required this.storeRevenue,
    required this.storeCollection,
    required this.storePayments,
  });

  DashboardData copyWith({
    double? combinedRevenue,
    double? trendChangePercent,
    List<TrendPoint>? trend,
    double? receipts,
    double? payments,
    double? crediters,
    double? debiters,
    int? currentPatients,
    int? malePatients,
    int? femalePatients,
    int? ipPatients,
    int? opPatients,
    double? totalCollection,
    int? storePurchase,
    int? storeRevenue,
    int? storeCollection,
    int? storePayments,
  }) {
    return DashboardData(
      combinedRevenue: combinedRevenue ?? this.combinedRevenue,
      trendChangePercent: trendChangePercent ?? this.trendChangePercent,
      trend: trend ?? this.trend,
      receipts: receipts ?? this.receipts,
      payments: payments ?? this.payments,
      crediters: crediters ?? this.crediters,
      debiters: debiters ?? this.debiters,
      currentPatients: currentPatients ?? this.currentPatients,
      malePatients: malePatients ?? this.malePatients,
      femalePatients: femalePatients ?? this.femalePatients,
      ipPatients: ipPatients ?? this.ipPatients,
      opPatients: opPatients ?? this.opPatients,
      totalCollection: totalCollection ?? this.totalCollection,
      storePurchase: storePurchase ?? this.storePurchase,
      storeRevenue: storeRevenue ?? this.storeRevenue,
      storeCollection: storeCollection ?? this.storeCollection,
      storePayments: storePayments ?? this.storePayments,
    );
  }

  @override
  List<Object?> get props => [
        combinedRevenue,
        trendChangePercent,
        trend,
        receipts,
        payments,
        crediters,
        debiters,
        currentPatients,
        malePatients,
        femalePatients,
        ipPatients,
        opPatients,
        totalCollection,
        storePurchase,
        storeRevenue,
        storeCollection,
        storePayments,
      ];
}
