import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/google_sign_in_config.dart';
import '../../../core/constants/api_constants.dart';
import '../../../shared/models/workspace_models.dart';
import '../../workspace/services/users_service.dart';
import '../models/auth_session.dart';
import '../models/google_sign_in_result.dart';
import 'session_storage.dart';
import '../../../core/services/chat_service.dart';

class AuthService {
  AuthService({
    http.Client? httpClient,
    UsersService? usersService,
  })  : _httpClient = httpClient ?? http.Client(),
        _usersService = usersService ?? UsersService();

  final http.Client _httpClient;
  final UsersService _usersService;

  GoogleSignIn _buildGoogleSignIn() {
    return GoogleSignIn(
      scopes: const ['email', 'profile'],
      serverClientId: GoogleSignInConfig.serverClientIdOrNull,
    );
  }

  Future<void> _clearGoogleSession({GoogleSignIn? googleSignIn}) async {
    final client = googleSignIn ?? _buildGoogleSignIn();

    try {
      await client.signOut();
    } catch (_) {
      // Clearing the local Google cache is best-effort.
    }

    try {
      await client.disconnect();
    } catch (_) {
      // Disconnect may fail when there is no active Google session.
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      // Login persists both the access token and refresh token so later API calls
      // and socket connections can authenticate without asking the user again.
      final response = await _httpClient.post(
        Uri.parse(ApiConstants.loginEndpoint),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      final data = _decodeJsonBody(response.body);
      if (response.statusCode == 200) {
        await _persistSessionFromPayload(data);
        return {
          'success': true,
          'message': data['message'] ?? 'Login successful',
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Login failed',
      };
    } catch (error) {
      return {'success': false, 'message': 'Network error: $error'};
    }
  }

  Future<Map<String, dynamic>> register(
    String username,
    String password,
  ) async {
    try {
      final response = await _httpClient.post(
        Uri.parse(ApiConstants.registerEndpoint),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      final data = _decodeJsonBody(response.body);
      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Registration successful',
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Registration failed',
      };
    } catch (error) {
      return {'success': false, 'message': 'Network error: $error'};
    }
  }

  Future<bool> isLoggedIn() {
    return SessionStorage.isLoggedIn();
  }

  Future<void> logout() async {
    final session = await SessionStorage.loadSession();

    try {
      if (session != null && session.accessToken.isNotEmpty) {
        await _httpClient.post(
          Uri.parse('${ApiConstants.baseUrl}/auth/logout'),
          headers: {
            'Content-Type': 'application/json',
            HttpHeaders.authorizationHeader: 'Bearer ${session.accessToken}',
          },
          body: jsonEncode({'refreshToken': session.refreshToken}),
        );
      }
    } catch (_) {
      // Local cleanup is more important than surfacing a logout transport error.
    } finally {
      // Local cleanup also disconnects realtime chat/reminder sockets.
      ChatService().disconnect();
      await _clearGoogleSession();
      await SessionStorage.clearSession();
    }
  }

  Future<void> logoutAll() async {
    final session = await SessionStorage.loadSession();

    try {
      if (session != null && session.accessToken.isNotEmpty) {
        await _httpClient.post(
          Uri.parse('${ApiConstants.baseUrl}/auth/logout-all'),
          headers: {
            'Content-Type': 'application/json',
            HttpHeaders.authorizationHeader: 'Bearer ${session.accessToken}',
          },
        );
      }
    } catch (_) {
      // Local cleanup is more important than surfacing a logout transport error.
    } finally {
      ChatService().disconnect();
      await _clearGoogleSession();
      await SessionStorage.clearSession();
    }
  }

  Future<AppUser?> hydrateCurrentUser() async {
    // The app can render instantly from cached session data, then quietly
    // refresh from the backend when the network is available.
    final cachedUser = await SessionStorage.getCurrentUser();
    try {
      return await _usersService.getCurrentUser();
    } catch (_) {
      return cachedUser;
    }
  }

  Future<GoogleSignInResult> signInWithGoogle() async {
    final config = GoogleSignInConfigSnapshot.current();
    try {
      // Google sign-in ends by exchanging the Google ID token with our own backend,
      // so the rest of the app still uses the same JWT/session model.
      final googleSignIn = _buildGoogleSignIn();
      await _clearGoogleSession(googleSignIn: googleSignIn);

      final account = await googleSignIn.signIn();
      if (account == null) {
        return GoogleSignInResult.failure(
          failure: const GoogleSignInFailure(
            code: GoogleSignInFailureCode.cancelled,
            message: 'cancelled',
          ),
        );
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        final code = config.hasExplicitServerClientId
            ? GoogleSignInFailureCode.noIdToken
            : GoogleSignInFailureCode.missingClientConfiguration;
        return GoogleSignInResult.failure(
          failure: GoogleSignInFailure(
            code: code,
            message: 'no_id_token',
            diagnostics: _buildDiagnostics(
              config,
              rawMessage:
                  'Google authentication completed without an ID token.',
            ),
          ),
        );
      }

      final response = await _httpClient.post(
        Uri.parse(ApiConstants.googleAuthEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      final data = _decodeJsonBody(response.body);

      if (response.statusCode == 200 && data['token'] != null) {
        await _persistSessionFromPayload(data);
        return GoogleSignInResult.success(
          message: data['message']?.toString() ?? 'Login successful',
        );
      }

      return GoogleSignInResult.failure(
        failure: GoogleSignInFailure(
          code: GoogleSignInFailureCode.backendRejected,
          message: data['message']?.toString() ?? 'Google login failed',
          diagnostics: _buildDiagnostics(
            config,
            rawMessage: data['message']?.toString(),
          ),
        ),
      );
    } on PlatformException catch (error) {
      return GoogleSignInResult.failure(
        failure: _classifyPlatformFailure(error, config),
      );
    } on SocketException catch (error) {
      return GoogleSignInResult.failure(
        failure: GoogleSignInFailure(
          code: GoogleSignInFailureCode.networkError,
          message: 'Network error: $error',
          rawMessage: error.message,
          diagnostics: _buildDiagnostics(
            config,
            platformCode: GoogleSignIn.kNetworkError,
            rawMessage: error.message,
          ),
        ),
      );
    } catch (error) {
      return GoogleSignInResult.failure(
        failure: GoogleSignInFailure(
          code: GoogleSignInFailureCode.unexpected,
          message: 'Unexpected error: $error',
          rawMessage: error.toString(),
          diagnostics: _buildDiagnostics(
            config,
            rawMessage: error.toString(),
          ),
        ),
      );
    }
  }

  Future<void> _persistSessionFromPayload(Map<String, dynamic> payload) async {
    // Backend auth responses always normalize to the same session shape.
    final token = payload['token']?.toString() ?? '';
    final refreshToken = payload['refreshToken']?.toString() ?? '';
    if (token.isEmpty || refreshToken.isEmpty) {
      throw const FormatException('Auth payload is missing tokens');
    }

    final session = AuthSession(
      accessToken: token,
      refreshToken: refreshToken,
      user: AppUser.fromJson(payload['user']),
    );
    await SessionStorage.saveSession(session);
  }

  Map<String, dynamic> _decodeJsonBody(String body) {
    if (body.isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    return <String, dynamic>{'message': decoded.toString()};
  }

  GoogleSignInFailure _classifyPlatformFailure(
    PlatformException error,
    GoogleSignInConfigSnapshot config,
  ) {
    final rawMessage = error.message ?? error.toString();
    final statusCode = _extractApiStatusCode(rawMessage);
    final diagnostics = _buildDiagnostics(
      config,
      platformCode: error.code,
      apiStatus: statusCode?.toString(),
      rawMessage: rawMessage,
    );

    switch (error.code) {
      case GoogleSignIn.kSignInCanceledError:
        return GoogleSignInFailure(
          code: GoogleSignInFailureCode.cancelled,
          message: 'cancelled',
          rawMessage: rawMessage,
          diagnostics: diagnostics,
        );
      case GoogleSignIn.kNetworkError:
        return GoogleSignInFailure(
          code: GoogleSignInFailureCode.networkError,
          message: 'network_error',
          rawMessage: rawMessage,
          diagnostics: diagnostics,
        );
      case GoogleSignIn.kSignInFailedError:
        if (statusCode == 10) {
          return GoogleSignInFailure(
            code: GoogleSignInFailureCode.androidDeveloperError,
            message: 'android_developer_error',
            rawMessage: rawMessage,
            diagnostics: diagnostics,
          );
        }

        return GoogleSignInFailure(
          code: GoogleSignInFailureCode.signInFailed,
          message: 'sign_in_failed',
          rawMessage: rawMessage,
          diagnostics: diagnostics,
        );
      default:
        return GoogleSignInFailure(
          code: GoogleSignInFailureCode.unexpected,
          message: error.code,
          rawMessage: rawMessage,
          diagnostics: diagnostics,
        );
    }
  }

  Map<String, String> _buildDiagnostics(
    GoogleSignInConfigSnapshot config, {
    String? platformCode,
    String? apiStatus,
    String? rawMessage,
  }) {
    return <String, String>{
      'androidPackage': config.androidPackageName,
      'serverClientId': config.serverClientIdDisplay,
      'serverClientIdSource': config.hasExplicitServerClientId
          ? 'dart-define GOOGLE_SERVER_CLIENT_ID'
          : 'native default_web_client_id fallback',
      if (platformCode != null && platformCode.isNotEmpty)
        'platformCode': platformCode,
      if (apiStatus != null && apiStatus.isNotEmpty) 'apiStatus': apiStatus,
      if (rawMessage != null && rawMessage.isNotEmpty) 'rawMessage': rawMessage,
    };
  }

  int? _extractApiStatusCode(String rawMessage) {
    final match = RegExp(r'ApiException:\s*(\d+)').firstMatch(rawMessage);
    if (match == null) {
      return null;
    }
    return int.tryParse(match.group(1)!);
  }
}
