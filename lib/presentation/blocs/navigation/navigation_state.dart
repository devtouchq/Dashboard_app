part of 'navigation_bloc.dart';

/// Three top-level tabs in the bottom nav.
/// All section screens (EMR/Accounts/Store/etc) are pushed routes,
/// not tabs.
enum AppTab { home, notifications, profile }

class NavigationState extends Equatable {
  final int currentIndex;

  const NavigationState({this.currentIndex = 0});

  AppTab get currentTab => AppTab.values[currentIndex];

  NavigationState copyWith({int? currentIndex}) {
    return NavigationState(currentIndex: currentIndex ?? this.currentIndex);
  }

  @override
  List<Object?> get props => [currentIndex];
}
