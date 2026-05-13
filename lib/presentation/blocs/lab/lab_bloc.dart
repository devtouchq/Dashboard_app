import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/app_logger.dart';
import '../../../data/models/lab_data.dart';
import '../../../data/repositories/lab_repository.dart';

abstract class LabEvent extends Equatable {
  const LabEvent();
  @override
  List<Object?> get props => [];
}

class LabLoadRequested extends LabEvent {
  const LabLoadRequested();
}

class LabRefreshed extends LabEvent {
  const LabRefreshed();
}

enum LabStatus { initial, loading, success, failure }

class LabState extends Equatable {
  final LabStatus status;
  final LabData? data;
  final String? errorMessage;

  const LabState({
    this.status = LabStatus.initial,
    this.data,
    this.errorMessage,
  });

  LabState copyWith({
    LabStatus? status,
    LabData? data,
    String? errorMessage,
  }) {
    return LabState(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, data, errorMessage];
}

class LabBloc extends Bloc<LabEvent, LabState> {
  static const _tag = 'LabBloc';
  final LabRepository _repository;

  LabBloc(this._repository) : super(const LabState()) {
    on<LabLoadRequested>(_onLoad);
    on<LabRefreshed>(_onRefresh);
  }

  Future<void> _onLoad(LabLoadRequested event, Emitter<LabState> emit) async {
    AppLogger.info(_tag, 'load requested');
    emit(state.copyWith(status: LabStatus.loading));
    try {
      final data = await _repository.fetchDashboard();
      emit(state.copyWith(status: LabStatus.success, data: data));
    } catch (e, st) {
      AppLogger.error(_tag, 'load failed', error: e, stackTrace: st);
      emit(state.copyWith(
        status: LabStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRefresh(LabRefreshed event, Emitter<LabState> emit) async {
    AppLogger.info(_tag, 'refresh requested');
    try {
      final data = await _repository.fetchDashboard();
      emit(state.copyWith(status: LabStatus.success, data: data));
    } catch (e, st) {
      AppLogger.error(_tag, 'refresh failed', error: e, stackTrace: st);
      emit(state.copyWith(
        status: LabStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
