import '../../core/network/dio_client.dart';
import '../models/dashboard_data.dart';

class DashboardRepository {
  // ignore: unused_field
  final DioClient _client;

  DashboardRepository(this._client);

  Future<DashboardData> fetchDashboard() async {
    await Future.delayed(const Duration(milliseconds: 500));

    return const DashboardData(
      combinedRevenue: [
        MonthlyRevenuePoint(
          month: 'Jan',
          emr: 2300,
          accounts: 4000,
          store: 2200,
          bar: 1900,
          lab: 2400,
        ),
        MonthlyRevenuePoint(
          month: 'Feb',
          emr: 2900,
          accounts: 1500,
          store: 1900,
          bar: 2100,
          lab: 2100,
        ),
        MonthlyRevenuePoint(
          month: 'Mar',
          emr: 2700,
          accounts: 10000,
          store: 2200,
          bar: 2200,
          lab: 2400,
        ),
        MonthlyRevenuePoint(
          month: 'Apr',
          emr: 3200,
          accounts: 3900,
          store: 2300,
          bar: 2300,
          lab: 2300,
        ),
        MonthlyRevenuePoint(
          month: 'May',
          emr: 3700,
          accounts: 4800,
          store: 2000,
          bar: 2500,
          lab: 2400,
        ),
        MonthlyRevenuePoint(
          month: 'Jun',
          emr: 3900,
          accounts: 3900,
          store: 2500,
          bar: 2700,
          lab: 2600,
        ),
      ],
      emrPatients: 248,
      emrRevenue: 12450,
      accountsInvoices: 156,
      accountsRevenue: 45230,
      storeItems: 1234,
      storeRevenue: 23890,
      barProducts: 89,
      barRevenue: 8650,
      labTests: 156,
      labRevenue: 18340,
      banquetEvents: 115,
      banquetRevenue: 33000,
      restaurantOrders: 85,
      restaurantRevenue: 5800,
      hrStaff: 342,
      hrRevenue: 24500,
      frontofficeCheckIns: 156,
      frontofficeRevenue: 8200,
    );
  }
}
