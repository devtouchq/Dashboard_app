import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../utils/app_logger.dart';
import 'notification_center_service.dart';

/// Background message handler. MUST be a top-level function (not a method)
/// because the OS spawns a fresh isolate to execute it when the app is
/// terminated. Add this annotation to keep the tree-shaker happy.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  AppLogger.info('FCM', 'background message: ${message.messageId}');
  AppLogger.info('FCM', 'data: ${message.data}');
// Bump the badge from the background isolate too. This works because
// SharedPreferences is process-safe — the value persists and the main
// isolate picks it up via the stream the next time it reads.
  try {
    await NotificationCenterService().init();
    await NotificationCenterService().increment();
  } catch (e) {
    AppLogger.error('FCM', 'badge bump failed: $e');
  }
}

/// Central notification handler. Call `init()` once after Firebase.initializeApp().
class NotificationService {
  static const _tag = 'NotificationService';

  // GlobalKey<NavigatorState> from main.dart so we can navigate
  // from anywhere (including notification taps) without context.
  static final navigatorKey = GlobalKey<NavigatorState>();

  static final _local = FlutterLocalNotificationsPlugin();
  static final _messaging = FirebaseMessaging.instance;

  // Android notification channel — required on Android 8+.
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'ayurliv_high_importance',
    'Ayurliv Notifications',
    description: 'Updates and alerts from Ayurliv Dashboard.',
    importance: Importance.high,
    playSound: true,
  );

  /// Cached FCM token so callers can register it with the backend.
  static String? _fcmToken;
  static String? get fcmToken => _fcmToken;

  /// Stream that fires whenever the FCM token rotates. Use this in your
  /// AuthBloc to re-register the token with your backend.
  static final StreamController<String> _tokenController =
      StreamController<String>.broadcast();
  static Stream<String> get tokenStream => _tokenController.stream;

  /// Initialize. Call once from main() after Firebase.initializeApp().
  static Future<void> init() async {
    print('═══ NotificationService.init() ENTERED');
    AppLogger.info(_tag, 'init');

    // 1. Set up local notifications (used to show foreground banners
    //    on Android — iOS shows them natively when configured below).
    await _setupLocalNotifications();

    // 2. Register the Android channel (no-op on iOS).
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 3. iOS-specific: tell FCM to show heads-up alerts when foreground.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 4. Request permission. On Android 13+ this triggers the runtime
    //    POST_NOTIFICATIONS permission. On iOS this triggers the popup.
    await requestPermission();

    // 5. Get the FCM token.
    await _refreshToken();

    // 6. Listen for token rotations (happens occasionally).
    _messaging.onTokenRefresh.listen((token) {
      AppLogger.info(_tag, 'token refreshed');
      _fcmToken = token;
      _tokenController.add(token);
    });

    // 7. Foreground messages — show a local banner manually.
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // 8. App opened from a notification (was in background).
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    // 9. App launched cold from a notification (was terminated).
    final initialMsg = await _messaging.getInitialMessage();
    if (initialMsg != null) {
      // Delay so the navigator is ready.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onMessageOpenedApp(initialMsg);
      });
    }
  }

  static Future<void> _setupLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false, // handled by FCM permission flow
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _local.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        // User tapped a foreground banner — payload is the JSON-encoded data map.
        if (response.payload != null && response.payload!.isNotEmpty) {
          try {
            final data = json.decode(response.payload!) as Map<String, dynamic>;
            _handleTap(data);
          } catch (e) {
            AppLogger.error(_tag, 'bad payload: $e');
          }
        }
      },
    );
  }

  /// Ask the user for notification permission.
  /// Returns true if granted.
  static Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;
    AppLogger.info(_tag, 'permission: ${settings.authorizationStatus}');
    return granted;
  }

  static Future<void> _refreshToken() async {
    print('═══ _refreshToken() ENTERED');
    try {
      final token = await _messaging.getToken();
      print('═══ getToken returned: $token');
      AppLogger.info(_tag, 'FCM token: $token');
      _fcmToken = token;
      if (token != null) _tokenController.add(token);
    } catch (e, st) {
      AppLogger.error(_tag, 'getToken failed', error: e, stackTrace: st);
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  Foreground handling
  // ─────────────────────────────────────────────────────────────
  static Future<void> _onForegroundMessage(RemoteMessage message) async {
    AppLogger.info(_tag,
        'foreground message: ${message.notification?.title} / data=${message.data}');

    // FCM doesn't show banners automatically when app is in foreground.
    // We render one ourselves via flutter_local_notifications.
    final notif = message.notification;
    if (notif != null) {
      await _local.show(
        notif.hashCode,
        notif.title,
        notif.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: json.encode(message.data),
      );
    }
    // NEW: bump the unread badge whenever a foreground notification arrives.
    await NotificationCenterService().increment();
  }
  //TODO: consider debouncing if you expect a flood of foreground notifications
// ─── (OPTIONAL) — sync badge when app comes back to foreground ─────
// When the user reopens the app after a background push, the main
// isolate's in-memory count may be stale (the background isolate wrote
// to SharedPreferences but our stream didn't fire). Re-read at init.
//
// Already handled by NotificationCenterService.init() being called once
// in main.dart. If you want to refresh whenever the app resumes from
// background, add this to your HomeScreen's didChangeAppLifecycleState:
//
//   if (state == AppLifecycleState.resumed) {
//     // Re-read in case a background notification arrived while we slept.
//     await NotificationCenterService().init();
//   }

  // ─────────────────────────────────────────────────────────────
  //  Tap handling — user opens a notification.
  //  Background notifications: route key in `message.data['screen']`.
  // ─────────────────────────────────────────────────────────────
  static void _onMessageOpenedApp(RemoteMessage message) {
    AppLogger.info(_tag, 'message opened app: ${message.data}');
    _handleTap(message.data);
  }

  static void _handleTap(Map<String, dynamic> data) {
    final screen = data['screen']?.toString();
    if (screen == null || screen.isEmpty) return;

    AppLogger.info(_tag, 'navigating to: $screen');

    // Use the global navigator key so this works without a BuildContext.
    final nav = navigatorKey.currentState;
    if (nav == null) {
      AppLogger.error(_tag, 'navigator not ready');
      return;
    }

    // Map of `screen` → route name. Adjust route names to match your
    // MaterialApp.routes (or use direct Navigator.push with widgets).
    switch (screen) {
      case 'home':
        nav.pushNamedAndRemoveUntil('/home', (r) => false);
        break;
      case 'emr':
        nav.pushNamed('/emr');
        break;
      case 'accounts':
        nav.pushNamed('/accounts');
        break;
      case 'store':
        nav.pushNamed('/store');
        break;
      case 'bar':
        nav.pushNamed('/bar');
        break;
      case 'lab':
        nav.pushNamed('/lab');
        break;
      case 'restaurant':
        nav.pushNamed('/restaurant');
        break;
      case 'hr':
        nav.pushNamed('/hr');
        break;
      case 'banquet':
        nav.pushNamed('/banquet');
        break;
      case 'frontoffice':
        nav.pushNamed('/frontoffice');
        break;
      default:
        AppLogger.info(_tag, 'unknown screen: $screen');
    }
  }

  /// Subscribe this device to a topic (used for broadcast pushes).
  /// e.g. subscribeToTopic('all-users') — anyone subscribed gets pushes
  /// the backend sends to that topic.
  static Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    AppLogger.info(_tag, 'subscribed: $topic');
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    AppLogger.info(_tag, 'unsubscribed: $topic');
  }

  /// Force-delete the current FCM token. Useful on logout — the backend
  /// won't be able to push to a device that has logged out.
  static Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      _fcmToken = null;
      AppLogger.info(_tag, 'token deleted');
    } catch (e) {
      AppLogger.error(_tag, 'deleteToken failed: $e');
    }
  }
}

// ════════════════════════════════════════════════════════════════════
//  TROUBLESHOOTING
// ════════════════════════════════════════════════════════════════════
//
// 1. "FCM token is null" on Android
//    → Real device required. Emulators without Google Play Services
//      won't return a token.
//    → Make sure google-services.json is in android/app/.
//
// 2. "No notification shown" on iOS
//    → Must use a real iPhone. Simulator doesn't deliver push.
//    → APNs key must be uploaded to Firebase (Stage 1.4).
//    → Push capability must be enabled in Xcode (Stage 2.5).
//    → Bundle ID must match between Xcode and Firebase.
//
// 3. "Notification arrives but tap doesn't navigate"
//    → MaterialApp must use navigatorKey: NotificationService.navigatorKey.
//    → Backend must send `data: { "screen": "emr" }` in the FCM payload.
//
// 4. "Background notification doesn't show banner on Android"
//    → Backend MUST send a `notification` field (title + body) for the
//      OS to render the banner. Data-only pushes won't show a tray entry.
//
// 5. "Foreground banner not shown on iOS"
//    → Verify setForegroundNotificationPresentationOptions was called
//      in init() (it is — but check init() runs before notifications arrive).
//
// ════════════════════════════════════════════════════════════════════
