import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/app_logger.dart';
import '../../../data/models/emr_data.dart';
import '../../../data/repositories/emr_repository.dart';

// ─────────────────────────────────────────────────────────────
//  Events
// ─────────────────────────────────────────────────────────────
abstract class EmrEvent extends Equatable {
  const EmrEvent();
  @override
  List<Object?> get props => [];
}

class EmrLoadRequested extends EmrEvent {
  const EmrLoadRequested();
}

class EmrRefreshed extends EmrEvent {
  const EmrRefreshed();
}

// ─────────────────────────────────────────────────────────────
//  State
// ─────────────────────────────────────────────────────────────
enum EmrStatus { initial, loading, success, failure }

class EmrState extends Equatable {
  final EmrStatus status;
  final EmrData? data;
  final String? errorMessage;

  const EmrState({
    this.status = EmrStatus.initial,
    this.data,
    this.errorMessage,
  });

  EmrState copyWith({
    EmrStatus? status,
    EmrData? data,
    String? errorMessage,
  }) {
    return EmrState(
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
class EmrBloc extends Bloc<EmrEvent, EmrState> {
  static const _tag = 'EmrBloc';
  final EmrRepository _repository;

  EmrBloc(this._repository) : super(const EmrState()) {
    on<EmrLoadRequested>(_onLoad);
    on<EmrRefreshed>(_onRefresh);
  }

  Future<void> _onLoad(EmrLoadRequested event, Emitter<EmrState> emit) async {
    AppLogger.info(_tag, 'load requested');
    emit(state.copyWith(status: EmrStatus.loading));
    try {
      final data = await _repository.fetchDashboard();
      emit(state.copyWith(status: EmrStatus.success, data: data));
    } catch (e, st) {
      AppLogger.error(_tag, 'load failed', error: e, stackTrace: st);
      emit(state.copyWith(
        status: EmrStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRefresh(EmrRefreshed event, Emitter<EmrState> emit) async {
    AppLogger.info(_tag, 'refresh requested');
    try {
      final data = await _repository.fetchDashboard();
      emit(state.copyWith(status: EmrStatus.success, data: data));
    } catch (e, st) {
      AppLogger.error(_tag, 'refresh failed', error: e, stackTrace: st);
      emit(state.copyWith(
        status: EmrStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
