import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/app_logger.dart';
import '../../../data/models/banquet_data.dart';
import '../../../data/repositories/banquet_repository.dart';

abstract class BanquetEvent extends Equatable {
  const BanquetEvent();
  @override
  List<Object?> get props => [];
}

class BanquetLoadRequested extends BanquetEvent {
  const BanquetLoadRequested();
}

class BanquetRefreshed extends BanquetEvent {
  const BanquetRefreshed();
}

enum BanquetStatus { initial, loading, success, failure }

class BanquetState extends Equatable {
  final BanquetStatus status;
  final BanquetData? data;
  final String? errorMessage;

  const BanquetState({
    this.status = BanquetStatus.initial,
    this.data,
    this.errorMessage,
  });

  BanquetState copyWith({
    BanquetStatus? status,
    BanquetData? data,
    String? errorMessage,
  }) {
    return BanquetState(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, data, errorMessage];
}

class BanquetBloc extends Bloc<BanquetEvent, BanquetState> {
  static const _tag = 'BanquetBloc';
  final BanquetRepository _repository;

  BanquetBloc(this._repository) : super(const BanquetState()) {
    on<BanquetLoadRequested>(_onLoad);
    on<BanquetRefreshed>(_onRefresh);
  }

  Future<void> _onLoad(
      BanquetLoadRequested event, Emitter<BanquetState> emit) async {
    AppLogger.info(_tag, 'load requested');
    emit(state.copyWith(status: BanquetStatus.loading));
    try {
      final data = await _repository.fetchDashboard();
      emit(state.copyWith(status: BanquetStatus.success, data: data));
    } catch (e, st) {
      AppLogger.error(_tag, 'load failed', error: e, stackTrace: st);
      emit(state.copyWith(
        status: BanquetStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRefresh(
      BanquetRefreshed event, Emitter<BanquetState> emit) async {
    AppLogger.info(_tag, 'refresh requested');
    try {
      final data = await _repository.fetchDashboard();
      emit(state.copyWith(status: BanquetStatus.success, data: data));
    } catch (e, st) {
      AppLogger.error(_tag, 'refresh failed', error: e, stackTrace: st);
      emit(state.copyWith(
        status: BanquetStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
