import 'dart:convert';
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/google_sign_in_config.dart';
import '../../../core/constants/api_constants.dart';
import '../models/google_sign_in_result.dart';

class AuthService {
  static const String _tokenKey = 'jwt_token';

  // Login Method
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.loginEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Save the JWT token locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, data['token']);
        return {'success': true, 'message': 'Login successful'};
      } else {
        return {'success': false, 'message': data['error'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Register Method
  Future<Map<String, dynamic>> register(
      String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.registerEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'message': 'Registration successful'};
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Registration failed'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Check if User is Logged In
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_tokenKey);
  }

  // Logout Method
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<GoogleSignInResult> signInWithGoogle() async {
    final config = GoogleSignInConfigSnapshot.current();
    try {
      final googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId: GoogleSignInConfig.serverClientIdOrNull,
      );

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

      final response = await http.post(
        Uri.parse(ApiConstants.googleAuthEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, data['token'] as String);
        return const GoogleSignInResult.success(message: 'Login successful');
      }

      return GoogleSignInResult.failure(
        failure: GoogleSignInFailure(
          code: GoogleSignInFailureCode.backendRejected,
          message: data['error']?.toString() ?? 'Google login failed',
          diagnostics: _buildDiagnostics(
            config,
            rawMessage: data['error']?.toString(),
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
