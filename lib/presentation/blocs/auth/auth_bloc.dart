import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/local_storage_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/models/auth_data.dart';
import '../../../data/repositories/auth_repository.dart';

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

  AuthBloc(this._repository, this._storage) : super(const AuthState()) {
    on<BaseUrlSubmitted>(_onBaseUrlSubmitted);
    on<LoginSubmitted>(_onLoginSubmitted);
    on<BranchSelected>(_onBranchSelected);
    on<LogoutRequested>(_onLogout);
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
      final res = await _repository.login(LoginRequest(
        accId: event.accountId.trim(),
        username: event.username.trim(),
        password: event.password,
      ));

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

      emit(state.copyWith(
        status: AuthStatus.loginSuccess,
        branches: res.branchList,
      ));
    } catch (e, st) {
      AppLogger.error(_tag, 'login failed', error: e, stackTrace: st);
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
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
    AppLogger.info(_tag, 'LogoutRequested');
    await _storage.clearSession();
    emit(const AuthState());
  }

  /// Normalize URL:
  /// - trim, strip trailing slashes
  /// - if no scheme present:
  ///     * LAN IPs (192.168.x.x, 10.x.x.x, 172.16-31.x.x) → http://
  ///     * localhost → http://
  ///     * everything else → https://
  String _cleanUrl(String input) {
    var u = input.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    if (u.startsWith('http://') || u.startsWith('https://')) {
      return u;
    }

    // Extract the host part (everything up to the first '/' or ':')
    var host = u;
    final slashIdx = host.indexOf('/');
    if (slashIdx >= 0) host = host.substring(0, slashIdx);
    final colonIdx = host.indexOf(':');
    if (colonIdx >= 0) host = host.substring(0, colonIdx);

    // LAN ranges → HTTP (almost always)
    final isLocalHost = host == 'localhost' || host == '127.0.0.1';
    final isPrivateIp = _isPrivateIp(host);

    final scheme = (isLocalHost || isPrivateIp) ? 'http' : 'https';
    return '$scheme://$u';
  }

  /// Returns true for RFC 1918 private IPs and link-local 169.254.x.x.
  bool _isPrivateIp(String host) {
    final parts = host.split('.');
    if (parts.length != 4) return false;
    final nums = parts.map(int.tryParse).toList();
    if (nums.any((n) => n == null || n < 0 || n > 255)) return false;
    final a = nums[0]!;
    final b = nums[1]!;
    if (a == 10) return true; // 10.0.0.0/8
    if (a == 192 && b == 168) return true; // 192.168.0.0/16
    if (a == 172 && b >= 16 && b <= 31) return true; // 172.16.0.0/12
    if (a == 169 && b == 254) return true; // link-local
    return false;
  }
}
