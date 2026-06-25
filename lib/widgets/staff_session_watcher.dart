import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/order_polling_provider.dart';

class StaffSessionWatcher extends ConsumerStatefulWidget {
  final Widget child;

  const StaffSessionWatcher({super.key, required this.child});

  @override
  ConsumerState<StaffSessionWatcher> createState() =>
      _StaffSessionWatcherState();
}

class _StaffSessionWatcherState extends ConsumerState<StaffSessionWatcher>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final auth = ref.read(authProvider);
      if (auth.isStaffLoggedIn) {
        ref.read(orderPollingProvider).pollAndNotify();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (prev?.loading == true && !next.loading && next.isStaffLoggedIn) {
        ref.read(orderPollingProvider).onStaffLogin();
      } else if (prev?.isStaffLoggedIn == true && !next.isStaffLoggedIn) {
        ref.read(orderPollingProvider).onStaffLogout();
      }
    });

    return widget.child;
  }
}
