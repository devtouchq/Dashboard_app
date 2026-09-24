import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/auth_data.dart';
import '../utils/app_logger.dart';

/// Single point of access for everything we persist on the device.
/// Keys are kept private so screens can't typo them.
class LocalStorageService {
  static const _tag = 'LocalStorage';

  // ─── Keys ────────────────────────────────────────────────
  static const _kBaseUrl = 'base_url';
  static const _kAccountId = 'account_id';
  static const _kAuthToken = 'auth_token';
  static const _kUserId = 'user_id';
  static const _kModule = 'module';
  static const _kUniqueId = 'unique_id';
  static const _kSelectedBranch = 'selected_branch';
  static const _kRememberMe = 'remember_me';
  static const _kSavedUsername = 'saved_username';
  static const _kSavedAccountId = 'saved_account_id';
  static const _kBranchList = 'branch_list';
  static const _kVoiceLanguage = 'voice_language';
  static const _kVoiceMuted = 'voice_muted';

  late final SharedPreferences _prefs;

  /// Call once at app start before runApp().
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    // Diagnostic: log what's already in storage on startup. Useful for
    // debugging "branches missing on cold start".
    final saved = branchList;
    AppLogger.info(_tag,
        'initialized. baseUrl="${baseUrl ?? ''}" persistedBranches=${saved.length}');
  }

  // ─── Base URL ────────────────────────────────────────────
  Future<bool> setBaseUrl(String url) {
    AppLogger.info(_tag, 'setBaseUrl: $url');
    return _prefs.setString(_kBaseUrl, url);
  }

  String? get baseUrl => _prefs.getString(_kBaseUrl);

  Future<bool> clearBaseUrl() {
    AppLogger.info(_tag, 'clearBaseUrl');
    return _prefs.remove(_kBaseUrl);
  }

  // ─── Auth session ────────────────────────────────────────
  Future<void> saveSession({
    required String accountId,
    required String authToken,
    required String userId,
    required String module,
    required String uniqueId,
  }) async {
    AppLogger.info(_tag, 'saveSession for $userId');
    await Future.wait([
      _prefs.setString(_kAccountId, accountId),
      _prefs.setString(_kAuthToken, authToken),
      _prefs.setString(_kUserId, userId),
      _prefs.setString(_kModule, module),
      _prefs.setString(_kUniqueId, uniqueId),
    ]);
  }

  String? get accountId => _prefs.getString(_kAccountId);
  String? get authToken => _prefs.getString(_kAuthToken);
  String? get userId => _prefs.getString(_kUserId);
  String? get module => _prefs.getString(_kModule);
  String? get uniqueId => _prefs.getString(_kUniqueId);

  bool get hasSession =>
      (authToken != null && authToken!.isNotEmpty) &&
      (userId != null && userId!.isNotEmpty);

  // ─── Branch ──────────────────────────────────────────────
  Future<bool> setSelectedBranch(String branchValue) {
    AppLogger.info(_tag, 'setSelectedBranch: $branchValue');
    return _prefs.setString(_kSelectedBranch, branchValue);
  }

  String? get selectedBranch => _prefs.getString(_kSelectedBranch);

  /// Persist the branch list so it survives cold-starts (when the user
  /// doesn't need to log in again). Called from AuthBloc after login.
  Future<void> setBranchList(List<Branch> branches) async {
    final jsonList =
        branches.map((b) => {'text': b.text, 'value': b.value}).toList();
    final encoded = jsonEncode(jsonList);
    await _prefs.setString(_kBranchList, encoded);
    AppLogger.info(
        _tag, 'setBranchList: ${branches.length} branches saved to prefs');
  }

  /// Read the persisted branch list. Returns empty list if none saved.
  /// Called at cold-start from AuthBloc's bootstrap handler.
  List<Branch> get branchList {
    final raw = _prefs.getString(_kBranchList);
    if (raw == null || raw.isEmpty) {
      AppLogger.info(_tag, 'branchList getter: no persisted branches found');
      return const [];
    }
    try {
      final decoded = jsonDecode(raw) as List;
      final list = decoded.map((e) {
        final map = e as Map;
        return Branch(
          text: map['text']?.toString() ?? '',
          value: map['value']?.toString() ?? '',
        );
      }).toList();
      AppLogger.info(
          _tag, 'branchList getter: restored ${list.length} branches');
      return list;
    } catch (e) {
      AppLogger.error(_tag, 'branchList decode failed: $e');
      return const [];
    }
  }

  // ────────────────── Remember me ─────────────────────
  Future<void> setRememberMe({
    required bool remember,
    String? accountId,
    String? username,
  }) async {
    await _prefs.setBool(_kRememberMe, remember);
    if (remember) {
      if (accountId != null) {
        await _prefs.setString(_kSavedAccountId, accountId);
      }
      if (username != null) {
        await _prefs.setString(_kSavedUsername, username);
      }
    } else {
      await _prefs.remove(_kSavedAccountId);
      await _prefs.remove(_kSavedUsername);
    }
  }

  bool get rememberMe => _prefs.getBool(_kRememberMe) ?? false;
  String? get savedAccountId => _prefs.getString(_kSavedAccountId);
  String? get savedUsername => _prefs.getString(_kSavedUsername);

  // ───────────────── Voice assistant ────────────
  /// BCP-47 code of the language the voice assistant listens and replies
  /// in, e.g. `en-IN`. Null until the user picks one.
  String? get voiceLanguageCode => _prefs.getString(_kVoiceLanguage);

  Future<bool> setVoiceLanguageCode(String code) {
    AppLogger.info(_tag, 'setVoiceLanguageCode: $code');
    return _prefs.setString(_kVoiceLanguage, code);
  }

  /// Whether the spoken reply is muted. Survives the session so a user
  /// who muted once isn't blasted with audio next time.
  bool get voiceMuted => _prefs.getBool(_kVoiceMuted) ?? false;

  Future<bool> setVoiceMuted(bool muted) => _prefs.setBool(_kVoiceMuted, muted);

  // ───────────────── Clear / logout ────────────
  /// Clear the login session but keep baseUrl and remember-me info.
  /// User will land on LoginScreen with prefilled Account ID/Username.
  Future<void> clearSession() async {
    AppLogger.info(_tag, 'clearSession');
    await Future.wait([
      _prefs.remove(_kAccountId),
      _prefs.remove(_kAuthToken),
      _prefs.remove(_kUserId),
      _prefs.remove(_kModule),
      _prefs.remove(_kUniqueId),
      _prefs.remove(_kSelectedBranch),
      _prefs.remove(_kBranchList), // ← branch list belongs to the session
    ]);
  }

  /// Wipe everything — used to reset the app to its first-launch state.
  /// User will see BaseUrlScreen next.
  Future<void> clearAll() async {
    AppLogger.info(_tag, 'clearAll');
    // _prefs.clear() already wipes everything including _kBranchList.
    // The explicit remove was redundant (kept for readability but no-op).
    await _prefs.clear();
  }
}
