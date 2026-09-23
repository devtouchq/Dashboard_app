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

class DashboardLoadRequested extends DashboardEvent {
  const DashboardLoadRequested();
}

class DashboardRefreshed extends DashboardEvent {
  const DashboardRefreshed();
}

class DashboardPollingStarted extends DashboardEvent {
  final Duration interval;
  const DashboardPollingStarted(
      {this.interval = DashboardBloc.defaultPollInterval});
  @override
  List<Object?> get props => [interval];
}

class DashboardPollingStopped extends DashboardEvent {
  const DashboardPollingStopped();
}

/// Changes the date range the dashboard is fetched for. Pass both as
/// null to go back to "today".
class DashboardDateRangeChanged extends DashboardEvent {
  final DateTime? fromDate;
  final DateTime? toDate;
  const DashboardDateRangeChanged({this.fromDate, this.toDate});
  @override
  List<Object?> get props => [fromDate, toDate];
}

// ─────────────────────────────────────────────────────────────
//  State
// ─────────────────────────────────────────────────────────────
enum DashboardStatus { initial, loading, success, failure }

class DashboardState extends Equatable {
  final DashboardStatus status;
  final DashboardData? data;
  final String? errorMessage;

  /// User-selected range. Null means "today" — resolved at fetch time so
  /// the dashboard rolls over to the new day automatically at midnight.
  final DateTime? fromDate;
  final DateTime? toDate;

  const DashboardState({
    this.status = DashboardStatus.initial,
    this.data,
    this.errorMessage,
    this.fromDate,
    this.toDate,
  });

  bool get hasCustomRange => fromDate != null && toDate != null;

  DateTime get effectiveFromDate => fromDate ?? _today();
  DateTime get effectiveToDate => toDate ?? _today();

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DashboardState copyWith({
    DashboardStatus? status,
    DashboardData? data,
    String? errorMessage,
  }) {
    return DashboardState(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage,
      fromDate: fromDate,
      toDate: toDate,
    );
  }

  @override
  List<Object?> get props => [status, data, errorMessage, fromDate, toDate];
}

// ─────────────────────────────────────────────────────────────
//  Bloc
// ─────────────────────────────────────────────────────────────
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  static const _tag = 'DashboardBloc';
  static const defaultPollInterval = Duration(seconds: 10);
  final DashboardRepository _repository;

  Timer? _pollTimer;
  int _requestSeq = 0;

  DashboardBloc(this._repository) : super(const DashboardState()) {
    on<DashboardLoadRequested>(_onLoad);
    on<DashboardRefreshed>(_onRefresh);
    on<DashboardPollingStarted>(_onPollingStarted);
    on<DashboardPollingStopped>(_onPollingStopped);
    on<DashboardDateRangeChanged>(_onDateRangeChanged);
  }

  Future<void> _onLoad(
      DashboardLoadRequested event, Emitter<DashboardState> emit) async {
    AppLogger.info(_tag, 'load (with spinner) — clearing old data');
    emit(DashboardState(
      status: DashboardStatus.loading,
      fromDate: state.fromDate,
      toDate: state.toDate,
    ));
    await _fetch(emit);
  }

  Future<void> _onDateRangeChanged(
      DashboardDateRangeChanged event, Emitter<DashboardState> emit) async {
    AppLogger.info(
        _tag, 'date range changed → ${event.fromDate} .. ${event.toDate}');
    emit(DashboardState(
      status: DashboardStatus.loading,
      fromDate: event.fromDate,
      toDate: event.toDate,
    ));
    await _fetch(emit);
  }

  Future<void> _onRefresh(
      DashboardRefreshed event, Emitter<DashboardState> emit) async {
    AppLogger.info(_tag, 'silent refresh');
    await _fetch(emit, silent: true);
  }

  Future<void> _fetch(Emitter<DashboardState> emit,
      {bool silent = false}) async {
    final myId = ++_requestSeq;

    try {
      // Null unless the user picked a range — see fetchDashboard.
      final data = await _repository.fetchDashboard(
        fromDate: state.fromDate,
        toDate: state.toDate,
      );

      if (myId != _requestSeq) {
        AppLogger.info(
            _tag, 'stale response ignored (seq $myId vs $_requestSeq)');
        return;
      }

      // Poll returned exactly what's already on screen — nothing to update.
      if (state.status == DashboardStatus.success && data == state.data) {
        AppLogger.info(_tag, 'no change in data — skipping update');
        return;
      }

      // Diagnostic log: what came back? Useful for figuring out why
      // "No activity today" is showing when the server has data.
      AppLogger.info(
          _tag,
          'fetch success — '
          'tiles=${data.overview.sectionTiles.length}, '
          'daily=${data.overview.sectionsDaily.length}, '
          'totalRevenue=${data.overview.totalRevenue}');

      // Log each daily section's revenue so we can see what the server sent.
      for (final s in data.overview.sectionsDaily) {
        AppLogger.info(_tag, '  daily[${s.name}] = ${s.totalRevenue}');
      }
      for (final t in data.overview.sectionTiles) {
        AppLogger.info(
            _tag, '  tile[${t.name}] count=${t.count} revenue=${t.revenue}');
      }

      emit(state.copyWith(status: DashboardStatus.success, data: data));
    } catch (e, st) {
      if (myId != _requestSeq) {
        AppLogger.info(_tag, 'stale error ignored (seq $myId vs $_requestSeq)');
        return;
      }

      AppLogger.error(_tag, silent ? 'silent fetch failed' : 'fetch failed',
          error: e, stackTrace: st);
      if (silent && state.data != null) {
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
