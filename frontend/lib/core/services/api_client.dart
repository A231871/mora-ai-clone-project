import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../features/auth/models/auth_session.dart';
import '../../features/auth/services/session_storage.dart';
import '../../shared/models/workspace_models.dart';
import '../constants/api_constants.dart';

class ApiException implements Exception {
  const ApiException(this.statusCode, this.message, {this.details});

  final int statusCode;
  final String message;
  final dynamic details;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  final http.Client _httpClient = http.Client();

  Future<dynamic> get(
    String path, {
    Map<String, String?> queryParameters = const <String, String?>{},
    bool unwrapData = true,
  }) {
    return _send(
      method: 'GET',
      path: path,
      queryParameters: queryParameters,
      unwrapData: unwrapData,
    );
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    bool unwrapData = true,
  }) {
    return _send(
      method: 'POST',
      path: path,
      body: body,
      unwrapData: unwrapData,
    );
  }

  Future<dynamic> patch(
    String path, {
    Map<String, dynamic>? body,
    bool unwrapData = true,
  }) {
    return _send(
      method: 'PATCH',
      path: path,
      body: body,
      unwrapData: unwrapData,
    );
  }

  Future<dynamic> delete(
    String path, {
    Map<String, dynamic>? body,
    bool unwrapData = true,
  }) {
    return _send(
      method: 'DELETE',
      path: path,
      body: body,
      unwrapData: unwrapData,
    );
  }

  Future<dynamic> postMultipart(
    String path, {
    required String filePath,
    String fieldName = 'file',
    Map<String, String> fields = const <String, String>{},
    bool unwrapData = true,
    bool allowRefresh = true,
  }) async {
    final token = await SessionStorage.getAccessToken();
    final response = await _sendMultipartOnce(
      path: path,
      filePath: filePath,
      fieldName: fieldName,
      fields: fields,
      token: token,
    );

    if (response.statusCode == 401 &&
        allowRefresh &&
        await _refreshSession()) {
      return postMultipart(
        path,
        filePath: filePath,
        fieldName: fieldName,
        fields: fields,
        unwrapData: unwrapData,
        allowRefresh: false,
      );
    }

    return _parseResponse(response, unwrapData: unwrapData);
  }

  Future<dynamic> _send({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    Map<String, String?> queryParameters = const <String, String?>{},
    bool unwrapData = true,
    bool allowRefresh = true,
  }) async {
    final uri = _buildUri(path, queryParameters: queryParameters);
    final token = await SessionStorage.getAccessToken();
    final response = await _sendRequestOnce(
      method: method,
      uri: uri,
      token: token,
      body: body,
    );

    if (response.statusCode == 401 &&
        allowRefresh &&
        await _refreshSession()) {
      return _send(
        method: method,
        path: path,
        body: body,
        queryParameters: queryParameters,
        unwrapData: unwrapData,
        allowRefresh: false,
      );
    }

    return _parseResponse(response, unwrapData: unwrapData);
  }

  Future<http.Response> _sendRequestOnce({
    required String method,
    required Uri uri,
    required String? token,
    Map<String, dynamic>? body,
  }) {
    final headers = <String, String>{
      HttpHeaders.acceptHeader: 'application/json',
      HttpHeaders.contentTypeHeader: 'application/json',
      if (token != null && token.isNotEmpty)
        HttpHeaders.authorizationHeader: 'Bearer $token',
    };
    final encodedBody = body == null ? null : jsonEncode(body);

    switch (method) {
      case 'GET':
        return _httpClient.get(uri, headers: headers);
      case 'POST':
        return _httpClient.post(uri, headers: headers, body: encodedBody);
      case 'PATCH':
        return _httpClient.patch(uri, headers: headers, body: encodedBody);
      case 'DELETE':
        return _httpClient.delete(uri, headers: headers, body: encodedBody);
      default:
        throw UnsupportedError('Unsupported HTTP method: $method');
    }
  }

  Future<http.Response> _sendMultipartOnce({
    required String path,
    required String filePath,
    required String fieldName,
    required Map<String, String> fields,
    required String? token,
  }) async {
    final request = http.MultipartRequest('POST', _buildUri(path));
    request.headers[HttpHeaders.acceptHeader] = 'application/json';
    if (token != null && token.isNotEmpty) {
      request.headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
    }
    request.fields.addAll(fields);
    request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));

    final streamedResponse = await request.send();
    return http.Response.fromStream(streamedResponse);
  }

  Uri _buildUri(
    String path, {
    Map<String, String?> queryParameters = const <String, String?>{},
  }) {
    final baseUri = Uri.parse(ApiConstants.baseUrl);
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final query = <String, String>{
      for (final entry in queryParameters.entries)
        if (entry.value != null && entry.value!.isNotEmpty)
          entry.key: entry.value!,
    };

    return baseUri.replace(
      path: '${baseUri.path}$cleanPath',
      queryParameters: query.isEmpty ? null : query,
    );
  }

  dynamic _parseResponse(
    http.Response response, {
    required bool unwrapData,
  }) {
    final decoded = _decodeBody(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (unwrapData &&
          decoded is Map<String, dynamic> &&
          decoded.containsKey('data')) {
        return decoded['data'];
      }
      return decoded;
    }

    if (decoded is Map<String, dynamic>) {
      throw ApiException(
        response.statusCode,
        (decoded['message'] ?? 'Request failed').toString(),
        details: decoded['details'],
      );
    }

    throw ApiException(
      response.statusCode,
      response.body.isEmpty ? 'Request failed' : response.body,
    );
  }

  dynamic _decodeBody(String body) {
    if (body.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      return decoded;
    } catch (_) {
      return body;
    }
  }

  Future<bool> _refreshSession() async {
    final existingSession = await SessionStorage.loadSession();
    if (existingSession == null || existingSession.refreshToken.isEmpty) {
      await SessionStorage.clearSession();
      return false;
    }

    final response = await _httpClient.post(
      _buildUri('/auth/refresh'),
      headers: const <String, String>{
        HttpHeaders.acceptHeader: 'application/json',
        HttpHeaders.contentTypeHeader: 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'refreshToken': existingSession.refreshToken,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      await SessionStorage.clearSession();
      return false;
    }

    final decoded = _decodeBody(response.body);
    if (decoded is! Map<String, dynamic>) {
      await SessionStorage.clearSession();
      return false;
    }

    final nextUserJson = asJsonMap(decoded['user']);
    final nextSession = AuthSession(
      accessToken: (decoded['token'] ?? '').toString(),
      refreshToken:
          (decoded['refreshToken'] ?? existingSession.refreshToken).toString(),
      user: nextUserJson.isEmpty
          ? existingSession.user
          : AppUser.fromJson(nextUserJson),
    );

    if (nextSession.accessToken.isEmpty) {
      await SessionStorage.clearSession();
      return false;
    }

    await SessionStorage.saveSession(nextSession);
    return true;
  }
}
