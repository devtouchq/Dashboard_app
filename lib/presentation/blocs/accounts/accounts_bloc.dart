import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/app_logger.dart';
import '../../../data/models/accounts_data.dart';
import '../../../data/repositories/accounts_repository.dart';

abstract class AccountsEvent extends Equatable {
  const AccountsEvent();
  @override
  List<Object?> get props => [];
}

class AccountsLoadRequested extends AccountsEvent {
  const AccountsLoadRequested();
}

class AccountsRefreshed extends AccountsEvent {
  const AccountsRefreshed();
}

enum AccountsStatus { initial, loading, success, failure }

class AccountsState extends Equatable {
  final AccountsStatus status;
  final AccountsData? data;
  final String? errorMessage;

  const AccountsState({
    this.status = AccountsStatus.initial,
    this.data,
    this.errorMessage,
  });

  AccountsState copyWith({
    AccountsStatus? status,
    AccountsData? data,
    String? errorMessage,
  }) {
    return AccountsState(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, data, errorMessage];
}

class AccountsBloc extends Bloc<AccountsEvent, AccountsState> {
  static const _tag = 'AccountsBloc';
  final AccountsRepository _repository;

  AccountsBloc(this._repository) : super(const AccountsState()) {
    on<AccountsLoadRequested>(_onLoad);
    on<AccountsRefreshed>(_onRefresh);
  }

  Future<void> _onLoad(
      AccountsLoadRequested event, Emitter<AccountsState> emit) async {
    AppLogger.info(_tag, 'load requested');
    emit(state.copyWith(status: AccountsStatus.loading));
    try {
      final data = await _repository.fetchDashboard();
      emit(state.copyWith(status: AccountsStatus.success, data: data));
    } catch (e, st) {
      AppLogger.error(_tag, 'load failed', error: e, stackTrace: st);
      emit(state.copyWith(
        status: AccountsStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRefresh(
      AccountsRefreshed event, Emitter<AccountsState> emit) async {
    AppLogger.info(_tag, 'refresh requested');
    try {
      final data = await _repository.fetchDashboard();
      emit(state.copyWith(status: AccountsStatus.success, data: data));
    } catch (e, st) {
      AppLogger.error(_tag, 'refresh failed', error: e, stackTrace: st);
      emit(state.copyWith(
        status: AccountsStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
