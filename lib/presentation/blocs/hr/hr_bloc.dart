import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/app_logger.dart';
import '../../../data/models/hr_data.dart';
import '../../../data/repositories/hr_repository.dart';

abstract class HrEvent extends Equatable {
  const HrEvent();
  @override
  List<Object?> get props => [];
}

class HrLoadRequested extends HrEvent {
  const HrLoadRequested();
}

class HrRefreshed extends HrEvent {
  const HrRefreshed();
}

enum HrStatus { initial, loading, success, failure }

class HrState extends Equatable {
  final HrStatus status;
  final HrData? data;
  final String? errorMessage;

  const HrState({
    this.status = HrStatus.initial,
    this.data,
    this.errorMessage,
  });

  HrState copyWith({
    HrStatus? status,
    HrData? data,
    String? errorMessage,
  }) {
    return HrState(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, data, errorMessage];
}

class HrBloc extends Bloc<HrEvent, HrState> {
  static const _tag = 'HrBloc';
  final HrRepository _repository;

  HrBloc(this._repository) : super(const HrState()) {
    on<HrLoadRequested>(_onLoad);
    on<HrRefreshed>(_onRefresh);
  }

  Future<void> _onLoad(HrLoadRequested event, Emitter<HrState> emit) async {
    AppLogger.info(_tag, 'load requested');
    emit(state.copyWith(status: HrStatus.loading));
    try {
      final data = await _repository.fetchDashboard();
      emit(state.copyWith(status: HrStatus.success, data: data));
    } catch (e, st) {
      AppLogger.error(_tag, 'load failed', error: e, stackTrace: st);
      emit(state.copyWith(
        status: HrStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRefresh(HrRefreshed event, Emitter<HrState> emit) async {
    AppLogger.info(_tag, 'refresh requested');
    try {
      final data = await _repository.fetchDashboard();
      emit(state.copyWith(status: HrStatus.success, data: data));
    } catch (e, st) {
      AppLogger.error(_tag, 'refresh failed', error: e, stackTrace: st);
      emit(state.copyWith(
        status: HrStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
