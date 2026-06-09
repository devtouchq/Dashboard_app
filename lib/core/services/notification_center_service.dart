import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_logger.dart';

/// Tracks unread notification count app-wide.
/// Singleton, lazily initialized. Persists across app restarts so a
/// notification that arrived while the app was closed still shows a
/// badge when the user opens the app.
class NotificationCenterService {
  static const _tag = 'NotificationCenterService';
  static const _kUnreadKey = 'notif_unread_count';

  static final NotificationCenterService _instance =
      NotificationCenterService._();
  factory NotificationCenterService() => _instance;
  NotificationCenterService._();

  SharedPreferences? _prefs;
  int _unreadCount = 0;

  final _controller = StreamController<int>.broadcast();

  /// Latest unread count.
  int get unreadCount => _unreadCount;

  /// Listen for changes (e.g. in the bell icon widget).
  Stream<int> get stream => _controller.stream;

  /// Call once at app startup, after Firebase init.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _unreadCount = _prefs?.getInt(_kUnreadKey) ?? 0;
    AppLogger.info(_tag, 'init — unread=$_unreadCount');
    _controller.add(_unreadCount);
  }

  /// Increment the badge by 1. Call this when a notification arrives
  /// (foreground OR background — background needs special handling).
  Future<void> increment() async {
    _unreadCount += 1;
    await _prefs?.setInt(_kUnreadKey, _unreadCount);
    _controller.add(_unreadCount);
    AppLogger.info(_tag, 'increment → $_unreadCount');
  }

  /// Reset to 0. Call when the user opens the notification list
  /// (or taps the bell, depending on your UX).
  Future<void> markAllRead() async {
    _unreadCount = 0;
    await _prefs?.setInt(_kUnreadKey, 0);
    _controller.add(0);
    AppLogger.info(_tag, 'marked all read');
  }

  /// Set to a specific value (e.g. when syncing with backend).
  Future<void> setCount(int count) async {
    _unreadCount = count < 0 ? 0 : count;
    await _prefs?.setInt(_kUnreadKey, _unreadCount);
    _controller.add(_unreadCount);
  }
}
