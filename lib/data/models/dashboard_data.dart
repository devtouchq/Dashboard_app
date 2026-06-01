import 'package:equatable/equatable.dart';

// Helpers to safely parse numbers from JSON (API mixes int/double/string).
double _toD(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

int _toI(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString().split('.').first) ?? 0;
}

String _toS(dynamic v) => v?.toString() ?? '';

// ─────────────────────────────────────────────────────────────
//  Currency
// ─────────────────────────────────────────────────────────────
class CurrencyData extends Equatable {
  final String defaultCurrency;

  const CurrencyData({required this.defaultCurrency});

  factory CurrencyData.fromJson(Map<String, dynamic> j) => CurrencyData(
        defaultCurrency: _toS(j['DefaultCurrency']).isEmpty
            ? 'INR'
            : _toS(j['DefaultCurrency']),
      );

  static const fallback = CurrencyData(defaultCurrency: 'INR');

  @override
  List<Object?> get props => [defaultCurrency];
}

// ─────────────────────────────────────────────────────────────
//  EMR
// ─────────────────────────────────────────────────────────────
class DoctorPatientCount extends Equatable {
  final String doctor;
  final String currMonthName;
  final int currMonthPatients;
  final String prevMonthName;
  final int prevMonthPatients;

  const DoctorPatientCount({
    required this.doctor,
    required this.currMonthName,
    required this.currMonthPatients,
    required this.prevMonthName,
    required this.prevMonthPatients,
  });

  factory DoctorPatientCount.fromJson(Map<String, dynamic> j) =>
      DoctorPatientCount(
        doctor: _toS(j['Doctor']),
        currMonthName: _toS(j['CurrMonthName']),
        currMonthPatients: _toI(j['CurrMonthPatients']),
        prevMonthName: _toS(j['PrevMonthName']),
        prevMonthPatients: _toI(j['PrevMonthPatients']),
      );

  int get delta => currMonthPatients - prevMonthPatients;

  @override
  List<Object?> get props => [
        doctor,
        currMonthName,
        currMonthPatients,
        prevMonthName,
        prevMonthPatients,
      ];
}

class EmrData extends Equatable {
  final int totalPatients;
  final int appointments;
  final int activeCases;
  final int outpatientCount;
  final int inpatientCount;
  final int newPatientCount;
  final int repeatPatientCount;
  final int ipAdmittedAllTime;
  final int maleCount;
  final int femaleCount;
  final double totalRevenue;
  final double opAdvanceAmount;
  final double opBillAmount;

  final List<DoctorPatientCount> doctorPatients;

  const EmrData({
    required this.totalPatients,
    required this.appointments,
    required this.activeCases,
    required this.outpatientCount,
    required this.inpatientCount,
    required this.newPatientCount,
    required this.repeatPatientCount,
    required this.ipAdmittedAllTime,
    required this.maleCount,
    required this.femaleCount,
    required this.totalRevenue,
    required this.opAdvanceAmount,
    required this.opBillAmount,
    required this.doctorPatients,
  });

  factory EmrData.fromJson(Map<String, dynamic> j) => EmrData(
        totalPatients: _toI(j['TotalPatients']),
        appointments: _toI(j['Appointments']),
        activeCases: _toI(j['ActiveCases']),
        outpatientCount: _toI(j['OutpatientCount']),
        inpatientCount: _toI(j['InpatientCount']),
        newPatientCount: _toI(j['NewPatientCount']),
        repeatPatientCount: _toI(j['RepeatPatientCount']),
        ipAdmittedAllTime: _toI(j['IpAdmittedAllTime']),
        maleCount: _toI(j['MaleCount']),
        femaleCount: _toI(j['FemaleCount']),
        totalRevenue: _toD(j['TotalRevenueForEmr']),
        opAdvanceAmount: _toD(j['OpAdvanceAmount']),
        opBillAmount: _toD(j['OpBillAmount']),
        doctorPatients: (j['DoctorPatients'] as List?)
                ?.map((e) =>
                    DoctorPatientCount.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  @override
  List<Object?> get props => [
        totalPatients,
        appointments,
        activeCases,
        outpatientCount,
        inpatientCount,
        newPatientCount,
        repeatPatientCount,
        ipAdmittedAllTime,
        maleCount,
        femaleCount,
        totalRevenue,
        opAdvanceAmount,
        opBillAmount,
        doctorPatients,
      ];
}

// ─────────────────────────────────────────────────────────────
//  Accounts
// ─────────────────────────────────────────────────────────────
class AccountsData extends Equatable {
  final double totalPayments;
  final double totalRevenue;
  final double totalDebitors;
  final double totalReceipts;
  final double totalCollection;

  const AccountsData({
    required this.totalPayments,
    required this.totalRevenue,
    required this.totalDebitors,
    required this.totalReceipts,
    required this.totalCollection,
  });

  factory AccountsData.fromJson(Map<String, dynamic> j) => AccountsData(
        totalPayments: _toD(j['TotalPayments']),
        totalRevenue: _toD(j['TotalRevenue']),
        totalDebitors: _toD(j['TotalDebitors']),
        totalReceipts: _toD(j['TotalReceipts']),
        totalCollection: _toD(j['TotalCollection']),
      );

  @override
  List<Object?> get props => [
        totalPayments,
        totalRevenue,
        totalDebitors,
        totalReceipts,
        totalCollection
      ];
}

// ─────────────────────────────────────────────────────────────
//  Store
// ─────────────────────────────────────────────────────────────
class StoreSales extends Equatable {
  final double totalSales;
  final double insideKerala;
  final double outsideKerala;
  final double export;

  const StoreSales({
    required this.totalSales,
    required this.insideKerala,
    required this.outsideKerala,
    required this.export,
  });

  factory StoreSales.fromJson(Map<String, dynamic> j) => StoreSales(
        totalSales: _toD(j['TotalSales']),
        insideKerala: _toD(j['InsideKerala']),
        outsideKerala: _toD(j['OutsideKerala']),
        export: _toD(j['Export']),
      );

  @override
  List<Object?> get props => [totalSales, insideKerala, outsideKerala, export];
}

class StorePurchase extends Equatable {
  final double totalPurchase;
  final double totalRemittance;
  final double pending;

  const StorePurchase({
    required this.totalPurchase,
    required this.totalRemittance,
    required this.pending,
  });

  factory StorePurchase.fromJson(Map<String, dynamic> j) => StorePurchase(
        totalPurchase: _toD(j['TotalPurchase']),
        totalRemittance: _toD(j['TotalRemittance']),
        pending: _toD(j['Pending']),
      );

  @override
  List<Object?> get props => [totalPurchase, totalRemittance, pending];
}

class StoreData extends Equatable {
  final double totalRevenue;
  final double totalCollection;
  final double purchase;
  final StoreSales sales;
  final StorePurchase purchaseSummary;
  final String wipPercentage;

  const StoreData({
    required this.totalRevenue,
    required this.totalCollection,
    required this.purchase,
    required this.sales,
    required this.purchaseSummary,
    required this.wipPercentage,
  });

  factory StoreData.fromJson(Map<String, dynamic> j) => StoreData(
        totalRevenue: _toD(j['TotalRevenueStore']),
        totalCollection: _toD(j['TotalCollectionStore']),
        purchase: _toD(j['Purchase']),
        sales: StoreSales.fromJson(
            (j['SalesSummary'] as Map?)?.cast<String, dynamic>() ?? {}),
        purchaseSummary: StorePurchase.fromJson(
            (j['PurchaseSummary'] as Map?)?.cast<String, dynamic>() ?? {}),
        wipPercentage:
            _toS((j['Wip'] as Map?)?['WipAveragePercentage'] ?? '0%'),
      );

  @override
  List<Object?> get props => [
        totalRevenue,
        totalCollection,
        purchase,
        sales,
        purchaseSummary,
        wipPercentage
      ];
}

// ─────────────────────────────────────────────────────────────
//  Bar
// ─────────────────────────────────────────────────────────────
class BarItemTotal extends Equatable {
  final String category;
  final double amount;

  const BarItemTotal({required this.category, required this.amount});

  @override
  List<Object?> get props => [category, amount];
}

class BarData extends Equatable {
  final double totalRevenue;
  final double totalCollection;
  final List<BarItemTotal> itemTotals;

  const BarData({
    required this.totalRevenue,
    required this.totalCollection,
    required this.itemTotals,
  });

  factory BarData.fromJson(Map<String, dynamic> j) {
    // The API sends amounts and categories as parallel CSV strings:
    //   "1400,100,350,1400,100,350,..."
    //   "WINE,BEER,GIN,WINE,BEER,GIN,..."
    // Categories repeat, so we sum them up per category.
    final amountsCsv = _toS(j['hiddenTotalBarItemAmount']);
    final categoriesCsv = _toS(j['hiddenTotalBarItemCategory']);

    final amounts = _splitCsv(amountsCsv).map(_toD).toList();
    final categories = _splitCsv(categoriesCsv);

    final summed = <String, double>{};
    final pairCount =
        amounts.length < categories.length ? amounts.length : categories.length;
    for (var i = 0; i < pairCount; i++) {
      final cat = categories[i].trim();
      if (cat.isEmpty) continue;
      summed[cat] = (summed[cat] ?? 0) + amounts[i];
    }

    // Sort descending so the biggest bar is first.
    final totals = summed.entries
        .map((e) => BarItemTotal(category: e.key, amount: e.value))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return BarData(
      totalRevenue: _toD(j['TotalRevenueBar']),
      totalCollection: _toD(j['TotalCollectionBar']),
      itemTotals: totals,
    );
  }

  @override
  List<Object?> get props => [totalRevenue, totalCollection, itemTotals];
}

// Helper used by BarData.fromJson — drops trailing empty token left by
// the API's trailing comma ("WINE,BEER,GIN,").
List<String> _splitCsv(String csv) {
  if (csv.isEmpty) return const [];
  return csv.split(',').where((s) => s.trim().isNotEmpty).toList();
}

// ─────────────────────────────────────────────────────────────
//  Lab
// ─────────────────────────────────────────────────────────────
class LabData extends Equatable {
  final double testCount;
  final double totalRevenue;
  final double totalCollection;

  const LabData({
    required this.testCount,
    required this.totalRevenue,
    required this.totalCollection,
  });

  factory LabData.fromJson(Map<String, dynamic> j) => LabData(
        testCount: _toD(j['labelTestCount']),
        totalRevenue: _toD(j['labelTotalRevenueLab']),
        totalCollection: _toD(j['labelTotalCollectionLab']),
      );

  @override
  List<Object?> get props => [testCount, totalRevenue, totalCollection];
}

// ─────────────────────────────────────────────────────────────
//  Restaurant
// ─────────────────────────────────────────────────────────────
class RestaurantData extends Equatable {
  final double totalPax;
  final double runningTableCount;
  final double totalRevenue;
  final double totalCollection;

  const RestaurantData({
    required this.totalPax,
    required this.runningTableCount,
    required this.totalRevenue,
    required this.totalCollection,
  });

  factory RestaurantData.fromJson(Map<String, dynamic> j) => RestaurantData(
        totalPax: _toD(j['TotalPax']),
        runningTableCount: _toD(j['RunningTableCount']),
        totalRevenue: _toD(j['TotalRevenueRestaurant']),
        totalCollection: _toD(j['TotalCollectionRestaurant']),
      );

  @override
  List<Object?> get props =>
      [totalPax, runningTableCount, totalRevenue, totalCollection];
}

// ─────────────────────────────────────────────────────────────
//  HR
// ─────────────────────────────────────────────────────────────
class HrData extends Equatable {
  final int totalPresent;
  final int totalAbsent;
  final String lastSyncedTime;
  final double totalRevenue;

  const HrData({
    required this.totalPresent,
    required this.totalAbsent,
    required this.lastSyncedTime,
    required this.totalRevenue,
  });

  factory HrData.fromJson(Map<String, dynamic> j) => HrData(
        totalPresent: _toI(j['TotalPresent']),
        totalAbsent: _toI(j['TotalAbsent']),
        lastSyncedTime: _toS(j['LastSyncedTime']),
        totalRevenue: _toD(j['TotalRevenueHr']),
      );

  @override
  List<Object?> get props =>
      [totalPresent, totalAbsent, lastSyncedTime, totalRevenue];
}

// ─────────────────────────────────────────────────────────────
//  Banquet & Frontoffice — values live inside Accounts in this API
// ─────────────────────────────────────────────────────────────
class BanquetData extends Equatable {
  final double totalRevenue;
  final double totalFunctions;
  final double totalReservations;

  const BanquetData({
    required this.totalRevenue,
    required this.totalFunctions,
    required this.totalReservations,
  });

  factory BanquetData.fromAccounts(Map<String, dynamic> j) => BanquetData(
        totalRevenue: _toD(j['TotalRevenueBanquet']),
        totalFunctions: _toD(j['TotalNoOfFunction']),
        totalReservations: _toD(j['TotalNoOfReservations']),
      );

  @override
  List<Object?> get props => [totalRevenue, totalFunctions, totalReservations];
}

class FrontofficeData extends Equatable {
  final double totalCheckIn;
  final double currentGuests;
  final double expectedArrival;
  final double probableCheckout;
  final double totalRevenue;
  final double totalCollection;

  const FrontofficeData({
    required this.totalCheckIn,
    required this.currentGuests,
    required this.expectedArrival,
    required this.probableCheckout,
    required this.totalRevenue,
    required this.totalCollection,
  });

  factory FrontofficeData.fromAccounts(Map<String, dynamic> j) =>
      FrontofficeData(
        totalCheckIn: _toD(j['TotalCheckIn']),
        currentGuests: _toD(j['CurrentGuests']),
        expectedArrival: _toD(j['TotalExpectedArrival']),
        probableCheckout: _toD(j['TotalProbableCheckout']),
        totalRevenue: _toD(j['TotalRevenueFo']),
        totalCollection: _toD(j['TotalCollection']),
      );

  @override
  List<Object?> get props => [
        totalCheckIn,
        currentGuests,
        expectedArrival,
        probableCheckout,
        totalRevenue,
        totalCollection
      ];
}

// ─────────────────────────────────────────────────────────────
//  Overview
// ─────────────────────────────────────────────────────────────
class SectionDaily extends Equatable {
  final String name;
  final double totalRevenue;

  const SectionDaily({required this.name, required this.totalRevenue});

  factory SectionDaily.fromJson(Map<String, dynamic> j) => SectionDaily(
        name: _toS(j['Name']),
        totalRevenue: _toD(j['TotalRevenue']),
      );

  @override
  List<Object?> get props => [name, totalRevenue];
}

class SectionTile extends Equatable {
  final String name;
  final double count;
  final String countLabel;
  final double revenue;

  const SectionTile({
    required this.name,
    required this.count,
    required this.countLabel,
    required this.revenue,
  });

  factory SectionTile.fromJson(Map<String, dynamic> j) => SectionTile(
        name: _toS(j['Name']),
        count: _toD(j['Count']),
        countLabel: _toS(j['CountLabel']),
        revenue: _toD(j['Revenue']),
      );

  @override
  List<Object?> get props => [name, count, countLabel, revenue];
}

class OverviewData extends Equatable {
  final List<SectionDaily> sectionsDaily;
  final List<SectionTile> sectionTiles;

  const OverviewData({
    required this.sectionsDaily,
    required this.sectionTiles,
  });

  factory OverviewData.fromJson(Map<String, dynamic> j) => OverviewData(
        sectionsDaily: (j['SectionsDaily'] as List?)
                ?.map((e) => SectionDaily.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        sectionTiles: (j['SectionTiles'] as List?)
                ?.map((e) => SectionTile.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  double get totalRevenue =>
      sectionsDaily.fold<double>(0, (s, x) => s + x.totalRevenue);

  @override
  List<Object?> get props => [sectionsDaily, sectionTiles];
}

// ─────────────────────────────────────────────────────────────
//  Top-level DashboardData
// ─────────────────────────────────────────────────────────────
class DashboardData extends Equatable {
  final EmrData emr;
  final AccountsData accounts;
  final StoreData store;
  final BarData bar;
  final LabData lab;
  final RestaurantData restaurant;
  final HrData hr;
  final BanquetData banquet;
  final FrontofficeData frontoffice;
  final OverviewData overview;
  final CurrencyData currency;

  const DashboardData({
    required this.emr,
    required this.accounts,
    required this.store,
    required this.bar,
    required this.lab,
    required this.restaurant,
    required this.hr,
    required this.banquet,
    required this.frontoffice,
    required this.overview,
    required this.currency,
  });

  factory DashboardData.fromJson(Map<String, dynamic> j) {
    Map<String, dynamic> sub(String key) =>
        (j[key] as Map?)?.cast<String, dynamic>() ?? {};

    final accountsJson = sub('Accounts');

    return DashboardData(
      emr: EmrData.fromJson(sub('Emr')),
      accounts: AccountsData.fromJson(accountsJson),
      store: StoreData.fromJson(sub('Store')),
      bar: BarData.fromJson(sub('Bar')),
      lab: LabData.fromJson(sub('Lab')),
      restaurant: RestaurantData.fromJson(sub('Restaurant')),
      hr: HrData.fromJson(sub('HrManager')),
      banquet: BanquetData.fromAccounts(accountsJson),
      frontoffice: FrontofficeData.fromAccounts(accountsJson),
      overview: OverviewData.fromJson(sub('Overview')),
      currency: j['Currency'] != null
          ? CurrencyData.fromJson(
              (j['Currency'] as Map).cast<String, dynamic>())
          : CurrencyData.fallback,
    );
  }

  @override
  List<Object?> get props => [
        emr,
        accounts,
        store,
        bar,
        lab,
        restaurant,
        hr,
        banquet,
        frontoffice,
        overview,
        currency,
      ];
}
