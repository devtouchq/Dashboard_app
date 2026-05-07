part of 'emr_bloc.dart';

enum EmrStatus { initial, loading, success, failure }

class EmrState extends Equatable {
  final EmrStatus status;
  final EmrData? data;
  final String? errorMessage;

  const EmrState({
    this.status = EmrStatus.initial,
    this.data,
    this.errorMessage,
  });

  EmrState copyWith({
    EmrStatus? status,
    EmrData? data,
    String? errorMessage,
  }) {
    return EmrState(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, data, errorMessage];
}
