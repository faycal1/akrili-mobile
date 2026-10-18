import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../data/repositories/auth_repository.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  developer.log('Handling background message: ${message.messageId}', name: 'FCM');
}

class FcmService {
  static final FcmService instance = FcmService._internal();
  FcmService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  void Function(String type, String id)? onDeepLink;

  bool _initialized = false;

  Future<void> initialize({void Function(String type, String id)? onDeepLinkAction}) async {
    if (_initialized) return;
    onDeepLink = onDeepLinkAction;

    try {
      await Firebase.initializeApp();
    } catch (e) {
      developer.log('Firebase.initializeApp() skipped or not configured: $e', name: 'FCM');
      return;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request permissions
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    } catch (_) {}

    // Android Local Notification setup
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) {
          try {
            final data = jsonDecode(response.payload!) as Map<String, dynamic>;
            final type = data['type']?.toString();
            final id = data['id']?.toString();
            if (type != null && id != null) {
              onDeepLink?.call(type, id);
            }
          } catch (_) {}
        }
      },
    );

    // Create high importance notification channel
    const channel = AndroidNotificationChannel(
      'akrili_channel',
      'Akrili Notifications',
      description: 'Instant updates on bookings and messages',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Foreground listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      final data = message.data;

      if (notification != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title ?? 'Akrili',
          notification.body ?? '',
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
          payload: jsonEncode(data),
        );
      }
    });

    // App opened from background by notification tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessageTap(message);
    });

    // App opened from terminated state by notification tap
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTap(initialMessage);
    }

    _initialized = true;
  }

  void _handleMessageTap(RemoteMessage message) {
    final type = message.data['type']?.toString();
    final id = message.data['id']?.toString();
    if (type != null && id != null) {
      onDeepLink?.call(type, id);
    }
  }

  Future<void> registerDeviceToken(AuthRepository authRepo) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        final platform = Platform.isIOS ? 'ios' : 'android';
        await authRepo.registerDeviceToken(token: token, platform: platform);
        developer.log('Device token successfully registered with backend', name: 'FCM');
      }
    } catch (e) {
      developer.log('Could not register device token: $e', name: 'FCM');
    }
  }

  void listenToTokenRefresh(AuthRepository authRepo) {
    try {
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        if (newToken.isNotEmpty) {
          final platform = Platform.isIOS ? 'ios' : 'android';
          await authRepo.registerDeviceToken(token: newToken, platform: platform);
          developer.log('Refreshed token registered with backend', name: 'FCM');
        }
      });
    } catch (_) {}
  }
}
