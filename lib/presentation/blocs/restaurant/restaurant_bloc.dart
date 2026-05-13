import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/app_logger.dart';
import '../../../data/models/restaurant_data.dart';
import '../../../data/repositories/restaurant_repository.dart';

abstract class RestaurantEvent extends Equatable {
  const RestaurantEvent();
  @override
  List<Object?> get props => [];
}

class RestaurantLoadRequested extends RestaurantEvent {
  const RestaurantLoadRequested();
}

class RestaurantRefreshed extends RestaurantEvent {
  const RestaurantRefreshed();
}

enum RestaurantStatus { initial, loading, success, failure }

class RestaurantState extends Equatable {
  final RestaurantStatus status;
  final RestaurantData? data;
  final String? errorMessage;

  const RestaurantState({
    this.status = RestaurantStatus.initial,
    this.data,
    this.errorMessage,
  });

  RestaurantState copyWith({
    RestaurantStatus? status,
    RestaurantData? data,
    String? errorMessage,
  }) {
    return RestaurantState(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, data, errorMessage];
}

class RestaurantBloc extends Bloc<RestaurantEvent, RestaurantState> {
  static const _tag = 'RestaurantBloc';
  final RestaurantRepository _repository;

  RestaurantBloc(this._repository) : super(const RestaurantState()) {
    on<RestaurantLoadRequested>(_onLoad);
    on<RestaurantRefreshed>(_onRefresh);
  }

  Future<void> _onLoad(
      RestaurantLoadRequested event, Emitter<RestaurantState> emit) async {
    AppLogger.info(_tag, 'load requested');
    emit(state.copyWith(status: RestaurantStatus.loading));
    try {
      final data = await _repository.fetchDashboard();
      emit(state.copyWith(status: RestaurantStatus.success, data: data));
    } catch (e, st) {
      AppLogger.error(_tag, 'load failed', error: e, stackTrace: st);
      emit(state.copyWith(
        status: RestaurantStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRefresh(
      RestaurantRefreshed event, Emitter<RestaurantState> emit) async {
    AppLogger.info(_tag, 'refresh requested');
    try {
      final data = await _repository.fetchDashboard();
      emit(state.copyWith(status: RestaurantStatus.success, data: data));
    } catch (e, st) {
      AppLogger.error(_tag, 'refresh failed', error: e, stackTrace: st);
      emit(state.copyWith(
        status: RestaurantStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
