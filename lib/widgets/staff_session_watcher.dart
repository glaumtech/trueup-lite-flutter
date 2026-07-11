import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../services/fcm_service.dart';

class StaffSessionWatcher extends ConsumerStatefulWidget {
  final Widget child;

  const StaffSessionWatcher({super.key, required this.child});

  @override
  ConsumerState<StaffSessionWatcher> createState() =>
      _StaffSessionWatcherState();
}

class _StaffSessionWatcherState extends ConsumerState<StaffSessionWatcher> {
  bool _registeredFcmForSession = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureFcmRegistered());
  }

  void _ensureFcmRegistered() {
    final auth = ref.read(authProvider);
    if (auth.loading || !auth.isStaffLoggedIn || _registeredFcmForSession) {
      return;
    }
    _registeredFcmForSession = true;
    FcmService.instance.register(ref);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (prev?.loading == true && !next.loading && next.isStaffLoggedIn) {
        _registeredFcmForSession = true;
        FcmService.instance.register(ref);
      } else if (prev?.isStaffLoggedIn == true && !next.isStaffLoggedIn) {
        _registeredFcmForSession = false;
        FcmService.instance.unregister(ref);
      }
    });

    return widget.child;
  }
}
