part of 'accounts_bloc.dart';

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
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, data, errorMessage];
}
