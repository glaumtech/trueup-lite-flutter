import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

class AuthSession {
  final String token;
  final String username;
  final bool billingKioskUser;

  const AuthSession({
    required this.token,
    required this.username,
    required this.billingKioskUser,
  });
}

class AuthService {
  static const String tokenKey = 'store_auth_token';
  static const String usernameKey = 'store_auth_username';
  static const String staffKey = 'store_auth_staff';
  static const String sessionKey = 'store_auth_session';

  Future<AuthSession?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final active = prefs.getBool(sessionKey) ?? false;
    final token = prefs.getString(tokenKey);
    final username = prefs.getString(usernameKey);
    final isStaff = prefs.getBool(staffKey) ?? false;

    if (!active || token == null || username == null || !isStaff) {
      return null;
    }
    return AuthSession(
      token: token,
      username: username,
      billingKioskUser: isStaff,
    );
  }

  static Future<AuthSession?> loadSessionStatic() async {
    return AuthService().loadSession();
  }

  Future<AuthSession> login(String username, String password) async {
    final uri = Uri.parse('${ApiService.baseUrl}/reg/login');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({'username': username, 'password': password}),
    );

    if (response.statusCode != 200) {
      throw ApiException('Invalid credentials', response.statusCode);
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final token = data['token'] as String?;
    final name = data['username'] as String?;
    final isStaff = data['billingKioskUser'] == true;

    if (token == null || name == null) {
      throw ApiException('Unexpected login response');
    }
    if (!isStaff) {
      throw ApiException('Staff access required for online orders');
    }

    final session = AuthSession(
      token: token,
      username: name,
      billingKioskUser: isStaff,
    );
    await _persistSession(session);
    return session;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(tokenKey);
    if (token != null) {
      try {
        await http.post(
          Uri.parse('${ApiService.baseUrl}/reg/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      } catch (_) {}
    }
    await clearSession();
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(sessionKey);
    await prefs.remove(tokenKey);
    await prefs.remove(usernameKey);
    await prefs.remove(staffKey);
  }

  Future<void> _persistSession(AuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(sessionKey, true);
    await prefs.setString(tokenKey, session.token);
    await prefs.setString(usernameKey, session.username);
    await prefs.setBool(staffKey, session.billingKioskUser);
  }
}
