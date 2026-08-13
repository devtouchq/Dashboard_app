import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';

import '../../core/di/local_storage_service.dart';
import '../../core/network/api_transformer.dart';
import '../../core/network/dio_client.dart';
import '../../core/utils/app_logger.dart';

/// Response from the AI assistant API.
class ChatApiResponse {
  final bool isSuccess;
  final String botMessage;
  final String? errorMessage;
  final bool isHtml;

  const ChatApiResponse({
    required this.isSuccess,
    required this.botMessage,
    this.errorMessage,
    this.isHtml = false,
  });
}

/// Wraps /api/AIAssistant/SendMessage.
///
/// AI answers can take 30–90 seconds because the backend runs an LLM
/// query. The global DioClient timeout (30s) is too short for this
/// endpoint — we override `receiveTimeout` per request to give the AI
/// enough time to finish.
class ChatRepository {
  static const _tag = 'ChatRepository';
  static const _componentName = 'AyurvedadashboardComponent';

  /// How long to wait for the AI backend to respond. LLM inference can
  /// legitimately take a while — 2 minutes is a comfortable ceiling.
  static const _aiReceiveTimeout = Duration(minutes: 2);

  /// Send timeout is short because the compressed request body is small.
  static const _aiSendTimeout = Duration(seconds: 30);

  final DioClient _client;
  final LocalStorageService _storage;
  final ApiTransformer _transformer;
  final Random _random = Random();

  ChatRepository(this._client, this._storage) : _transformer = ApiTransformer();

  Future<ChatApiResponse> sendMessage(String userMessage) async {
    final body = _buildRequestBody(userMessage);
    AppLogger.info(_tag, 'send → question="${userMessage.length} chars"');

    try {
      final compressedPayload = _transformer.compressRequest(body);
      AppLogger.info(
          _tag, 'request compressed to ${compressedPayload.length} chars'); 

      final response = await _client.dio.post(
        '/api/AIAssistant/SendMessage',
        data: compressedPayload,
        options: Options(
          headers: {
            Headers.contentTypeHeader: 'application/json',
            Headers.acceptHeader: 'application/json',
            'content-encoding': 'gzip',
            'accept-encoding': 'gzip, deflate',
            'User-Agent': 'AyurlivDashboard/1.0',
          },
          responseType: ResponseType.bytes,
          // Override the global DioClient timeouts. The AI backend runs
          // an LLM query which can take up to a minute or more — the
          // global 30s receiveTimeout was firing before the server had
          // a chance to reply.
          sendTimeout: _aiSendTimeout,
          receiveTimeout: _aiReceiveTimeout,
        ),
      );



      if (response.statusCode != 200) {
        return ChatApiResponse(
          isSuccess: false,
          botMessage: '',
          errorMessage: 'Server returned ${response.statusCode}',
        );
      }

      final data = _decodeResponse(response.data as List<int>);
      if (data == null) {
        return const ChatApiResponse(
          isSuccess: false,
          botMessage: '',
          errorMessage: 'Could not read server response',
        );
      }

      final html = _extractAIResponse(data);
      if (html.isEmpty) {
        AppLogger.info(_tag,
            'response had no hiddenAIResponse.Text. Top-level keys: ${data.keys.toList()}');
        return const ChatApiResponse(
          isSuccess: false,
          botMessage: '',
          errorMessage: 'The assistant did not return an answer',
        );
      }

      return ChatApiResponse(
        isSuccess: true,
        botMessage: html,
        isHtml: true,
      );
    } on DioException catch (e, st) {
      // Give the user a friendlier message for the specific timeout case,
      // since AI queries hit this most often. Anything else falls through
      // to the original rethrow so ChatBloc can flag the message as failed.
      if (e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionTimeout) {
        AppLogger.error(_tag, 'AI request timed out (${e.type})',
            error: e, stackTrace: st);
        return const ChatApiResponse(
          isSuccess: false,
          botMessage: '',
          errorMessage:
              'The assistant is taking longer than usual. Please try again.',
        );
      }
      AppLogger.error(_tag, 'sendMessage failed', error: e, stackTrace: st);
      rethrow;
    } catch (e, st) {
      AppLogger.error(_tag, 'sendMessage failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  Build the ButtonClickedActionArgs payload
  // ─────────────────────────────────────────────────────────────
  Map<String, dynamic> _buildRequestBody(String question) {
    final now = DateTime.now();
    final module = _storage.module ?? 'OPModule';
    final selectedBranch = _storage.selectedBranch ?? '';
    final scopedBranch =
        selectedBranch.toUpperCase() == 'ALL' ? '' : selectedBranch;
    final aiContext = jsonEncode({
      'module': module,
      'subModule': scopedBranch,
      'componentName': _componentName,
    });

    final uniqueId = _formatUniqueId(now);
    final tabId =
        '${now.millisecondsSinceEpoch}.${_random.nextInt(9999).toString().padLeft(4, '0')}';

    final controls = [
      _hiddenControl('hiddenSelectedCompany', scopedBranch),
      _hiddenControl('hiddenSelectedModule', module),
      _hiddenControl('hiddenAIQuestion', question),
      _hiddenControl('hiddenAIResponse', ''),
      _hiddenControl('hiddenAIContext', aiContext),
    ];

    return {
      r'$type': 'tqActions.ActionArgs.ButtonClickedActionArgs,tqActions',
      'ClientAppOS': 'Android',
      'ClientAppOSVersion': '13',
      'ClientAppType': 'MobileApp',
      'ClientAppVersionNumber': '1.0.0',
      'Surface': {
        r'$type': 'tqActions.States.SurfaceState, tqActions',
        'controls': controls,
        'EvType': '',
      },
      'RequestID': '',
      'UniqueID': _storage.uniqueId ?? uniqueId,
      'UserAgent': 'AyurlivDashboard/1.0',
      'ModuleName': module,
      'SubModuleName': scopedBranch,
      'UniqueCompanyID': _storage.accountId ?? '',
      'AccId': _storage.accountId ?? '',
      'ComponentName': '',
      'TabId': tabId,
      'LoginType': 'ERP_lOGIN',
      'Button': {
        r'$type': 'tqActions.States.ButtonState,tqActions',
        'ID': '',
        'WaterMarkText': '',
      },
      'AuthTocken': _storage.authToken ?? '',
    };
  }

  Map<String, dynamic> _hiddenControl(String id, String text) {
    return {
      'type': 'HIDDEN',
      'ID': id,
      'WaterMarkText': '',
      'Text': text,
    };
  }

  String _formatUniqueId(DateTime dt) {
    String pad(int v, [int w = 2]) => v.toString().padLeft(w, '0');
    return '${pad(dt.year, 4)}${pad(dt.month)}${pad(dt.day)}'
        '${pad(dt.hour)}${pad(dt.minute)}${pad(dt.second)}'
        '${pad(dt.millisecond, 3)}';
  }

  // ─────────────────────────────────────────────────────────────
  //  Decode + extract the answer
  // ─────────────────────────────────────────────────────────────
  Map<String, dynamic>? _decodeResponse(List<int> bytes) {
    try {
      String jsonString;
      if (bytes.length >= 2 && bytes[0] == 0x1f && bytes[1] == 0x8b) {
        AppLogger.info(_tag, 'response gzipped, decompressing...');
        final decompressed = GZipCodec().decode(bytes);
        jsonString = utf8.decode(decompressed);
      } else {
        AppLogger.info(_tag, 'response plain, decoding utf8...');
        jsonString = utf8.decode(bytes);
      }

      final raw = jsonDecode(jsonString);
      if (raw is! Map) return null;

      return _transformer.decompressResponse(raw.cast<String, dynamic>());
    } catch (e, st) {
      AppLogger.error(_tag, 'decode failed', error: e, stackTrace: st);
      return null;
    }
  }

  String _extractAIResponse(Map<String, dynamic> data) {
    final surface = (data['SufaceState'] ?? data['Surface']) as Map?;
    if (surface == null) return '';

    final controls = surface['Controls'] as List?;
    if (controls == null) return '';

    for (final c in controls) {
      if (c is Map && c['ID'] == 'hiddenAIResponse') {
        final text = c['Text'];
        if (text is String && text.trim().isNotEmpty) {
          return text;
        }
      }
    }
    return '';
  }
}
