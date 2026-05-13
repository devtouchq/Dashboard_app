import '../../core/constants/string_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/frontoffice_data.dart';

class FrontofficeRepository {
  // ignore: unused_field
  final DioClient _client;

  FrontofficeRepository(this._client);

  Future<FrontofficeData> fetchDashboard() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const FrontofficeData(
      checkIns: 156,
      inQueue: 12,
      completed: 144,
      hourlyTraffic: [
        HourlyTrafficPoint(hour: '8am', visitors: 14),
        HourlyTrafficPoint(hour: '10am', visitors: 28),
        HourlyTrafficPoint(hour: '12pm', visitors: 45),
        HourlyTrafficPoint(hour: '2pm', visitors: 38),
        HourlyTrafficPoint(hour: '4pm', visitors: 32),
        HourlyTrafficPoint(hour: '6pm', visitors: 18),
      ],
      inquiriesByType: [
        InquiryTypeItem(type: StringConstants.appointment, count: 70),
        InquiryTypeItem(type: StringConstants.billing, count: 40),
        InquiryTypeItem(type: StringConstants.medicalRecords, count: 35),
        InquiryTypeItem(type: StringConstants.generalInfo, count: 50),
      ],
    );
  }
}
