import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/app_logger.dart';
import '../../../data/models/bar_data.dart';
import '../../../data/repositories/bar_repository.dart';

abstract class BarEvent extends Equatable {
  const BarEvent();
  @override
  List<Object?> get props => [];
}

class BarLoadRequested extends BarEvent {
  const BarLoadRequested();
}

class BarRefreshed extends BarEvent {
  const BarRefreshed();
}

enum BarStatus { initial, loading, success, failure }

class BarState extends Equatable {
  final BarStatus status;
  final BarData? data;
  final String? errorMessage;

  const BarState({
    this.status = BarStatus.initial,
    this.data,
    this.errorMessage,
  });

  BarState copyWith({
    BarStatus? status,
    BarData? data,
    String? errorMessage,
  }) {
    return BarState(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, data, errorMessage];
}

class BarBloc extends Bloc<BarEvent, BarState> {
  static const _tag = 'BarBloc';
  final BarRepository _repository;

  BarBloc(this._repository) : super(const BarState()) {
    on<BarLoadRequested>(_onLoad);
    on<BarRefreshed>(_onRefresh);
  }

  Future<void> _onLoad(BarLoadRequested event, Emitter<BarState> emit) async {
    AppLogger.info(_tag, 'load requested');
    emit(state.copyWith(status: BarStatus.loading));
    try {
      final data = await _repository.fetchDashboard();
      emit(state.copyWith(status: BarStatus.success, data: data));
    } catch (e, st) {
      AppLogger.error(_tag, 'load failed', error: e, stackTrace: st);
      emit(state.copyWith(
        status: BarStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRefresh(BarRefreshed event, Emitter<BarState> emit) async {
    AppLogger.info(_tag, 'refresh requested');
    try {
      final data = await _repository.fetchDashboard();
      emit(state.copyWith(status: BarStatus.success, data: data));
    } catch (e, st) {
      AppLogger.error(_tag, 'refresh failed', error: e, stackTrace: st);
      emit(state.copyWith(
        status: BarStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
