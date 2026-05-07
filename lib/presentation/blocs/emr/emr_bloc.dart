import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/emr_data.dart';
import '../../../data/repositories/emr_repository.dart';

part 'emr_event.dart';
part 'emr_state.dart';

class EmrBloc extends Bloc<EmrEvent, EmrState> {
  final EmrRepository _repository;

  EmrBloc(this._repository) : super(const EmrState()) {
    on<EmrLoadRequested>(_onLoad);
    on<EmrRefreshed>(_onRefresh);
  }

  Future<void> _onLoad(EmrLoadRequested event, Emitter<EmrState> emit) async {
    emit(state.copyWith(status: EmrStatus.loading));
    try {
      final data = await _repository.fetchEmr();
      emit(state.copyWith(status: EmrStatus.success, data: data));
    } catch (e) {
      emit(
        state.copyWith(status: EmrStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onRefresh(EmrRefreshed event, Emitter<EmrState> emit) async {
    try {
      final data = await _repository.fetchEmr();
      emit(state.copyWith(status: EmrStatus.success, data: data));
    } catch (e) {
      emit(
        state.copyWith(status: EmrStatus.failure, errorMessage: e.toString()),
      );
    }
  }
}
