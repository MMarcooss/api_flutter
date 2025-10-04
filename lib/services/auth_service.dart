// services/auth/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import './base_service.dart';
import '../../models/user.dart';

/// Serviço dedicado para operações de autenticação
class AuthService extends BaseApiService {
  AuthService({http.Client? client, String? baseUrl})
      : super(client: client, baseUrl: baseUrl ?? 'https://dummyjson.com');

  /// Obtém informações do usuário atualmente autenticado
  Future<User?> getCurrentUser() async {
    if (accessToken == null) return null;

    final uri = Uri.parse('$baseUrl/auth/me');
    final res = await getWithRetry(uri);

    if (res.statusCode == 401 || res.statusCode == 403) {
      return null;
    }

    if (res.statusCode != 200) {
      throw Exception(
          'Erro ao buscar usuário atual: ${res.statusCode} ${res.body}');
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    return User.fromJson(map);
  }

  /// Verifica se o usuário está autenticado
  bool get isAuthenticated => accessToken != null;

  /// Faz logout limpando os tokens
  void logoutUser() {
    logout(); // Chama o método da classe pai
  }

  /// Login personalizado com retorno de dados do usuário
  Future<User> loginWithUserData({
    required String username,
    required String password,
    int expiresInMins = 30,
  }) async {
    await login(
      username: username,
      password: password,
      expiresInMins: expiresInMins,
    );

    final user = await getCurrentUser();
    if (user == null) {
      throw Exception('Falha ao obter dados do usuário após login');
    }

    return user;
  }
}
