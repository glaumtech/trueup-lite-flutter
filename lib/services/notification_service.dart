import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'online_orders_alerts';
  static const String channelName = 'Online Orders';
  static const int newOrderNotificationId = 9001;

  bool _initialized = false;

  void Function(String? payload)? _navigationHandler;

  void setNavigationHandler(void Function(String? payload) handler) {
    _navigationHandler = handler;
  }

  Future<void> handleLaunchNotification() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      _navigationHandler?.call(details?.notificationResponse?.payload);
    }
  }

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    const channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: 'Alerts for new pending online orders',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(channel);

    _initialized = true;
  }

  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    final granted = await android.requestNotificationsPermission();
    return granted ?? false;
  }

  Future<void> showOrderAlert({
    required String title,
    required String body,
    String orderRef = '',
  }) async {
    await init();

    final payload = orderRef.isNotEmpty
        ? '/online-orders/$orderRef'
        : '/online-orders';

    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Alerts for new pending online orders',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.message,
    );

    await _plugin.show(
      newOrderNotificationId,
      title,
      body,
      const NotificationDetails(android: androidDetails),
      payload: payload,
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    _navigationHandler?.call(response.payload);
  }
}
