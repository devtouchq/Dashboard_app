import 'package:shared_preferences/shared_preferences.dart';

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

  late final SharedPreferences _prefs;

  /// Call once at app start before runApp().
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    AppLogger.info(_tag, 'initialized. baseUrl="${baseUrl ?? ''}"');
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

  // ─── Remember me ─────────────────────────────────────────
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

  // ─── Clear / logout ──────────────────────────────────────
  Future<void> clearSession() async {
    AppLogger.info(_tag, 'clearSession');
    await Future.wait([
      _prefs.remove(_kAccountId),
      _prefs.remove(_kAuthToken),
      _prefs.remove(_kUserId),
      _prefs.remove(_kModule),
      _prefs.remove(_kUniqueId),
      _prefs.remove(_kSelectedBranch),
    ]);
  }

  /// Wipe everything — used to reset the app to its first-launch state.
  Future<void> clearAll() async {
    AppLogger.info(_tag, 'clearAll');
    await _prefs.clear();
  }
}
