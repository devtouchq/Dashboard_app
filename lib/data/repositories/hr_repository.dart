import '../../core/constants/string_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/hr_data.dart';

class HrRepository {
  // ignore: unused_field
  final DioClient _client;

  HrRepository(this._client);

  Future<HrData> fetchDashboard() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const HrData(
      totalStaff: 342,
      present: 328,
      onLeave: 14,
      attendanceRate: [
        AttendancePoint(month: 'Jan', presentPercent: 94, absentPercent: 6),
        AttendancePoint(month: 'Feb', presentPercent: 96, absentPercent: 4),
        AttendancePoint(month: 'Mar', presentPercent: 92, absentPercent: 8),
        AttendancePoint(month: 'Apr', presentPercent: 97, absentPercent: 3),
        AttendancePoint(month: 'May', presentPercent: 95, absentPercent: 5),
        AttendancePoint(month: 'Jun', presentPercent: 96, absentPercent: 4),
      ],
      staffByDepartment: [
        DepartmentSlice(label: StringConstants.medical, percent: 45),
        DepartmentSlice(label: StringConstants.administration, percent: 25),
        DepartmentSlice(label: StringConstants.support, percent: 18),
        DepartmentSlice(label: StringConstants.maintenance, percent: 12),
      ],
    );
  }
}
