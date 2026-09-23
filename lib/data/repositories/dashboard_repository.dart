import 'package:dio/dio.dart';

import '../../core/di/local_storage_service.dart';
import '../../core/network/dio_client.dart';
import '../../core/utils/app_logger.dart';
import '../models/dashboard_data.dart';

class DashboardRepository {
  static const _tag = 'DashboardRepository';
  final DioClient _client;
  final LocalStorageService _storage;

  DashboardRepository(this._client, this._storage);

  /// POST {baseUrl}/api/DashBoardManagement/DashBoard/MobileAppDashBoardViewRequest
  Future<DashboardData> fetchDashboard({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final body = {
      'AccountId': _storage.accountId ?? '',
      'AuthToken': _storage.authToken ?? '',
      'Module': _storage.module ?? 'EMR',
      'SubModule': _storage.selectedBranch ?? '',
      'UniqueID': _storage.uniqueId ?? '',
      'TabId': '',
      'FromDate': _formatDate(fromDate),
      'ToDate': _formatDate(toDate),
    };

    AppLogger.info(_tag, 'fetchDashboard → body=$body');

    try {
      final res = await _client.dio.post(
        '/api/DashBoardManagement/DashBoard/MobileAppDashBoardViewRequest',
        data: body,
      );

      final data = res.data;
      if (data is! Map<String, dynamic>) {
        throw Exception('Unexpected response shape');
      }
      if (data['IsSuccess'] == false) {
        final msg = (data['ActionMessage'] ?? 'Request failed').toString();
        throw Exception(msg);
      }

      return DashboardData.fromJson(data);
    } on DioException catch (e, st) {
      AppLogger.error(_tag, 'fetch failed: ${e.message}',
          error: e, stackTrace: st);
      final msg = e.response?.statusCode != null
          ? 'Server returned ${e.response!.statusCode}'
          : (e.message ?? 'Network error');
      throw Exception(msg);
    } catch (e, st) {
      AppLogger.error(_tag, 'fetch error', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Date format expected by the server: dd/MM/yyyy.
  String _formatDate(DateTime dt) {
    String pad(int v) => v.toString().padLeft(2, '0');
    return '${pad(dt.day)}/${pad(dt.month)}/${dt.year}';
  }
}
