import 'package:dio/dio.dart';

import '../../core/network/dio_client.dart';
import '../../core/utils/app_logger.dart';

/// Sends/removes device FCM tokens to/from the .NET backend.
/// Implement these two endpoints on the backend side (see
/// dotnet_backend_setup.md).
class DeviceTokenRepository {
  static const _tag = 'DeviceTokenRepository';
  final DioClient _client;

  DeviceTokenRepository(this._client);

  /// Called after login and whenever the FCM token rotates.
  /// Backend should upsert (userId + deviceToken + platform) so it can
  /// later target a specific user.
  Future<void> registerDeviceToken({
    required String userId,
    required String accountId,
    required String authToken,
    required String fcmToken,
  }) async {
    AppLogger.info(_tag, 'register device token for user=$userId');

    try {
      await _client.dio.post(
        '/api/notification/RegisterDevice',
        data: {
          'UserId': userId,
          'AccountId': accountId,
          'AuthToken': authToken,
          'DeviceToken': fcmToken,
          'Platform': _platform(),
        },
      );
      AppLogger.info(_tag, 'register success');
    } on DioException catch (e) {
      AppLogger.error(_tag, 'register failed: ${e.message}');
      // Don't rethrow — failing to register shouldn't block login.
    }
  }

  /// Called on logout. Tells the backend to stop sending pushes to
  /// this device.
  Future<void> unregisterDeviceToken({
    required String userId,
    required String authToken,
    required String fcmToken,
  }) async {
    AppLogger.info(_tag, 'unregister device token for user=$userId');

    try {
      await _client.dio.post(
        '/api/notification/UnregisterDevice',
        data: {
          'UserId': userId,
          'AuthToken': authToken,
          'DeviceToken': fcmToken,
        },
      );
      AppLogger.info(_tag, 'unregister success');
    } on DioException catch (e) {
      AppLogger.error(_tag, 'unregister failed: ${e.message}');
    }
  }

  String _platform() {
    // For an exact platform string, import 'dart:io' at the top and use
    //   if (Platform.isAndroid) return 'android';
    //   if (Platform.isIOS) return 'ios';
    // Mobile-only build, so 'mobile' is a safe default.
    return 'mobile';
  }
}

// Helpful: in your injector.dart, register this:
// i.addSingleton<DeviceTokenRepository>(
//   () => DeviceTokenRepository(i.get<DioClient>()),
// );
