import 'package:dio/dio.dart';

import '../../core/network/dio_client.dart';
import '../../core/utils/app_logger.dart';
import '../models/auth_data.dart';

class AuthRepository {
  static const _tag = 'AuthRepository';
  final DioClient _client;

  AuthRepository(this._client);

  /// POST {baseUrl}/api/Authentication/Login/MobileAppLogin
  Future<LoginResponse> login(LoginRequest request) async {
    AppLogger.info(_tag, 'login → ${request.username}@${request.accId}');
    try {
      final res = await _client.dio.post(
        '/api/Authentication/Login/MobileAppLogin',
        data: request.toJson(),
      );

      final body = res.data;
      if (body is! Map<String, dynamic>) {
        throw Exception('Unexpected response shape');
      }
      final parsed = LoginResponse.fromJson(body);

      if (!parsed.isSuccess) {
        AppLogger.warn(_tag, 'login response IsSuccess=false');
      } else {
        AppLogger.info(_tag, 'login OK — ${parsed.branchList.length} branches');
      }
      return parsed;
    } on DioException catch (e, st) {
      AppLogger.error(
        _tag,
        'login failed: ${e.message}',
        error: e,
        stackTrace: st,
      );
      // Surface a friendlier message to the UI
      final msg = e.response?.statusCode != null
          ? 'Server returned ${e.response!.statusCode}'
          : (e.message ?? 'Network error');
      throw Exception(msg);
    } catch (e, st) {
      AppLogger.error(_tag, 'login error', error: e, stackTrace: st);
      rethrow;
    }
  }
}
