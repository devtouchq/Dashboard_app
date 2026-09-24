import 'package:dio/dio.dart';

/// The request never got an answer from the server: no route, refused,
/// timed out, or blocked on the device. Distinct from an HTTP error so the
/// UI can explain connectivity (including iOS Local Network permission)
/// instead of showing a raw socket message.
class ServerUnreachableException implements Exception {
  /// Low-level detail from the network layer, for the log.
  final String detail;

  const ServerUnreachableException(this.detail);

  /// True when [e] means "could not reach the server" rather than "the
  /// server answered with an error".
  static bool matches(DioException e) {
    if (e.response != null) return false;
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.unknown:
        return true;
      default:
        // badCertificate, badResponse, cancel, transformTimeout: the
        // server (or the client itself) did respond in some way.
        return false;
    }
  }

  @override
  String toString() => 'ServerUnreachableException($detail)';
}
