import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/app_logger.dart';
import '../../../data/models/dashboard_data.dart';
import '../../../data/repositories/dashboard_repository.dart';

// ─────────────────────────────────────────────────────────────
//  Events
// ─────────────────────────────────────────────────────────────
abstract class DashboardEvent extends Equatable {
  const DashboardEvent();
  @override
  List<Object?> get props => [];
}

/// Initial load — shows the loading spinner.
class DashboardLoadRequested extends DashboardEvent {
  const DashboardLoadRequested();
}

/// Pull-to-refresh — does NOT show the spinner; previous data stays
/// on screen until the new data arrives.
class DashboardRefreshed extends DashboardEvent {
  const DashboardRefreshed();
}

/// Begin polling every `interval` seconds. Triggered when home becomes visible.
class DashboardPollingStarted extends DashboardEvent {
  final Duration interval;
  const DashboardPollingStarted({this.interval = const Duration(seconds: 5)});
  @override
  List<Object?> get props => [interval];
}

/// Stop polling. Triggered when leaving the home screen.
class DashboardPollingStopped extends DashboardEvent {
  const DashboardPollingStopped();
}

// ─────────────────────────────────────────────────────────────
//  State
// ─────────────────────────────────────────────────────────────
enum DashboardStatus { initial, loading, success, failure }

class DashboardState extends Equatable {
  final DashboardStatus status;
  final DashboardData? data;
  final String? errorMessage;

  const DashboardState({
    this.status = DashboardStatus.initial,
    this.data,
    this.errorMessage,
  });

  DashboardState copyWith({
    DashboardStatus? status,
    DashboardData? data,
    String? errorMessage,
  }) {
    return DashboardState(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, data, errorMessage];
}

// ─────────────────────────────────────────────────────────────
//  Bloc
// ─────────────────────────────────────────────────────────────
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  static const _tag = 'DashboardBloc';
  final DashboardRepository _repository;

  Timer? _pollTimer;

  DashboardBloc(this._repository) : super(const DashboardState()) {
    on<DashboardLoadRequested>(_onLoad);
    on<DashboardRefreshed>(_onRefresh);
    on<DashboardPollingStarted>(_onPollingStarted);
    on<DashboardPollingStopped>(_onPollingStopped);
  }

  Future<void> _onLoad(
      DashboardLoadRequested event, Emitter<DashboardState> emit) async {
    AppLogger.info(_tag, 'load (with spinner)');
    emit(state.copyWith(status: DashboardStatus.loading));
    await _fetch(emit);
  }

  Future<void> _onRefresh(
      DashboardRefreshed event, Emitter<DashboardState> emit) async {
    AppLogger.info(_tag, 'silent refresh');
    await _fetch(emit, silent: true);
  }

  Future<void> _fetch(Emitter<DashboardState> emit,
      {bool silent = false}) async {
    try {
      final data = await _repository.fetchDashboard();
      emit(state.copyWith(status: DashboardStatus.success, data: data));
    } catch (e, st) {
      AppLogger.error(_tag, silent ? 'silent fetch failed' : 'fetch failed',
          error: e, stackTrace: st);
      if (silent && state.data != null) {
        // Silent refresh: don't blow away the visible data on failure.
        // Just log and keep the previous state.
        return;
      }
      emit(state.copyWith(
        status: DashboardStatus.failure,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  void _onPollingStarted(
      DashboardPollingStarted event, Emitter<DashboardState> emit) {
    AppLogger.info(
        _tag, 'polling started — every ${event.interval.inSeconds}s');
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(event.interval, (_) {
      if (!isClosed) add(const DashboardRefreshed());
    });
  }

  void _onPollingStopped(
      DashboardPollingStopped event, Emitter<DashboardState> emit) {
    AppLogger.info(_tag, 'polling stopped');
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    _pollTimer = null;
    return super.close();
  }
}
