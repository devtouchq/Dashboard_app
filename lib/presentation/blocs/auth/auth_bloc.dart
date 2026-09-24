import 'dart:async';
import 'dart:io' show Platform;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/local_storage_service.dart';
import '../../../core/network/network_exceptions.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/models/auth_data.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/device_token_repo.dart';

// ─────────────────────────────────────────────────────────────
//  Events
// ─────────────────────────────────────────────────────────────
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class BaseUrlSubmitted extends AuthEvent {
  final String url;
  const BaseUrlSubmitted(this.url);
  @override
  List<Object?> get props => [url];
}

class LoginSubmitted extends AuthEvent {
  final String accountId;
  final String username;
  final String password;
  final bool rememberMe;
  const LoginSubmitted({
    required this.accountId,
    required this.username,
    required this.password,
    required this.rememberMe,
  });
  @override
  List<Object?> get props => [accountId, username, password, rememberMe];
}

class BranchSelected extends AuthEvent {
  final Branch branch;
  const BranchSelected(this.branch);
  @override
  List<Object?> get props => [branch];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

/// Fired on app startup (from RouteGate) to rehydrate persisted state
/// like the branch list — so the drawer isn't empty when the user opens
/// the app the next day without going through login again.
class AuthBootstrapped extends AuthEvent {
  const AuthBootstrapped();
}

// ─────────────────────────────────────────────────────────────
//  State
// ─────────────────────────────────────────────────────────────
enum AuthStatus {
  initial,
  baseUrlSaving,
  baseUrlSaved,
  loggingIn,
  loginSuccess,
  branchSelected,
  failure,
  loggedOut,
  loading,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final List<Branch> branches;
  final Branch? selectedBranch;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.branches = const [],
    this.selectedBranch,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    List<Branch>? branches,
    Branch? selectedBranch,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      branches: branches ?? this.branches,
      selectedBranch: selectedBranch ?? this.selectedBranch,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, branches, selectedBranch, errorMessage];
}

// ─────────────────────────────────────────────────────────────
//  Bloc
// ─────────────────────────────────────────────────────────────
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  static const _tag = 'AuthBloc';
  final AuthRepository _repository;
  final LocalStorageService _storage;
  final DeviceTokenRepository _deviceTokenRepo;

  StreamSubscription<String>? _tokenSub;

  AuthBloc(this._repository, this._storage, this._deviceTokenRepo)
      : super(const AuthState()) {
    on<BaseUrlSubmitted>(_onBaseUrlSubmitted);
    on<LoginSubmitted>(_onLoginSubmitted);
    on<BranchSelected>(_onBranchSelected);
    on<LogoutRequested>(_onLogout);
    on<AuthBootstrapped>(_onBootstrapped);

    // Listen for FCM token rotations.
    // Important: NotificationService.init() also emits the FIRST token on
    // this stream at app startup. At that moment the user is usually not
    // logged in yet, so the guard below short-circuits. That's correct —
    // the actual first registration happens in _onLoginSubmitted after
    // a successful login. This listener handles only true rotations
    // while a user IS already logged in.
    _tokenSub = NotificationService.tokenStream.listen((newToken) {
      final userId = _storage.userId;
      final authToken = _storage.authToken;
      if (userId == null ||
          userId.isEmpty ||
          authToken == null ||
          authToken.isEmpty) {
        return; // not logged in — nothing to re-register
      }
      AppLogger.info(_tag, 'token rotated → re-registering with backend');
      _deviceTokenRepo.registerDeviceToken(
        userId: userId,
        accountId: _storage.accountId ?? '',
        authToken: authToken,
        fcmToken: newToken,
      );
    });
  }

  // ─────────────────────────────────────────────────────────────
  //  Rehydrate persisted state on app cold-start.
  //  Called from RouteGate before deciding which screen to show.
  // ─────────────────────────────────────────────────────────────
  Future<void> _onBootstrapped(
      AuthBootstrapped event, Emitter<AuthState> emit) async {
    final savedBranches = _storage.branchList;
    if (savedBranches.isNotEmpty) {
      AppLogger.info(
          _tag, 'bootstrap: restoring ${savedBranches.length} branches');
      emit(state.copyWith(branches: savedBranches));
    } else {
      AppLogger.info(_tag, 'bootstrap: no persisted branches');
    }
  }

  Future<void> _onBaseUrlSubmitted(
      BaseUrlSubmitted event, Emitter<AuthState> emit) async {
    AppLogger.info(_tag, 'BaseUrlSubmitted: raw="${event.url}"');
    emit(state.copyWith(status: AuthStatus.baseUrlSaving));
    try {
      final cleaned = _cleanUrl(event.url);
      AppLogger.info(_tag, 'BaseUrlSubmitted: cleaned="$cleaned"');
      await _storage.setBaseUrl(cleaned);
      emit(state.copyWith(status: AuthStatus.baseUrlSaved));
      // Not awaited: this only exists to make iOS show its Local Network
      // prompt now, on the setup screen, rather than during login.
      unawaited(_repository.warmUp());
    } catch (e, st) {
      AppLogger.error(_tag, 'baseUrl save failed', error: e, stackTrace: st);
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoginSubmitted(
      LoginSubmitted event, Emitter<AuthState> emit) async {
    AppLogger.info(_tag, 'LoginSubmitted');
    emit(state.copyWith(status: AuthStatus.loggingIn));
    try {
      final request = LoginRequest(
        accId: event.accountId.trim(),
        username: event.username.trim(),
        password: event.password,
      );

      LoginResponse res;
      try {
        res = await _repository.login(request);
      } on ServerUnreachableException catch (e) {
        // On a fresh iOS install the first request to a LAN server is
        // what triggers the Local Network prompt, and that request fails
        // while the prompt is up. One retry a moment later succeeds once
        // the user has tapped Allow.
        AppLogger.info(_tag, 'server unreachable (${e.detail}), retrying once');
        await Future<void>.delayed(_unreachableRetryDelay);
        res = await _repository.login(request);
      }

      if (!res.isSuccess) {
        emit(state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'Invalid credentials',
        ));
        return;
      }

      await _storage.saveSession(
        accountId: res.accountId,
        authToken: res.authToken,
        userId: res.userId,
        module: res.module,
        uniqueId: res.uniqueId,
      );

      await _storage.setRememberMe(
        remember: event.rememberMe,
        accountId: event.accountId,
        username: event.username,
      );

      // Register the device's FCM token with the backend so it can
      // target this user. Wrapped in try/catch so push registration
      // failure doesn't block the login flow.
      await _registerDeviceTokenIfAvailable(
        userId: res.userId,
        accountId: res.accountId,
        authToken: res.authToken,
      );

      // Prepend an "ALL" pseudo-branch so the user can view a consolidated
      // dashboard across every branch. The dashboard API receives "ALL" as
      // the SubModule value and is expected to handle it server-side.
      final branchesWithAll = <Branch>[
        const Branch(text: 'ALL', value: 'ALL'),
        ...res.branchList,
      ];

      // PERSIST branches so cold-starts (no fresh login) can restore them
      // via AuthBootstrapped. Without this, the drawer would be empty
      // the next time the user opens the app.
      await _storage.setBranchList(branchesWithAll);

      emit(state.copyWith(
        status: AuthStatus.loginSuccess,
        branches: branchesWithAll,
      ));

      // Now that the user is in, ask for notification permission and get
      // the push token. Not awaited: login must not wait on APNS. When
      // the token arrives, the tokenStream listener registers it because
      // the session is already saved.
      unawaited(NotificationService.ensureInitialized());
    } on ServerUnreachableException catch (e, st) {
      AppLogger.error(_tag, 'login: server unreachable', error: e, stackTrace: st);
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: _unreachableMessage(),
      ));
    } catch (e, st) {
      AppLogger.error(_tag, 'login failed', error: e, stackTrace: st);
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  static const _unreachableRetryDelay = Duration(milliseconds: 1500);

  /// What to tell the user when the server never answered. For a server
  /// on the local network on iOS, the usual cause is the Local Network
  /// permission having been denied, so say exactly where to fix it.
  String _unreachableMessage() {
    final host = Uri.tryParse(_storage.baseUrl ?? '')?.host ?? '';
    final onLan = _isPrivateIp(host) ||
        host == 'localhost' ||
        host.endsWith('.local') ||
        (host.isNotEmpty && !host.contains('.'));
    if (Platform.isIOS && onLan) {
      return "Couldn't reach the server at $host. Allow Local Network access "
          'for Ayurlive Dashboard in Settings › Privacy & Security › Local '
          'Network, make sure this phone is on the same Wi-Fi as the '
          'server, then try again.';
    }
    return "Couldn't reach the server${host.isEmpty ? '' : ' at $host'}. "
        'Check the server address and your internet connection, then try again.';
  }

  /// Helper: attempt to register the current device's FCM token with the
  /// backend. Silent failures by design — push setup must never block login.
  Future<void> _registerDeviceTokenIfAvailable({
    required String userId,
    required String accountId,
    required String authToken,
  }) async {
    final fcmToken = NotificationService.fcmToken;
    if (fcmToken == null || fcmToken.isEmpty) {
      AppLogger.info(_tag, 'no FCM token yet — skipping registration');
      return;
    }
    try {
      await _deviceTokenRepo.registerDeviceToken(
        userId: userId,
        accountId: accountId,
        authToken: authToken,
        fcmToken: fcmToken,
      );
    } catch (e) {
      AppLogger.error(_tag, 'device token register failed: $e');
    }
  }

  Future<void> _onBranchSelected(
      BranchSelected event, Emitter<AuthState> emit) async {
    AppLogger.info(_tag, 'BranchSelected: ${event.branch.text}');
    await _storage.setSelectedBranch(event.branch.value);
    emit(state.copyWith(
      status: AuthStatus.branchSelected,
      selectedBranch: event.branch,
    ));
  }

  Future<void> _onLogout(LogoutRequested event, Emitter<AuthState> emit) async {
    AppLogger.info(_tag, 'logout requested');

    // Grab credentials BEFORE clearing storage, since the APIs need them.
    final authToken = _storage.authToken ?? '';
    final userId = _storage.userId ?? '';
    final accountId = _storage.accountId ?? '';
    final uniqueId = _storage.uniqueId ?? '';
    final fcmToken = NotificationService.fcmToken;

    emit(state.copyWith(status: AuthStatus.loading));

    // 1. Unregister this device from the backend so it stops pushing.
    if (fcmToken != null &&
        fcmToken.isNotEmpty &&
        authToken.isNotEmpty &&
        userId.isNotEmpty) {
      try {
        await _deviceTokenRepo.unregisterDeviceToken(
          userId: userId,
          authToken: authToken,
          fcmToken: fcmToken,
        );
      } catch (e) {
        AppLogger.error(_tag, 'device token unregister failed: $e');
      }
    }

    // 2. Delete the local FCM token so a new one is issued for next login.
    try {
      await NotificationService.deleteToken();
    } catch (e) {
      AppLogger.error(_tag, 'FCM deleteToken failed: $e');
    }

    // 3. Call the logout API. Even if it fails, we still clear storage —
    //    otherwise a logged-out user could be stuck with stale credentials.
    try {
      await _repository.logout(
        authToken: authToken,
        userId: userId,
        accountId: accountId,
        uniqueId: uniqueId,
      );
    } catch (e) {
      AppLogger.error(_tag, 'logout repo threw — clearing storage anyway',
          error: e);
    }

    // 4. Wipe EVERYTHING — baseUrl, session, remember-me, branches.
    //    User will see BaseUrlScreen on next launch.
    await _storage.clearAll();

    // Also clear the in-memory branches state so the drawer is empty
    // right away (not just on next cold-start).
    emit(const AuthState(status: AuthStatus.loggedOut));
  }

  @override
  Future<void> close() {
    _tokenSub?.cancel();
    return super.close();
  }

  /// Normalize URL — same as before, no changes.
  String _cleanUrl(String input) {
    var u = input.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    if (u.startsWith('http://') || u.startsWith('https://')) {
      return u;
    }

    var host = u;
    final slashIdx = host.indexOf('/');
    if (slashIdx >= 0) host = host.substring(0, slashIdx);
    final colonIdx = host.indexOf(':');
    if (colonIdx >= 0) host = host.substring(0, colonIdx);

    final isLocalHost = host == 'localhost' || host == '127.0.0.1';
    final isPrivateIp = _isPrivateIp(host);

    final scheme = (isLocalHost || isPrivateIp) ? 'http' : 'https';
    return '$scheme://$u';
  }

  bool _isPrivateIp(String host) {
    final parts = host.split('.');
    if (parts.length != 4) return false;
    final nums = parts.map(int.tryParse).toList();
    if (nums.any((n) => n == null || n < 0 || n > 255)) return false;
    final a = nums[0]!;
    final b = nums[1]!;
    if (a == 10) return true;
    if (a == 192 && b == 168) return true;
    if (a == 172 && b >= 16 && b <= 31) return true;
    if (a == 169 && b == 254) return true;
    return false;
  }
}
