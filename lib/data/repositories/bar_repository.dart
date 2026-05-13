import '../../core/constants/string_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/bar_data.dart';

class BarRepository {
  // ignore: unused_field
  final DioClient _client;

  BarRepository(this._client);

  Future<BarData> fetchDashboard() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const BarData(
      totalProducts: 89,
      dailySales: 2600,
      orders: 124,
      weeklyRevenue: [
        WeeklyRevenuePoint(day: 'Mon', revenue: 900),
        WeeklyRevenuePoint(day: 'Tue', revenue: 1350),
        WeeklyRevenuePoint(day: 'Wed', revenue: 800),
        WeeklyRevenuePoint(day: 'Thu', revenue: 1700),
        WeeklyRevenuePoint(day: 'Fri', revenue: 1950),
        WeeklyRevenuePoint(day: 'Sat', revenue: 2600),
        WeeklyRevenuePoint(day: 'Sun', revenue: 1450),
      ],
      productMix: [
        ProductMixSlice(label: StringConstants.beer, percent: 35),
        ProductMixSlice(label: StringConstants.wine, percent: 25),
        ProductMixSlice(label: StringConstants.spirits, percent: 20),
        ProductMixSlice(label: StringConstants.cocktails, percent: 15),
        ProductMixSlice(label: StringConstants.nonAlcoholic, percent: 5),
      ],
    );
  }
}
