part of 'store_bloc.dart';

enum StoreStatus { initial, loading, success, failure }

class StoreState extends Equatable {
  final StoreStatus status;
  final StoreData? data;
  final String? errorMessage;

  const StoreState({
    this.status = StoreStatus.initial,
    this.data,
    this.errorMessage,
  });

  StoreState copyWith({
    StoreStatus? status,
    StoreData? data,
    String? errorMessage,
  }) {
    return StoreState(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, data, errorMessage];
}
