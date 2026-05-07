import '../../core/network/dio_client.dart';
import '../models/store_data.dart';

class StoreRepository {
  final DioClient _client;

  StoreRepository(this._client);

  Future<StoreData> fetchStore() async {
    await Future.delayed(const Duration(milliseconds: 500));

    return const StoreData(
      totalCollection: 2227,
      trendChangePercent: 5.2,
      purchase: 0,
      revenue: 0,
      collection: 2227,
      payments: 0,
      categories: [
        CategorySlice(name: 'Medicines', amount: 1514, percent: 68),
        CategorySlice(name: 'Surgical', amount: 490, percent: 22),
        CategorySlice(name: 'Equipment', amount: 223, percent: 10),
      ],
    );
  }
}
