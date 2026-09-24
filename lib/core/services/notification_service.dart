import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../utils/app_logger.dart';
import 'notification_center_service.dart';

/// Top-level handler required by firebase_messaging for background messages.
/// Must be a top-level or static function annotated with @pragma.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  AppLogger.info('NotificationBg', 'background message: ${message.messageId}');
  await NotificationCenterService().init();
  await NotificationCenterService().increment();
}

/// Wraps Firebase Cloud Messaging + local-notification display.
///
/// iOS notes:
///  - On iOS, FCM cannot issue a token until Apple's APNS gives the app
///    an APNS token first. APNS itself requires:
///      1. An APNs key uploaded to Firebase Console
///      2. Push Notifications capability enabled in Xcode
///      3. Running on a physical device (simulators never get APNS tokens)
///  - We defer getToken() until getAPNSToken() returns non-null (with a
///    short retry loop), and if APNS still fails we skip the FCM step
///    gracefully rather than crashing the app.
class NotificationService {
  static const _tag = 'NotificationService';
  static const _channelId = 'ayurliv_high_importance';

  /// Global navigator key so background/terminated pushes can route.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  /// Current FCM token — null until we successfully fetch one.
  static String? fcmToken;

  /// Emits every time the token changes (initial fetch + Firebase rotations).
  static final StreamController<String> _tokenController =
      StreamController<String>.broadcast();
  static Stream<String> get tokenStream => _tokenController.stream;

  static bool _initialized = false;
  static Future<void>? _initInFlight;

  /// Whether [init] has completed.
  static bool get isInitialized => _initialized;

  /// Runs [init] and the broadcast-topic subscription once. Safe to call
  /// from several places: later calls wait for, or reuse, the first.
  ///
  /// On a fresh install this is called after the first successful login,
  /// not at startup, so the only system prompt during setup and login is
  /// the one that matters for connectivity (iOS Local Network access).
  static Future<void> ensureInitialized() {
    if (_initialized) return Future.value();
    return _initInFlight ??= () async {
      try {
        await init();
        await subscribeToTopic('all-users');
      } catch (e, st) {
        AppLogger.error(_tag, 'ensureInitialized failed',
            error: e, stackTrace: st);
      } finally {
        _initInFlight = null;
      }
    }();
  }

  // ─────────────────────────────────────────────────────────────
  //  Init — AFTER Firebase.initializeApp(). Prefer ensureInitialized().
  // ─────────────────────────────────────────────────────────────
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    AppLogger.info(_tag, 'init');

    // 1. Request user permission (Android 13+ needs runtime, iOS always needs).
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    AppLogger.info(_tag, 'permission: ${settings.authorizationStatus}');

    // 2. Set up local notifications for foreground display.
    await _initLocalNotifications();

    // 3. On iOS, wait for APNS token before asking for FCM token.
    //    On Android, this is a no-op.
    if (Platform.isIOS) {
      final apnsReady = await _waitForApnsToken();
      if (!apnsReady) {
        AppLogger.info(
            _tag,
            'iOS APNS token unavailable — skipping FCM token fetch. '
            'Push will start working once APNS is configured (Apple Dev + '
            'APNs key + Xcode capabilities + physical device).');
        // Wire up listeners anyway — if APNS becomes available later
        // (rare, but possible), we'll pick up the token via onTokenRefresh.
        _wireTokenRefreshListener();
        _wireMessageListeners();
        return;
      }
    }

    // 4. Fetch the initial FCM token (safely).
    await _refreshToken();

    // 5. Listen for token rotations (Firebase may issue a new one).
    _wireTokenRefreshListener();

    // 6. Wire up incoming-message handlers.
    _wireMessageListeners();
  }

  /// Poll for the APNS token for up to ~10 seconds. Returns true if we
  /// got one, false if it never arrived. This handles the fact that
  /// APNS registration is asynchronous — the token might not be ready
  /// the instant `requestPermission` returns.
  static Future<bool> _waitForApnsToken() async {
    const attempts = 10;
    const delay = Duration(seconds: 1);

    for (var i = 0; i < attempts; i++) {
      try {
        final token = await _messaging.getAPNSToken();
        if (token != null && token.isNotEmpty) {
          AppLogger.info(_tag, 'APNS token ready after ${i + 1} attempt(s)');
          return true;
        }
      } catch (e) {
        AppLogger.info(_tag, 'getAPNSToken attempt ${i + 1} threw: $e');
      }
      await Future.delayed(delay);
    }
    AppLogger.info(
        _tag, 'APNS token never arrived after ${attempts}s. Common causes:');
    AppLogger.info(_tag, '  • Running in iOS Simulator (needs real device)');
    AppLogger.info(
        _tag, '  • Push Notifications capability not enabled in Xcode');
    AppLogger.info(_tag, '  • APNs key not uploaded to Firebase Console');
    AppLogger.info(_tag, '  • Bundle ID mismatch between Xcode and Firebase');
    return false;
  }

  /// Try to fetch the FCM token. Never throws — logs and moves on.
  static Future<void> _refreshToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        fcmToken = token;
        _tokenController.add(token);
        AppLogger.info(_tag, 'FCM token: ${token.substring(0, 20)}...');
      } else {
        AppLogger.info(_tag, 'FCM token was null');
      }
    } catch (e, st) {
      AppLogger.error(_tag, 'getToken failed', error: e, stackTrace: st);
      // Swallow — app must not crash if push registration fails.
    }
  }

  static void _wireTokenRefreshListener() {
    _messaging.onTokenRefresh.listen((newToken) {
      AppLogger.info(_tag, 'onTokenRefresh: ${newToken.substring(0, 20)}...');
      fcmToken = newToken;
      _tokenController.add(newToken);
    });
  }

  static void _wireMessageListeners() {
    // Foreground: show a local notification banner.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      AppLogger.info(_tag, 'onMessage: ${message.messageId}');
      NotificationCenterService().increment();
      _showLocalNotification(message);
    });

    // User tapped a notification while app was in background.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      AppLogger.info(_tag, 'onMessageOpenedApp: ${message.messageId}');
      _handleTap(message);
    });

    // App was cold-started by tapping a notification.
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        AppLogger.info(_tag, 'getInitialMessage: ${message.messageId}');
        _handleTap(message);
      }
    });
  }

  static Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _local.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        AppLogger.info(_tag, 'local notification tapped');
      },
    );

    // Create the high-importance Android channel.
    const channel = AndroidNotificationChannel(
      _channelId,
      'Ayurliv High Importance',
      description: 'Real-time updates from Ayurliv Dashboard',
      importance: Importance.high,
    );

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notif = message.notification;
    if (notif == null) return;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      'Ayurliv High Importance',
      channelDescription: 'Real-time updates from Ayurliv Dashboard',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      notif.title ?? 'Ayurliv',
      notif.body ?? '',
      details,
    );
  }

  static void _handleTap(RemoteMessage message) {
    // TODO: route to specific screen based on message.data
    // For now, just bring the app to the foreground (default behavior).
    AppLogger.info(_tag, 'tap data: ${message.data}');
  }

  // ─────────────────────────────────────────────────────────────
  //  Topic subscription — safe against APNS-not-ready
  // ─────────────────────────────────────────────────────────────
  static Future<void> subscribeToTopic(String topic) async {
    // On iOS, subscribeToTopic also requires APNS. Skip if not ready.
    if (Platform.isIOS) {
      try {
        final apns = await _messaging.getAPNSToken();
        if (apns == null || apns.isEmpty) {
          AppLogger.info(_tag,
              'skipping subscribeToTopic("$topic") — APNS not ready on iOS');
          return;
        }
      } catch (e) {
        AppLogger.info(_tag, 'APNS check before topic subscribe failed: $e');
        return;
      }
    }

    try {
      await _messaging.subscribeToTopic(topic);
      AppLogger.info(_tag, 'subscribed to topic: $topic');
    } catch (e, st) {
      AppLogger.error(_tag, 'subscribeToTopic("$topic") failed',
          error: e, stackTrace: st);
      // Don't rethrow — a failed topic subscription is not fatal.
    }
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    if (Platform.isIOS) {
      final apns = await _messaging.getAPNSToken();
      if (apns == null) return;
    }
    try {
      await _messaging.unsubscribeFromTopic(topic);
      AppLogger.info(_tag, 'unsubscribed from topic: $topic');
    } catch (e) {
      AppLogger.info(_tag, 'unsubscribeFromTopic failed: $e');
    }
  }

  /// Called by AuthBloc on logout so the next login gets a fresh token.
  static Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      fcmToken = null;
      AppLogger.info(_tag, 'FCM token deleted');
    } catch (e) {
      AppLogger.info(_tag, 'deleteToken failed (ignored): $e');
    }
  }
}
