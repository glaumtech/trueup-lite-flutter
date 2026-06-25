import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'api_service.dart';
import 'auth_service.dart';
import 'notification_service.dart';

const String orderPollingTaskName = 'onlineOrderPolling';
const String knownPendingOrderRefsKey = 'known_pending_order_refs';

@pragma('vm:entry-point')
void orderPollingCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    await OrderPollingService.runBackgroundPoll();
    return true;
  });
}

class OrderPollingService {
  OrderPollingService({
    required ApiService api,
    NotificationService? notifications,
  })  : _api = api,
        _notifications = notifications ?? NotificationService.instance;

  final ApiService _api;
  final NotificationService _notifications;
  Timer? _foregroundTimer;

  static const Duration pollInterval = Duration(minutes: 30);

  Future<void> onStaffLogin() async {
    await _notifications.requestPermission();
    await registerBackgroundTask();
    await pollAndNotify();
    startForegroundPolling();
  }

  Future<void> onStaffLogout() async {
    stopForegroundPolling();
    await Workmanager().cancelByUniqueName(orderPollingTaskName);
  }

  void startForegroundPolling() {
    stopForegroundPolling();
    _foregroundTimer = Timer.periodic(pollInterval, (_) {
      pollAndNotify();
    });
  }

  void stopForegroundPolling() {
    _foregroundTimer?.cancel();
    _foregroundTimer = null;
  }

  Future<void> registerBackgroundTask() async {
    // Background polling reliability depends on Android battery optimization.
    await Workmanager().registerPeriodicTask(
      orderPollingTaskName,
      orderPollingTaskName,
      frequency: pollInterval,
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  /// Updates baseline from pending refs without showing notifications.
  Future<void> updateBaselineFromPending() async {
    try {
      final pending = await _api.getAdminPendingOrders();
      await _saveKnownRefs(pending.map((o) => o.id).toSet());
    } catch (_) {}
  }

  Future<void> pollAndNotify() async {
    try {
      final pending = await _api.getAdminPendingOrders();
      final currentRefs = pending.map((o) => o.id).toSet();
      final knownRefs = await _loadKnownRefs();

      if (knownRefs.isEmpty) {
        await _saveKnownRefs(currentRefs);
        return;
      }

      final newRefs = currentRefs.difference(knownRefs);
      if (newRefs.isNotEmpty) {
        await _notifications.showNewPendingOrders(newRefs.toList()..sort());
      }
      await _saveKnownRefs(currentRefs);
    } catch (_) {}
  }

  static Future<void> runBackgroundPoll() async {
    final session = await AuthService.loadSessionStatic();
    if (session == null) return;

    final api = ApiService()..authToken = session.token;
    try {
      final pending = await api.getAdminPendingOrders();
      final currentRefs = pending.map((o) => o.id).toSet();
      final knownRefs = await _loadKnownRefsStatic();

      if (knownRefs.isEmpty) {
        await _saveKnownRefsStatic(currentRefs);
        return;
      }

      final newRefs = currentRefs.difference(knownRefs);
      if (newRefs.isNotEmpty) {
        await NotificationService.instance.init();
        await NotificationService.instance
            .showNewPendingOrders(newRefs.toList()..sort());
      }
      await _saveKnownRefsStatic(currentRefs);
    } finally {
      api.dispose();
    }
  }

  Future<Set<String>> _loadKnownRefs() => _loadKnownRefsStatic();

  static Future<Set<String>> _loadKnownRefsStatic() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(knownPendingOrderRefsKey);
    if (raw == null || raw.isEmpty) return {};
    final list = json.decode(raw) as List<dynamic>;
    return list.map((e) => e.toString()).toSet();
  }

  Future<void> _saveKnownRefs(Set<String> refs) =>
      _saveKnownRefsStatic(refs);

  static Future<void> _saveKnownRefsStatic(Set<String> refs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      knownPendingOrderRefsKey,
      json.encode(refs.toList()..sort()),
    );
  }
}
