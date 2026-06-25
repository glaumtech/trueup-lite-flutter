import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';
import '../services/api_service.dart';

class AuthState {
  final AuthSession? session;
  final bool loading;

  const AuthState({this.session, this.loading = false});

  bool get isStaffLoggedIn => session != null && session!.billingKioskUser;
}

class AuthNotifier extends Notifier<AuthState> {
  late final AuthService _authService;

  @override
  AuthState build() {
    _authService = AuthService();
    _restoreSession();
    return const AuthState(loading: true);
  }

  Future<void> _restoreSession() async {
    final session = await _authService.loadSession();
    state = AuthState(session: session, loading: false);
  }

  Future<void> login(String username, String password) async {
    state = AuthState(session: state.session, loading: true);
    try {
      final session = await _authService.login(username, password);
      state = AuthState(session: session, loading: false);
    } catch (e) {
      state = AuthState(session: null, loading: false);
      rethrow;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState(session: null, loading: false);
  }

  String? get token => state.session?.token;
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

final authenticatedApiProvider = Provider<ApiService>((ref) {
  final api = ApiService();
  final token = ref.watch(authProvider).session?.token;
  if (token != null) {
    api.authToken = token;
  }
  ref.onDispose(api.dispose);
  return api;
});
