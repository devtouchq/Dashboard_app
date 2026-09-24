import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

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

/// One turn of the voice assistant: the answer to a spoken question as
/// text, plus the spoken version of that answer.
class SpeakResult {
  final bool isSuccess;
  final String? errorMessage;

  /// The assistant's answer as text, in the requested language. May be
  /// HTML like the SendMessage answers; see [replyPlainText].
  final String replyText;

  /// The plain sentence the server synthesised into speech (from
  /// hiddenAITtsText). Empty when the server did not send one.
  final String ttsText;

  /// The answer as synthesised speech, when the server embeds it in the
  /// response (base64). Null when it sends a URL instead, or no audio.
  final Uint8List? audioBytes;

  /// Where to stream the spoken answer from, when the server hosts it.
  final String? audioUrl;

  /// File extension matching the audio encoding (`mp3`, `wav`, `ogg`),
  /// so the player can be handed a correctly named temp file.
  final String audioExtension;

  const SpeakResult({
    required this.isSuccess,
    this.errorMessage,
    this.replyText = '',
    this.ttsText = '',
    this.audioBytes,
    this.audioUrl,
    this.audioExtension = 'mp3',
  });

  const SpeakResult.failure(String message)
      : this(isSuccess: false, errorMessage: message);

  bool get hasAudio =>
      (audioBytes != null && audioBytes!.isNotEmpty) ||
      (audioUrl != null && audioUrl!.isNotEmpty);

  /// Plain text of the answer for the voice screen: what was spoken if
  /// the server told us, otherwise [replyText] with its markup removed.
  String get replyPlainText =>
      ttsText.isNotEmpty ? ttsText : stripHtml(replyText);

  static final _tagPattern = RegExp(r'<[^>]*>');
  static final _spacePattern = RegExp(r'[ \t]+');
  static final _blankLines = RegExp(r'\n{3,}');

  static String stripHtml(String html) {
    if (!html.contains('<')) return html.trim();
    return html
        .replaceAll(RegExp(r'<\s*br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(
            RegExp(r'</\s*(p|div|li|tr|h[1-6])\s*>', caseSensitive: false),
            '\n')
        .replaceAll(_tagPattern, ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(_spacePattern, ' ')
        .replaceAll(_blankLines, '\n\n')
        .trim();
  }
}

/// Raw strings pulled out of the Speak response's surface controls.
class _SpeakControls {
  final String reply;
  final String ttsText;
  final String ttsLang;
  final String audioB64;
  final String audioUrl;
  final String encoding;

  const _SpeakControls({
    required this.reply,
    required this.ttsText,
    required this.ttsLang,
    required this.audioB64,
    required this.audioUrl,
    required this.encoding,
  });
}

/// Wraps /api/AIAssistant/SendMessage and /api/AIAssistant/Speak.
///
/// AI answers can take 30–90 seconds because the backend runs an LLM
/// query. The global DioClient timeout (30s) is too short for these
/// endpoints — we override `receiveTimeout` per request to give the AI
/// enough time to finish.
class ChatRepository {
  static const _tag = 'ChatRepository';
  static const _componentName = 'AyurvedadashboardComponent';

  /// How long to wait for the AI backend to respond. LLM inference can
  /// legitimately take a while — 2 minutes is a comfortable ceiling.
  static const _aiReceiveTimeout = Duration(minutes: 2);

  /// Send timeout is short because the compressed request body is small.
  static const _aiSendTimeout = Duration(seconds: 30);

  /// Audio uploads are much bigger than a question, and often go over a
  /// mobile connection.
  static const _audioSendTimeout = Duration(minutes: 2);

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
        options: _actionOptions(sendTimeout: _aiSendTimeout),
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

  /// Headers + timeouts every compressed AIAssistant action uses.
  Options _actionOptions({required Duration sendTimeout}) {
    return Options(
      headers: {
        Headers.contentTypeHeader: 'application/json',
        Headers.acceptHeader: 'application/json',
        'content-encoding': 'gzip',
        'accept-encoding': 'gzip, deflate',
        'User-Agent': 'AyurlivDashboard/1.0',
      },
      responseType: ResponseType.bytes,
      // Override the global DioClient timeouts. The AI backend runs an
      // LLM query which can take up to a minute or more — the global 30s
      // receiveTimeout was firing before the server had a chance to reply.
      sendTimeout: sendTimeout,
      receiveTimeout: _aiReceiveTimeout,
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Voice messages
  // ─────────────────────────────────────────────────────────────

  /// Endpoint that accepts a recorded voice message.
  ///
  /// ⚠️ NOT WIRED UP YET — fill this in when the backend endpoint exists.
  /// While it's empty, [sendAudio] fails with a clear message instead of
  /// posting to the wrong place.
  static const _audioEndpoint = '';

  /// Name of the multipart field holding the audio file.
  static const _audioFieldName = 'file';

  /// Uploads a recorded voice message (m4a / AAC).
  ///
  /// The multipart shape below is a placeholder: it sends the file plus
  /// the same identity fields every other call in this app uses. Adjust
  /// [_audioEndpoint], [_audioFieldName] and the fields below to match
  /// whatever the backend actually expects, and check how the answer
  /// comes back — [_extractAIResponse] assumes the same envelope the
  /// text endpoint returns.
  Future<ChatApiResponse> sendAudio(File audioFile,
      {Duration? duration}) async {
    if (_audioEndpoint.isEmpty) {
      AppLogger.info(_tag, 'sendAudio called but no endpoint is configured');
      return const ChatApiResponse(
        isSuccess: false,
        botMessage: '',
        errorMessage:
            'Voice messages are not enabled yet — the server endpoint is not configured.',
      );
    }

    final length = await audioFile.length();
    AppLogger.info(
        _tag, 'sendAudio → $length bytes, ${duration?.inSeconds ?? '?'}s');

    try {
      final form = FormData.fromMap({
        _audioFieldName: await MultipartFile.fromFile(
          audioFile.path,
          filename: audioFile.uri.pathSegments.last,
        ),
        'AccountId': _storage.accountId ?? '',
        'AuthToken': _storage.authToken ?? '',
        'Module': _storage.module ?? 'EMR',
        'SubModule': _storage.selectedBranch ?? '',
        'UniqueID': _storage.uniqueId ?? '',
        'DurationSeconds': duration?.inSeconds ?? 0,
      });

      final response = await _client.dio.post(
        _audioEndpoint,
        data: form,
        options: Options(
          responseType: ResponseType.bytes,
          sendTimeout: _audioSendTimeout,
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
        return const ChatApiResponse(
          isSuccess: false,
          botMessage: '',
          errorMessage: 'The assistant did not return an answer',
        );
      }

      return ChatApiResponse(isSuccess: true, botMessage: html, isHtml: true);
    } on DioException catch (e, st) {
      AppLogger.error(_tag, 'sendAudio failed', error: e, stackTrace: st);
      if (e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionTimeout) {
        return const ChatApiResponse(
          isSuccess: false,
          botMessage: '',
          errorMessage: 'Sending the voice message timed out. Please retry.',
        );
      }
      rethrow;
    } catch (e, st) {
      AppLogger.error(_tag, 'sendAudio failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  Voice assistant (question as text → answer as text + speech)
  // ─────────────────────────────────────────────────────────────

  /// Hidden controls the Speak action fills in, as seen in the web
  /// client's request: the answer to read out, the language it is in, and
  /// the synthesised audio. They are sent empty and come back filled.
  static const _ctlTtsText = 'hiddenAITtsText';
  static const _ctlTtsLang = 'hiddenAITtsLang';
  static const _ctlTtsAudio = 'hiddenAITtsAudio';

  /// POST {baseUrl}/api/AIAssistant/Speak
  ///
  /// Speech is recognised on the phone; [text] is what the user said.
  /// The server answers it in [languageCode] and returns the answer as
  /// text plus Google Cloud Text-to-Speech audio in the same language.
  ///
  /// Request: the same compressed ButtonClickedActionArgs envelope as
  /// [sendMessage], mirroring the web client — hiddenSelectedCompany,
  /// hiddenSelectedModule, hiddenAIQuestion = [text],
  /// hiddenAIResponse = "", hiddenAIContext (with `language` set to
  /// [languageCode]), hiddenAITtsText = "", hiddenAITtsLang = "",
  /// hiddenAITtsAudio = "".
  ///
  /// Response: the usual envelope. The answer is read from
  /// hiddenAIResponse (HTML) and hiddenAITtsText (plain, what is spoken);
  /// the audio from hiddenAITtsAudio (base64 or a URL), falling back to
  /// the envelope's `DownloadUrl`.
  Future<SpeakResult> speak({
    required String text,
    required String languageCode,
  }) async {
    final question = text.trim();
    if (question.isEmpty) {
      return const SpeakResult.failure("Didn't catch that — tap to try again.");
    }
    AppLogger.info(
        _tag, 'speak → question="${question.length} chars", lang=$languageCode');

    final body = _buildActionArgs(
      languageCode: languageCode,
      extraControls: [
        _hiddenControl('hiddenAIQuestion', question),
        _hiddenControl('hiddenAIResponse', ''),
      ],
      trailingControls: [
        _hiddenControl(_ctlTtsText, ''),
        _hiddenControl(_ctlTtsLang, ''),
        _hiddenControl(_ctlTtsAudio, ''),
      ],
    );

    try {
      final compressedPayload = _transformer.compressRequest(body);
      AppLogger.info(
          _tag, 'speak request compressed to ${compressedPayload.length} chars');

      final response = await _client.dio.post(
        '/api/AIAssistant/Speak',
        data: compressedPayload,
        options: _actionOptions(sendTimeout: _aiSendTimeout),
      );

      if (response.statusCode != 200) {
        return SpeakResult.failure('Server returned ${response.statusCode}');
      }

      final data = _decodeResponse(response.data as List<int>);
      if (data == null) {
        return const SpeakResult.failure('Could not read server response');
      }

      final actionMessage = (data['ActionMessage'] ?? '').toString().trim();
      if (data['IsSuccess'] == false ||
          data['ActionCancelled'] == true ||
          data['Cancelled'] == true) {
        return SpeakResult.failure(actionMessage.isEmpty
            ? 'The assistant could not answer that.'
            : actionMessage);
      }

      final found = _readSpeakControls(data);

      // The framework also has a generic download slot; a hosted TTS file
      // would arrive there.
      var audioUrl = found.audioUrl;
      if (audioUrl.isEmpty) {
        final dl = (data['DownloadUrl'] ?? '').toString().trim();
        if (dl.isNotEmpty) audioUrl = dl;
      }

      // The HTML answer normally arrives in hiddenAIResponse; when only
      // the spoken text came back, show that. A text answer with nothing
      // else usable can still live in ActionMessage (the server's way of
      // talking to the user).
      var reply = found.reply.isNotEmpty ? found.reply : found.ttsText;
      if (reply.isEmpty && found.audioB64.isEmpty && audioUrl.isEmpty) {
        reply = actionMessage;
      }

      if (reply.isEmpty && found.audioB64.isEmpty && audioUrl.isEmpty) {
        AppLogger.info(_tag,
            'speak: nothing usable in response. Top-level keys: ${data.keys.toList()}');
        return const SpeakResult.failure(
            'The assistant did not return an answer');
      }

      Uint8List? audioBytes;
      if (found.audioB64.isNotEmpty) {
        try {
          audioBytes = base64Decode(_stripDataUri(found.audioB64));
        } catch (e) {
          AppLogger.info(_tag, 'speak: audio was not valid base64 ($e)');
        }
      }

      AppLogger.info(_tag,
          'speak ← reply=${reply.length}ch tts=${found.ttsText.length}ch lang=${found.ttsLang} audio=${audioBytes?.length ?? 0}B url=${audioUrl.isNotEmpty}');

      return SpeakResult(
        isSuccess: true,
        replyText: reply,
        ttsText: found.ttsText,
        audioBytes: audioBytes,
        audioUrl: audioUrl.isEmpty ? null : audioUrl,
        audioExtension: _audioExtensionFor(found.encoding, audioUrl),
      );
    } on DioException catch (e, st) {
      AppLogger.error(_tag, 'speak failed', error: e, stackTrace: st);
      if (e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionTimeout) {
        return const SpeakResult.failure(
            'The assistant is taking longer than usual. Please try again.');
      }
      final code = e.response?.statusCode;
      return SpeakResult.failure(code != null
          ? 'Server returned $code'
          : 'Network error. Please try again.');
    } catch (e, st) {
      AppLogger.error(_tag, 'speak failed', error: e, stackTrace: st);
      return const SpeakResult.failure(
          'Something went wrong. Please try again.');
    }
  }

  /// Pulls the Speak outputs out of the surface controls.
  ///
  /// Exact IDs are preferred; failing that, the ID is matched by what it
  /// contains (`audio`, `response`…) so a rename on the server still
  /// works. Every control ID and text length is logged so a mismatch is
  /// obvious from the log.
  _SpeakControls _readSpeakControls(Map<String, dynamic> data) {
    final controls = <String, String>{}; // lower-case ID → text
    final surface = (data['SufaceState'] ?? data['Surface']) as Map?;
    final list = surface?['Controls'] ?? surface?['controls'];
    if (list is List) {
      for (final c in list) {
        if (c is! Map) continue;
        final id = c['ID']?.toString();
        if (id == null || id.isEmpty) continue;
        final text = c['Text'];
        controls[id.toLowerCase()] = text is String ? text.trim() : '';
      }
    }
    AppLogger.info(_tag,
        'speak controls: ${controls.entries.map((e) => '${e.key}=${e.value.length}ch').join(', ')}');

    String exact(String id) => controls[id.toLowerCase()] ?? '';
    String firstWhere(bool Function(String id) test) {
      for (final e in controls.entries) {
        if (e.value.isNotEmpty && test(e.key)) return e.value;
      }
      return '';
    }

    bool isAudioId(String id) =>
        id.contains('audio') || id.contains('speech') || id.contains('voice');
    bool looksLikeUrl(String s) =>
        s.startsWith('http://') || s.startsWith('https://') || s.startsWith('/');

    var reply = exact('hiddenAIResponse');
    if (reply.isEmpty) {
      reply = firstWhere((id) =>
          !isAudioId(id) &&
          !id.contains('tts') &&
          (id.contains('response') ||
              id.contains('answer') ||
              id.contains('reply')));
    }

    final ttsText = exact(_ctlTtsText);
    final ttsLang = exact(_ctlTtsLang);

    var audioB64 = '';
    var audioUrl = '';
    final audioCandidates = <String>[
      exact(_ctlTtsAudio),
      firstWhere((id) => isAudioId(id) && !id.contains('encoding')),
    ];
    for (final v in audioCandidates) {
      if (v.isEmpty) continue;
      if (looksLikeUrl(v)) {
        audioUrl = v;
      } else {
        audioB64 = v;
      }
      break;
    }

    final encoding =
        firstWhere((id) => isAudioId(id) && id.contains('encoding'));

    return _SpeakControls(
      reply: reply,
      ttsText: ttsText,
      ttsLang: ttsLang,
      audioB64: audioB64,
      audioUrl: audioUrl,
      encoding: encoding,
    );
  }

  /// `data:audio/mp3;base64,AAAA…` → `AAAA…`
  String _stripDataUri(String s) {
    if (!s.startsWith('data:')) return s;
    final comma = s.indexOf(',');
    return comma < 0 ? s : s.substring(comma + 1);
  }

  String _audioExtensionFor(String encoding, String url) {
    final e = encoding.toUpperCase();
    if (e.contains('LINEAR16') || e.contains('WAV')) return 'wav';
    if (e.contains('OGG') || e.contains('OPUS')) return 'ogg';
    if (e.contains('MP3') || e.contains('MPEG')) return 'mp3';
    final lower = url.toLowerCase();
    if (lower.endsWith('.wav')) return 'wav';
    if (lower.endsWith('.ogg') || lower.endsWith('.opus')) return 'ogg';
    return 'mp3';
  }

  // ─────────────────────────────────────────────────────────────
  //  Build the ButtonClickedActionArgs payload
  // ─────────────────────────────────────────────────────────────
  Map<String, dynamic> _buildRequestBody(String question) {
    return _buildActionArgs(extraControls: [
      _hiddenControl('hiddenAIQuestion', question),
      _hiddenControl('hiddenAIResponse', ''),
    ]);
  }

  /// The envelope every AIAssistant action takes: identity, client info
  /// and a surface holding the company/module hidden controls, then
  /// [extraControls], then hiddenAIContext, then [trailingControls] —
  /// the order the web client sends them in. [languageCode], when given,
  /// goes into the context as `language` (the Speak action reads the
  /// answer/speech language from there).
  Map<String, dynamic> _buildActionArgs({
    required List<Map<String, dynamic>> extraControls,
    List<Map<String, dynamic>> trailingControls = const [],
    String? languageCode,
  }) {
    final now = DateTime.now();
    final module = _storage.module ?? 'OPModule';
    final selectedBranch = _storage.selectedBranch ?? '';
    final scopedBranch =
        selectedBranch.toUpperCase() == 'ALL' ? '' : selectedBranch;
    final aiContext = jsonEncode({
      'module': module,
      'subModule': scopedBranch,
      'componentName': _componentName,
      if (languageCode != null) 'language': languageCode,
    });

    final uniqueId = _formatUniqueId(now);
    final tabId =
        '${now.millisecondsSinceEpoch}.${_random.nextInt(9999).toString().padLeft(4, '0')}';

    final controls = [
      _hiddenControl('hiddenSelectedCompany', scopedBranch),
      _hiddenControl('hiddenSelectedModule', module),
      ...extraControls,
      _hiddenControl('hiddenAIContext', aiContext),
      ...trailingControls,
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
