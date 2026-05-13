import '../../core/network/dio_client.dart';
import '../models/dashboard_data.dart';

class DashboardRepository {
  final DioClient _client;

  DashboardRepository(this._client);

  Future<DashboardData> fetchDashboard() async {
    await Future.delayed(const Duration(milliseconds: 600));

    return const DashboardData(
      combinedRevenue: 2227,
      trendChangePercent: 12.4,
      trend: [
        TrendPoint(
          day: 'Mon',
          accounts: 30,
          emr: 55,
          store: 18,
          hr: 8,
          restaurant: 22,
          lab: 14,
          bar: 9,
          frontoffice: 18,
          banquet: 6,
        ),
        TrendPoint(
          day: 'Tue',
          accounts: 45,
          emr: 38,
          store: 22,
          hr: 12,
          restaurant: 28,
          lab: 18,
          bar: 11,
          frontoffice: 24,
          banquet: 9,
        ),
        TrendPoint(
          day: 'Wed',
          accounts: 40,
          emr: 60,
          store: 28,
          hr: 10,
          restaurant: 32,
          lab: 20,
          bar: 14,
          frontoffice: 30,
          banquet: 12,
        ),
        TrendPoint(
          day: 'Thu',
          accounts: 70,
          emr: 50,
          store: 35,
          hr: 15,
          restaurant: 38,
          lab: 24,
          bar: 16,
          frontoffice: 36,
          banquet: 14,
        ),
        TrendPoint(
          day: 'Fri',
          accounts: 62,
          emr: 75,
          store: 42,
          hr: 18,
          restaurant: 45,
          lab: 28,
          bar: 22,
          frontoffice: 42,
          banquet: 18,
        ),
        TrendPoint(
          day: 'Sat',
          accounts: 85,
          emr: 65,
          store: 50,
          hr: 20,
          restaurant: 58,
          lab: 32,
          bar: 30,
          frontoffice: 52,
          banquet: 24,
        ),
        TrendPoint(
          day: 'Sun',
          accounts: 78,
          emr: 90,
          store: 58,
          hr: 16,
          restaurant: 52,
          lab: 30,
          bar: 26,
          frontoffice: 48,
          banquet: 20,
        ),
      ],
      receipts: 0,
      payments: 0,
      crediters: -6817071,
      debiters: 61232078,
      currentPatients: 581,
      malePatients: 452,
      femalePatients: 129,
      ipPatients: 0,
      opPatients: 0,
      totalCollection: 2227,
      storePurchase: 0,
      storeRevenue: 0,
      storeCollection: 2227,
      storePayments: 0,
    );
  }
}
