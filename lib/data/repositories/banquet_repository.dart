import '../../core/constants/string_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/banquet_data.dart';

class BanquetRepository {
  // ignore: unused_field
  final DioClient _client;

  BanquetRepository(this._client);

  Future<BanquetData> fetchDashboard() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const BanquetData(
      totalEvents: 115,
      thisMonth: 22,
      revenue: 33000,
      revenueTrend: [
        MonthlyRevenuePoint(month: 'Jan', revenue: 18000),
        MonthlyRevenuePoint(month: 'Feb', revenue: 22000),
        MonthlyRevenuePoint(month: 'Mar', revenue: 27000),
        MonthlyRevenuePoint(month: 'Apr', revenue: 21000),
        MonthlyRevenuePoint(month: 'May', revenue: 30000),
        MonthlyRevenuePoint(month: 'Jun', revenue: 34000),
      ],
      eventsByType: [
        EventTypeItem(type: StringConstants.wedding, count: 42),
        EventTypeItem(type: StringConstants.corporate, count: 28),
        EventTypeItem(type: StringConstants.birthday, count: 22),
        EventTypeItem(type: StringConstants.conference, count: 14),
        EventTypeItem(type: StringConstants.other, count: 9),
      ],
    );
  }
}
