import '../../core/constants/string_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/lab_data.dart';

class LabRepository {
  // ignore: unused_field
  final DioClient _client;

  LabRepository(this._client);

  Future<LabData> fetchDashboard() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const LabData(
      totalTests: 156,
      pending: 12,
      completed: 144,
      monthlyTests: [
        MonthlyTestPoint(month: 'Jan', count: 120),
        MonthlyTestPoint(month: 'Feb', count: 138),
        MonthlyTestPoint(month: 'Mar', count: 128),
        MonthlyTestPoint(month: 'Apr', count: 145),
        MonthlyTestPoint(month: 'May', count: 152),
        MonthlyTestPoint(month: 'Jun', count: 160),
      ],
      testsByType: [
        TestTypeItem(type: StringConstants.blood, count: 64),
        TestTypeItem(type: StringConstants.urine, count: 38),
        TestTypeItem(type: StringConstants.ctScan, count: 22),
        TestTypeItem(type: StringConstants.other, count: 32),
      ],
    );
  }
}
