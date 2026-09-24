import 'package:dio/dio.dart';

import '../../core/network/dio_client.dart';
import '../../core/network/network_exceptions.dart';
import '../../core/utils/app_logger.dart';
import '../models/auth_data.dart';

class AuthRepository {
  static const _tag = 'AuthRepository';
  final DioClient _client;

  AuthRepository(this._client);

  /// Touches the server once, ignoring the answer.
  ///
  /// Called right after the server address is saved so that, on iOS, the
  /// "connect to devices on your local network" prompt appears here on
  /// the setup screen, where it makes sense, instead of in the middle of
  /// login. Any status code counts as reachable; failures are only logged.
  Future<bool> warmUp() async {
    try {
      await _client.dio.get(
        '/',
        options: Options(
          validateStatus: (_) => true,
          receiveTimeout: const Duration(seconds: 8),
          sendTimeout: const Duration(seconds: 8),
          responseType: ResponseType.plain,
        ),
      );
      AppLogger.info(_tag, 'warmUp: server reachable');
      return true;
    } catch (e) {
      AppLogger.info(_tag, 'warmUp: server not reachable yet ($e)');
      return false;
    }
  }

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
      // No answer at all → typed exception so AuthBloc can retry and
      // explain connectivity. Anything else is an HTTP-level failure.
      if (ServerUnreachableException.matches(e)) {
        throw ServerUnreachableException(e.message ?? e.type.name);
      }
      final msg = e.response?.statusCode != null
          ? 'Server returned ${e.response!.statusCode}'
          : (e.message ?? 'Network error');
      throw Exception(msg);
    } catch (e, st) {
      AppLogger.error(_tag, 'login error', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Calls the MobileAppLogOut endpoint with credentials from storage.
  /// Failures are logged but NOT thrown — we still want local storage
  /// cleared even if the server logout call fails (e.g. offline, token
  /// already invalid).
  Future<void> logout({
    required String authToken,
    required String userId,
    required String accountId,
    required String uniqueId,
  }) async {
    const tag = 'AuthRepository';
    AppLogger.info(tag, 'logout API call');

    final body = {
      'AuthToken': authToken,
      'UserId': userId,
      'AccId': accountId,
      'UniqueId': uniqueId,
      'TabId': '',
    };

    try {
      await _client.dio.post(
        '/api/Authentication/Login/MobileAppLogOut',
        data: body,
        options: Options(
          headers: {'Content-Type': 'application/json'},
          responseType: ResponseType.plain,
        ),
      );
      AppLogger.info(tag, 'logout API success');
    } on DioException catch (e) {
      // Swallow — local storage clear still happens.
      AppLogger.error(tag, 'logout API failed: ${e.message}',
          error: e, stackTrace: e.stackTrace);
    } catch (e, st) {
      AppLogger.error(tag, 'logout error', error: e, stackTrace: st);
    }
  }
}
