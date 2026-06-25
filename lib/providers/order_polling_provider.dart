import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/order_polling_service.dart';
import 'auth_provider.dart';

final orderPollingProvider = Provider<OrderPollingService>((ref) {
  final api = ref.watch(authenticatedApiProvider);
  final service = OrderPollingService(api: api);
  ref.onDispose(service.stopForegroundPolling);
  return service;
});
