import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/store_data.dart';
import '../../../data/repositories/store_repository.dart';

part 'store_event.dart';
part 'store_state.dart';

class StoreBloc extends Bloc<StoreEvent, StoreState> {
  final StoreRepository _repository;

  StoreBloc(this._repository) : super(const StoreState()) {
    on<StoreLoadRequested>(_onLoad);
    on<StoreRefreshed>(_onRefresh);
  }

  Future<void> _onLoad(
    StoreLoadRequested event,
    Emitter<StoreState> emit,
  ) async {
    emit(state.copyWith(status: StoreStatus.loading));
    try {
      final data = await _repository.fetchStore();
      emit(state.copyWith(status: StoreStatus.success, data: data));
    } catch (e) {
      emit(
        state.copyWith(status: StoreStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onRefresh(
    StoreRefreshed event,
    Emitter<StoreState> emit,
  ) async {
    try {
      final data = await _repository.fetchStore();
      emit(state.copyWith(status: StoreStatus.success, data: data));
    } catch (e) {
      emit(
        state.copyWith(status: StoreStatus.failure, errorMessage: e.toString()),
      );
    }
  }
}
