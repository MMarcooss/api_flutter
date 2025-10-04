// services/base/base_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Classe base para serviços que consomem a DummyJSON API
/// Gerencia autenticação, refresh de tokens e headers comuns
abstract class BaseApiService {
  BaseApiService({http.Client? client, this.baseUrl = 'https://dummyjson.com'})
      : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  String? _accessToken;
  String? _refreshToken;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  Map<String, String> get baseHeaders => {
        'Content-Type': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  /// Faz login e guarda o accessToken/refreshToken (Bearer).
  Future<void> login({
    required String username,
    required String password,
    int expiresInMins = 30,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/login');
    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'expiresInMins': expiresInMins,
      }),
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      _accessToken = body['accessToken'] as String?;
      _refreshToken = body['refreshToken'] as String?;
    } else {
      throw Exception('Falha no login (${res.statusCode}): ${res.body}');
    }
  }

  /// Tenta renovar o accessToken usando o refreshToken.
  Future<bool> tryRefresh({int expiresInMins = 30}) async {
    if (_refreshToken == null) return false;
    final uri = Uri.parse('$baseUrl/auth/refresh');
    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'refreshToken': _refreshToken,
        'expiresInMins': expiresInMins,
      }),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      _accessToken = body['accessToken'] as String?;
      // pode vir um novo refreshToken
      _refreshToken = (body['refreshToken'] as String?) ?? _refreshToken;
      return true;
    }
    return false;
  }

  /// GET com tentativa de refresh automático em caso de 401/403.
  Future<http.Response> getWithRetry(Uri uri) async {
    var res = await _client.get(uri, headers: baseHeaders);
    if (res.statusCode == 401 || res.statusCode == 403) {
      final ok = await tryRefresh();
      if (ok) {
        res = await _client.get(uri, headers: baseHeaders);
      }
    }
    return res;
  }

  /// POST com tentativa de refresh automático em caso de 401/403.
  Future<http.Response> postWithRetry(Uri uri, {String? body}) async {
    var res = await _client.post(uri, headers: baseHeaders, body: body);
    if (res.statusCode == 401 || res.statusCode == 403) {
      final ok = await tryRefresh();
      if (ok) {
        res = await _client.post(uri, headers: baseHeaders, body: body);
      }
    }
    return res;
  }

  /// PUT com tentativa de refresh automático em caso de 401/403.
  Future<http.Response> putWithRetry(Uri uri, {String? body}) async {
    var res = await _client.put(uri, headers: baseHeaders, body: body);
    if (res.statusCode == 401 || res.statusCode == 403) {
      final ok = await tryRefresh();
      if (ok) {
        res = await _client.put(uri, headers: baseHeaders, body: body);
      }
    }
    return res;
  }

  /// DELETE com tentativa de refresh automático em caso de 401/403.
  Future<http.Response> deleteWithRetry(Uri uri) async {
    var res = await _client.delete(uri, headers: baseHeaders);
    if (res.statusCode == 401 || res.statusCode == 403) {
      final ok = await tryRefresh();
      if (ok) {
        res = await _client.delete(uri, headers: baseHeaders);
      }
    }
    return res;
  }

  /// Faz logout limpando os tokens
  void logout() {
    _accessToken = null;
    _refreshToken = null;
  }

  /// Define os tokens (útil para classes filhas)
  void setTokens(String? accessToken, String? refreshToken) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }
}
