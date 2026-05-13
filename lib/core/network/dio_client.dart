import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

import '../di/local_storage_service.dart';
import '../utils/app_logger.dart';

class DioClient {
  static const _tag = 'DioClient';
  late Dio dio;
  final LocalStorageService _storage;

  DioClient(this._storage) {
    final base = _storage.baseUrl ?? '';
    AppLogger.info(_tag, 'init with baseUrl="$base"');

    dio = Dio(BaseOptions(
      baseUrl: base,
      // Bumped from 15s. Connect failures on a phone (wrong network, wrong
      // scheme, blocked port) take a while to surface; longer timeouts make
      // the failure clearer rather than just "took too long".
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    if (!kIsWeb) {
      (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      };
    }

    // Attach auth token + always read the latest baseUrl from storage.
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = _storage.authToken;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        final currentBase = _storage.baseUrl;
        if (currentBase != null && currentBase.isNotEmpty) {
          options.baseUrl = currentBase;
        }
        AppLogger.info(
            _tag, '→ ${options.method} ${options.baseUrl}${options.path}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        AppLogger.info(
            _tag, '← ${response.statusCode} ${response.requestOptions.path}');
        return handler.next(response);
      },
      onError: (e, handler) {
        AppLogger.error(
          _tag,
          '✕ ${e.type.name} on ${e.requestOptions.path}: ${e.message}',
          error: e,
        );
        return handler.next(e);
      },
    ));
  }

  void updateBaseUrl(String newUrl) {
    AppLogger.info(_tag, 'updateBaseUrl: $newUrl');
    dio.options.baseUrl = newUrl;
  }
}
