import '../../core/network/dio_client.dart';
import '../models/dashboard_data.dart';

class DashboardRepository {
  final DioClient _client;

  DashboardRepository(this._client);

  /// Real API call would look like:
  ///   final res = await _client.dio.get('/dashboard/summary');
  ///   return DashboardData.fromJson(res.data);
  /// For now we return mock data so the UI is fully runnable.
  Future<DashboardData> fetchDashboard() async {
    await Future.delayed(const Duration(milliseconds: 600));

    return const DashboardData(
      combinedRevenue: 2227,
      trendChangePercent: 12.4,
      trend: [
        TrendPoint(day: 'Mon', accounts: 30, emr: 55, store: 18),
        TrendPoint(day: 'Tue', accounts: 45, emr: 38, store: 22),
        TrendPoint(day: 'Wed', accounts: 40, emr: 60, store: 28),
        TrendPoint(day: 'Thu', accounts: 70, emr: 50, store: 35),
        TrendPoint(day: 'Fri', accounts: 62, emr: 75, store: 42),
        TrendPoint(day: 'Sat', accounts: 85, emr: 65, store: 50),
        TrendPoint(day: 'Sun', accounts: 78, emr: 90, store: 58),
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
