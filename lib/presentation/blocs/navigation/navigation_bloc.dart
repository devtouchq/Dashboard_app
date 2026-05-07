import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/app_logger.dart';

part 'navigation_event.dart';
part 'navigation_state.dart';

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  static const _tag = 'NavigationBloc';

  NavigationBloc() : super(const NavigationState()) {
    on<NavigationTabChanged>((event, emit) {
      AppLogger.info(_tag, 'tab changed → index=${event.tabIndex}');
      emit(state.copyWith(currentIndex: event.tabIndex));
    });
  }
}
