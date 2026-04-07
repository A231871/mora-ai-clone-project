import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/models/workspace_models.dart';
import '../models/auth_session.dart';

class SessionStorage {
  SessionStorage._();

  static const String _sessionKey = 'auth_session';
  static const String _legacyTokenKey = 'jwt_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _currentUserKey = 'current_user';
  static const String _systemRoleKey = 'system_role';

  static Future<void> saveSession(AuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(session.toJson()));
    await prefs.setString(_legacyTokenKey, session.accessToken);
    await prefs.setString(_refreshTokenKey, session.refreshToken);
    await prefs.setString(_currentUserKey, jsonEncode(session.user.toJson()));
    await prefs.setString(_systemRoleKey, session.user.systemRole);
  }

  static Future<AuthSession?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final storedSession = prefs.getString(_sessionKey);

    if (storedSession != null && storedSession.isNotEmpty) {
      try {
        final decoded = jsonDecode(storedSession);
        if (decoded is Map<String, dynamic>) {
          return AuthSession.fromJson(decoded);
        }
        if (decoded is Map) {
          return AuthSession.fromJson(Map<String, dynamic>.from(decoded));
        }
      } catch (_) {
        // Fall through to the legacy keys.
      }
    }

    final token = prefs.getString(_legacyTokenKey);
    if (token == null || token.isEmpty) {
      return null;
    }

    final userRaw = prefs.getString(_currentUserKey);
    final userJson = userRaw == null ? <String, dynamic>{} : asJsonMap(userRaw);
    final systemRole =
        prefs.getString(_systemRoleKey) ?? userJson['systemRole']?.toString();

    return AuthSession(
      accessToken: token,
      refreshToken: prefs.getString(_refreshTokenKey) ?? '',
      user: AppUser.fromJson(<String, dynamic>{
        ...userJson,
        'systemRole': systemRole ?? 'member',
        'username': userJson['username'] ?? 'commander',
      }),
    );
  }

  static Future<String?> getAccessToken() async {
    final session = await loadSession();
    return session?.accessToken.isNotEmpty == true
        ? session!.accessToken
        : null;
  }

  static Future<String?> getRefreshToken() async {
    final session = await loadSession();
    return session?.refreshToken.isNotEmpty == true
        ? session!.refreshToken
        : null;
  }

  static Future<AppUser?> getCurrentUser() async {
    final session = await loadSession();
    return session?.user;
  }

  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> updateUser(AppUser user) async {
    final session = await loadSession();
    if (session == null) {
      return;
    }
    await saveSession(session.copyWith(user: user));
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    await prefs.remove(_legacyTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_currentUserKey);
    await prefs.remove(_systemRoleKey);
  }
}
