import '../../core/network/dio_client.dart';
import '../models/emr_data.dart';

class EmrRepository {
  // ignore: unused_field
  final DioClient _client;

  EmrRepository(this._client);

  /// Real API: `await _client.dio.get('/emr/dashboard')`
  /// For now we return mock data.
  Future<EmrData> fetchDashboard() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const EmrData(
      totalPatients: 248,
      appointments: 42,
      activeCases: 18,
      monthlyGrowth: [
        MonthlyGrowthPoint(month: 'Jan', patients: 165),
        MonthlyGrowthPoint(month: 'Feb', patients: 210),
        MonthlyGrowthPoint(month: 'Mar', patients: 175),
        MonthlyGrowthPoint(month: 'Apr', patients: 245),
        MonthlyGrowthPoint(month: 'May', patients: 215),
        MonthlyGrowthPoint(month: 'Jun', patients: 255),
      ],
      outpatientCount: 156,
      inpatientCount: 52,
      emergencyCount: 40,
    );
  }
}
