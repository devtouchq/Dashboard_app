import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/accounts_data.dart';
import '../../../data/repositories/accounts_repository.dart';

part 'accounts_event.dart';
part 'accounts_state.dart';

class AccountsBloc extends Bloc<AccountsEvent, AccountsState> {
  final AccountsRepository _repository;

  AccountsBloc(this._repository) : super(const AccountsState()) {
    on<AccountsLoadRequested>(_onLoad);
    on<AccountsRefreshed>(_onRefresh);
  }

  Future<void> _onLoad(
    AccountsLoadRequested event,
    Emitter<AccountsState> emit,
  ) async {
    emit(state.copyWith(status: AccountsStatus.loading));
    try {
      final data = await _repository.fetchAccounts();
      emit(state.copyWith(status: AccountsStatus.success, data: data));
    } catch (e) {
      emit(
        state.copyWith(
          status: AccountsStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onRefresh(
    AccountsRefreshed event,
    Emitter<AccountsState> emit,
  ) async {
    try {
      final data = await _repository.fetchAccounts();
      emit(state.copyWith(status: AccountsStatus.success, data: data));
    } catch (e) {
      emit(
        state.copyWith(
          status: AccountsStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
