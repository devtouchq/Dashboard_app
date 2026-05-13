import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/app_logger.dart';
import '../../../data/models/store_data.dart';
import '../../../data/repositories/store_repository.dart';

abstract class StoreEvent extends Equatable {
  const StoreEvent();
  @override
  List<Object?> get props => [];
}

class StoreLoadRequested extends StoreEvent {
  const StoreLoadRequested();
}

class StoreRefreshed extends StoreEvent {
  const StoreRefreshed();
}

enum StoreStatus { initial, loading, success, failure }

class StoreState extends Equatable {
  final StoreStatus status;
  final StoreData? data;
  final String? errorMessage;

  const StoreState({
    this.status = StoreStatus.initial,
    this.data,
    this.errorMessage,
  });

  StoreState copyWith({
    StoreStatus? status,
    StoreData? data,
    String? errorMessage,
  }) {
    return StoreState(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, data, errorMessage];
}

class StoreBloc extends Bloc<StoreEvent, StoreState> {
  static const _tag = 'StoreBloc';
  final StoreRepository _repository;

  StoreBloc(this._repository) : super(const StoreState()) {
    on<StoreLoadRequested>(_onLoad);
    on<StoreRefreshed>(_onRefresh);
  }

  Future<void> _onLoad(
      StoreLoadRequested event, Emitter<StoreState> emit) async {
    AppLogger.info(_tag, 'load requested');
    emit(state.copyWith(status: StoreStatus.loading));
    try {
      final data = await _repository.fetchDashboard();
      emit(state.copyWith(status: StoreStatus.success, data: data));
    } catch (e, st) {
      AppLogger.error(_tag, 'load failed', error: e, stackTrace: st);
      emit(state.copyWith(
        status: StoreStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRefresh(
      StoreRefreshed event, Emitter<StoreState> emit) async {
    AppLogger.info(_tag, 'refresh requested');
    try {
      final data = await _repository.fetchDashboard();
      emit(state.copyWith(status: StoreStatus.success, data: data));
    } catch (e, st) {
      AppLogger.error(_tag, 'refresh failed', error: e, stackTrace: st);
      emit(state.copyWith(
        status: StoreStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
