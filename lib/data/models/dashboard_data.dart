import 'package:equatable/equatable.dart';

/// One month on the combined revenue chart.
class MonthlyRevenuePoint extends Equatable {
  final String month;
  final double emr;
  final double accounts;
  final double store;
  final double bar;
  final double lab;

  const MonthlyRevenuePoint({
    required this.month,
    required this.emr,
    required this.accounts,
    required this.store,
    required this.bar,
    required this.lab,
  });

  @override
  List<Object?> get props => [month, emr, accounts, store, bar, lab];
}

/// Aggregate data for the Home (Dashboard) screen.
class DashboardData extends Equatable {
  final List<MonthlyRevenuePoint> combinedRevenue;

  // Quick stats per department, shown in the department tiles.
  final int emrPatients;
  final double emrRevenue;
  final int accountsInvoices;
  final double accountsRevenue;
  final int storeItems;
  final double storeRevenue;
  final int barProducts;
  final double barRevenue;
  final int labTests;
  final double labRevenue;
  final int banquetEvents;
  final double banquetRevenue;
  final int restaurantOrders;
  final double restaurantRevenue;
  final int hrStaff;
  final double hrRevenue;
  final int frontofficeCheckIns;
  final double frontofficeRevenue;

  const DashboardData({
    required this.combinedRevenue,
    required this.emrPatients,
    required this.emrRevenue,
    required this.accountsInvoices,
    required this.accountsRevenue,
    required this.storeItems,
    required this.storeRevenue,
    required this.barProducts,
    required this.barRevenue,
    required this.labTests,
    required this.labRevenue,
    required this.banquetEvents,
    required this.banquetRevenue,
    required this.restaurantOrders,
    required this.restaurantRevenue,
    required this.hrStaff,
    required this.hrRevenue,
    required this.frontofficeCheckIns,
    required this.frontofficeRevenue,
  });

  DashboardData copyWith({
    List<MonthlyRevenuePoint>? combinedRevenue,
    int? emrPatients,
    double? emrRevenue,
    int? accountsInvoices,
    double? accountsRevenue,
    int? storeItems,
    double? storeRevenue,
    int? barProducts,
    double? barRevenue,
    int? labTests,
    double? labRevenue,
    int? banquetEvents,
    double? banquetRevenue,
    int? restaurantOrders,
    double? restaurantRevenue,
    int? hrStaff,
    double? hrRevenue,
    int? frontofficeCheckIns,
    double? frontofficeRevenue,
  }) {
    return DashboardData(
      combinedRevenue: combinedRevenue ?? this.combinedRevenue,
      emrPatients: emrPatients ?? this.emrPatients,
      emrRevenue: emrRevenue ?? this.emrRevenue,
      accountsInvoices: accountsInvoices ?? this.accountsInvoices,
      accountsRevenue: accountsRevenue ?? this.accountsRevenue,
      storeItems: storeItems ?? this.storeItems,
      storeRevenue: storeRevenue ?? this.storeRevenue,
      barProducts: barProducts ?? this.barProducts,
      barRevenue: barRevenue ?? this.barRevenue,
      labTests: labTests ?? this.labTests,
      labRevenue: labRevenue ?? this.labRevenue,
      banquetEvents: banquetEvents ?? this.banquetEvents,
      banquetRevenue: banquetRevenue ?? this.banquetRevenue,
      restaurantOrders: restaurantOrders ?? this.restaurantOrders,
      restaurantRevenue: restaurantRevenue ?? this.restaurantRevenue,
      hrStaff: hrStaff ?? this.hrStaff,
      hrRevenue: hrRevenue ?? this.hrRevenue,
      frontofficeCheckIns: frontofficeCheckIns ?? this.frontofficeCheckIns,
      frontofficeRevenue: frontofficeRevenue ?? this.frontofficeRevenue,
    );
  }

  @override
  List<Object?> get props => [
        combinedRevenue,
        emrPatients,
        emrRevenue,
        accountsInvoices,
        accountsRevenue,
        storeItems,
        storeRevenue,
        barProducts,
        barRevenue,
        labTests,
        labRevenue,
        banquetEvents,
        banquetRevenue,
        restaurantOrders,
        restaurantRevenue,
        hrStaff,
        hrRevenue,
        frontofficeCheckIns,
        frontofficeRevenue,
      ];
}
