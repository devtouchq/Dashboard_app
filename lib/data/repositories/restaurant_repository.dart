import '../../core/constants/string_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/restaurant_data.dart';

class RestaurantRepository {
  // ignore: unused_field
  final DioClient _client;

  RestaurantRepository(this._client);

  Future<RestaurantData> fetchDashboard() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const RestaurantData(
      dailyOrders: 85,
      customers: 142,
      revenue: 5800,
      weeklySales: [
        WeeklySalesPoint(day: 'Mon', sales: 3100),
        WeeklySalesPoint(day: 'Tue', sales: 3200),
        WeeklySalesPoint(day: 'Wed', sales: 3000),
        WeeklySalesPoint(day: 'Thu', sales: 4400),
        WeeklySalesPoint(day: 'Fri', sales: 5100),
        WeeklySalesPoint(day: 'Sat', sales: 5800),
        WeeklySalesPoint(day: 'Sun', sales: 5300),
      ],
      salesByCategory: [
        CategorySalesSlice(label: StringConstants.mainCourse, percent: 40),
        CategorySalesSlice(label: StringConstants.appetizers, percent: 25),
        CategorySalesSlice(label: StringConstants.desserts, percent: 15),
        CategorySalesSlice(label: StringConstants.beverages, percent: 12),
        CategorySalesSlice(label: StringConstants.specials, percent: 8),
      ],
    );
  }
}
