import 'dart:io';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:parent/modules/parent/controllers/navigation_controller.dart';
import 'package:parent/routes/app_routes.dart';
import 'package:parent/modules/parent/services/parent_auth_service.dart';
import 'package:parent/modules/parent/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Must initialize Firebase in background isolate.
  await Firebase.initializeApp();
}

class PushNotificationsService extends GetxService {
  /// يضبطه [ChatView]: عند `true` لا نُظهر إشعارًا محليًا أثناء وجود المستخدم في المحادثة.
  static bool suppressForegroundMessageNotifications = false;

  final SupabaseService _supabase = Get.find<SupabaseService>();
  final ParentAuthService _auth = Get.find<ParentAuthService>();

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  static const AndroidNotificationChannel _messagesChannel =
      AndroidNotificationChannel(
        'messages',
        'رسائل رُشد',
        description: 'إشعارات الرسائل والتنبيهات الفورية',
        importance: Importance.max,
      );

  Future<void> init() async {
    if (!(Platform.isAndroid || Platform.isIOS)) return;

    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _initLocalNotifications();
    await _requestPermissions();
    await registerCurrentDeviceToken();
    await _configureMessageOpenHandlers();

    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      await _upsertToken(token);
    });

    FirebaseMessaging.onMessage.listen((message) async {
      if (suppressForegroundMessageNotifications) {
        return;
      }
      final n = message.notification;
      final title = n?.title ?? 'إشعار جديد';
      final body = n?.body ?? '';
      await _local.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: body,
        payload: jsonEncode(message.data),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _messagesChannel.id,
            _messagesChannel.name,
            channelDescription: _messagesChannel.description,
            importance: Importance.max,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(body),
            playSound: true,
            enableVibration: true,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    });
  }

  Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _local.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        _openCommunicationScreen();
      },
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTap,
    );

    final androidPlugin = _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(_messagesChannel);
  }

  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTap(NotificationResponse response) {
    // App resume handling is covered by _configureMessageOpenHandlers().
  }

  Future<void> _requestPermissions() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _configureMessageOpenHandlers() async {
    FirebaseMessaging.onMessageOpenedApp.listen((_) {
      _openCommunicationScreen();
    });

    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      _openCommunicationScreen();
    }
  }

  void _openCommunicationScreen() {
    void switchTab() {
      if (Get.isRegistered<NavigationController>()) {
        Get.find<NavigationController>().switchTab(2);
      }
    }

    // Stacked /legacy route: replace with main shell so bottom nav is visible.
    final onMain = Get.currentRoute == AppRoutes.PARENT_MAIN_NAVIGATION;
    if (!onMain) {
      Get.offAllNamed(AppRoutes.PARENT_MAIN_NAVIGATION);
      // New [NavigationController] is created in [MainNavigationView] next frame.
      WidgetsBinding.instance.addPostFrameCallback((_) => switchTab());
      return;
    }

    switchTab();
  }

  Future<void> _registerToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) return;
    await _upsertToken(token);
  }

  /// Public entrypoint for manual token registration after auth sync/login.
  Future<void> registerCurrentDeviceToken() async {
    try {
      await _registerToken();
    } catch (e) {
      print('⚠️ registerCurrentDeviceToken failed: $e');
    }
  }

  Future<void> _upsertToken(String token) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    if (_auth.appEntityId.value == 0 || _auth.userType.value.isEmpty) return;

    final platform = Platform.isAndroid ? 'android' : 'ios';

    try {
      await _supabase.from('user_devices').upsert({
        'auth_user_id': user.id,
        'user_type': _auth.userType.value,
        'app_entity_id': _auth.appEntityId.value,
        'platform': platform,
        'fcm_token': token,
        'is_active': true,
        'last_seen_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'auth_user_id,platform');
      print('✅ FCM token upserted for user=${user.id}, platform=$platform');
    } catch (e) {
      // Do not crash app if token registration fails due to RLS/conflict.
      print('⚠️ Failed to upsert FCM token: $e');
    }
  }
}
