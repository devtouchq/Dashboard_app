import '../../core/constants/string_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/store_data.dart';

class StoreRepository {
  // ignore: unused_field
  final DioClient _client;

  StoreRepository(this._client);

  Future<StoreData> fetchDashboard() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const StoreData(
      totalItems: 1234,
      lowStock: 23,
      orders: 156,
      inventoryByCategory: [
        CategoryInventory(
            category: StringConstants.medical, inStock: 420, sold: 180),
        CategoryInventory(
            category: StringConstants.surgical, inStock: 280, sold: 140),
        CategoryInventory(
            category: StringConstants.pharmacy, inStock: 880, sold: 400),
        CategoryInventory(
            category: StringConstants.equipment, inStock: 110, sold: 60),
        CategoryInventory(
            category: StringConstants.supplies, inStock: 300, sold: 170),
      ],
      monthlySales: [
        MonthlySalesPoint(month: 'Jan', sales: 2000),
        MonthlySalesPoint(month: 'Feb', sales: 2400),
        MonthlySalesPoint(month: 'Mar', sales: 1900),
        MonthlySalesPoint(month: 'Apr', sales: 2800),
        MonthlySalesPoint(month: 'May', sales: 2600),
        MonthlySalesPoint(month: 'Jun', sales: 3200),
      ],
    );
  }
}
