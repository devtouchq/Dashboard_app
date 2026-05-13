import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/app_logger.dart';
import '../../../../data/models/dashboard_data.dart';
import '../../../../data/repositories/dashboard_repository.dart';

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

  DashboardBloc(this._repository) : super(const DashboardState()) {
    on<DashboardLoadRequested>(_onLoad);
    on<DashboardRefreshed>(_onRefresh);
  }

  Future<void> _onLoad(
      DashboardLoadRequested event, Emitter<DashboardState> emit) async {
    AppLogger.info(_tag, 'load requested');
    emit(state.copyWith(status: DashboardStatus.loading));
    try {
      final data = await _repository.fetchDashboard();
      emit(state.copyWith(status: DashboardStatus.success, data: data));
    } catch (e, st) {
      AppLogger.error(_tag, 'load failed', error: e, stackTrace: st);
      emit(state.copyWith(
        status: DashboardStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRefresh(
      DashboardRefreshed event, Emitter<DashboardState> emit) async {
    AppLogger.info(_tag, 'refresh requested');
    try {
      final data = await _repository.fetchDashboard();
      emit(state.copyWith(status: DashboardStatus.success, data: data));
    } catch (e, st) {
      AppLogger.error(_tag, 'refresh failed', error: e, stackTrace: st);
      emit(state.copyWith(
        status: DashboardStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
