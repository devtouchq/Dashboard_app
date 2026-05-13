import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/app_logger.dart';
import '../../../data/models/frontoffice_data.dart';
import '../../../data/repositories/frontoffice_repository.dart';

abstract class FrontofficeEvent extends Equatable {
  const FrontofficeEvent();
  @override
  List<Object?> get props => [];
}

class FrontofficeLoadRequested extends FrontofficeEvent {
  const FrontofficeLoadRequested();
}

class FrontofficeRefreshed extends FrontofficeEvent {
  const FrontofficeRefreshed();
}

enum FrontofficeStatus { initial, loading, success, failure }

class FrontofficeState extends Equatable {
  final FrontofficeStatus status;
  final FrontofficeData? data;
  final String? errorMessage;

  const FrontofficeState({
    this.status = FrontofficeStatus.initial,
    this.data,
    this.errorMessage,
  });

  FrontofficeState copyWith({
    FrontofficeStatus? status,
    FrontofficeData? data,
    String? errorMessage,
  }) {
    return FrontofficeState(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, data, errorMessage];
}

class FrontofficeBloc extends Bloc<FrontofficeEvent, FrontofficeState> {
  static const _tag = 'FrontofficeBloc';
  final FrontofficeRepository _repository;

  FrontofficeBloc(this._repository) : super(const FrontofficeState()) {
    on<FrontofficeLoadRequested>(_onLoad);
    on<FrontofficeRefreshed>(_onRefresh);
  }

  Future<void> _onLoad(FrontofficeLoadRequested event,
      Emitter<FrontofficeState> emit) async {
    AppLogger.info(_tag, 'load requested');
    emit(state.copyWith(status: FrontofficeStatus.loading));
    try {
      final data = await _repository.fetchDashboard();
      emit(state.copyWith(status: FrontofficeStatus.success, data: data));
    } catch (e, st) {
      AppLogger.error(_tag, 'load failed', error: e, stackTrace: st);
      emit(state.copyWith(
        status: FrontofficeStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRefresh(
      FrontofficeRefreshed event, Emitter<FrontofficeState> emit) async {
    AppLogger.info(_tag, 'refresh requested');
    try {
      final data = await _repository.fetchDashboard();
      emit(state.copyWith(status: FrontofficeStatus.success, data: data));
    } catch (e, st) {
      AppLogger.error(_tag, 'refresh failed', error: e, stackTrace: st);
      emit(state.copyWith(
        status: FrontofficeStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
