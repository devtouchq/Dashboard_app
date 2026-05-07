part of 'emr_bloc.dart';

abstract class EmrEvent extends Equatable {
  const EmrEvent();

  @override
  List<Object?> get props => [];
}

class EmrLoadRequested extends EmrEvent {
  const EmrLoadRequested();
}

class EmrRefreshed extends EmrEvent {
  const EmrRefreshed();
}
