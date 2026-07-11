import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase_options.dart';
import '../providers/auth_provider.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('FCM background message: ${message.messageId}');
}

class FcmService {
  FcmService._();

  static final FcmService instance = FcmService._();

  bool _initialized = false;
  String? _currentToken;
  void Function(String route)? _navigationHandler;

  void setNavigationHandler(void Function(String route) handler) {
    _navigationHandler = handler;
  }

  Future<void> init() async {
    if (_initialized) return;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await NotificationService.instance.requestPermission();

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpened);
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      _currentToken = token;
      debugPrint('FCM token refreshed');
    });

    _initialized = true;
  }

  Future<void> handleInitialMessage() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message != null) {
      _navigateFromMessage(message);
    }
  }

  Future<void> register(WidgetRef ref) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('FcmService: no FCM token available');
        return;
      }
      _currentToken = token;
      final api = ref.read(authenticatedApiProvider);
      await api.registerFcmToken(token);
      debugPrint('FcmService: token registered with backend');
    } catch (error, stack) {
      debugPrint('FcmService.register failed: $error\n$stack');
    }
  }

  Future<void> unregister(WidgetRef ref) async {
    final token = _currentToken;
    if (token == null || token.isEmpty) {
      return;
    }
    try {
      final api = ref.read(authenticatedApiProvider);
      await api.unregisterFcmToken(token);
      debugPrint('FcmService: token unregistered from backend');
    } catch (error, stack) {
      debugPrint('FcmService.unregister failed: $error\n$stack');
    } finally {
      _currentToken = null;
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    final orderRef = message.data['orderRef'] ?? '';
    final title = message.notification?.title ?? 'New online order';
    final body = message.notification?.body ??
        (orderRef.isNotEmpty ? orderRef : 'Tap to view orders');
    NotificationService.instance.showOrderAlert(
      title: title,
      body: body,
      orderRef: orderRef,
    );
  }

  void _onMessageOpened(RemoteMessage message) {
    _navigateFromMessage(message);
  }

  void _navigateFromMessage(RemoteMessage message) {
    final route = _routeFromMessage(message);
    if (route != null) {
      _navigationHandler?.call(route);
    }
  }

  String? _routeFromMessage(RemoteMessage message) {
    final orderRef = message.data['orderRef'];
    if (orderRef != null && orderRef.isNotEmpty) {
      return '/online-orders/$orderRef';
    }
    final route = message.data['route'];
    if (route != null && route.isNotEmpty) {
      return route;
    }
    return '/online-orders';
  }
}
