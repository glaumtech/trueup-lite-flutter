import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'online_orders';
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
      importance: Importance.high,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    final granted = await android.requestNotificationsPermission();
    return granted ?? false;
  }

  Future<void> showNewPendingOrders(List<String> orderRefs) async {
    if (!_initialized || orderRefs.isEmpty) return;

    final title = orderRefs.length == 1
        ? 'New online order'
        : '${orderRefs.length} new online orders';
    final body = orderRefs.length == 1
        ? orderRefs.first
        : orderRefs.take(3).join(', ') +
            (orderRefs.length > 3 ? '…' : '');

    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Alerts for new pending online orders',
      importance: Importance.high,
      priority: Priority.high,
    );

    await _plugin.show(
      newOrderNotificationId,
      title,
      body,
      const NotificationDetails(android: androidDetails),
      payload: '/online-orders',
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    _navigationHandler?.call(response.payload);
  }
}
