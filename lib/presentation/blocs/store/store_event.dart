part of 'store_bloc.dart';

abstract class StoreEvent extends Equatable {
  const StoreEvent();

  @override
  List<Object?> get props => [];
}

class StoreLoadRequested extends StoreEvent {
  const StoreLoadRequested();
}

class StoreRefreshed extends StoreEvent {
  const StoreRefreshed();
}
