import 'dart:convert';
import 'package:http/http.dart' as http;

import './base_service.dart';
import '../../models/user.dart';

/// Serviço para operações relacionadas aos usuários
class UserService extends BaseApiService {
  UserService({http.Client? client, String? baseUrl})
      : super(client: client, baseUrl: baseUrl ?? 'https://dummyjson.com');

  /// Obtém os últimos N usuários (ordem por id desc se disponível).
  Future<List<User>> getLatestUsers({int limit = 10}) async {
    final uri = Uri.parse(
        '$baseUrl/users?limit=$limit&sortBy=id&order=desc&select=id,firstName,lastName,username,email,image');
    var res = await getWithRetry(uri);

    if (res.statusCode != 200) {
      // fallback simples sem sortBy/order
      final fallback = Uri.parse(
          '$baseUrl/users?limit=$limit&select=id,firstName,lastName,username,email,image');
      res = await getWithRetry(fallback);
      if (res.statusCode != 200) {
        throw Exception('Erro ao buscar users: ${res.statusCode} ${res.body}');
      }
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      final list = (map['users'] as List).cast<Map<String, dynamic>>();
      list.sort((a, b) => (b['id'] as int).compareTo(a['id'] as int));
      return list.map(User.fromJson).toList();
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (map['users'] as List).cast<Map<String, dynamic>>();
    return list.map(User.fromJson).toList();
  }

  /// Busca todos os usuários com paginação
  Future<List<User>> getAllUsers({
    int limit = 30,
    int skip = 0,
    String? select,
  }) async {
    final selectParam =
        select ?? 'id,firstName,lastName,username,email,image,gender';
    final uri =
        Uri.parse('$baseUrl/users?limit=$limit&skip=$skip&select=$selectParam');
    final res = await getWithRetry(uri);

    if (res.statusCode != 200) {
      throw Exception('Erro ao buscar users: ${res.statusCode} ${res.body}');
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (map['users'] as List).cast<Map<String, dynamic>>();
    return list.map(User.fromJson).toList();
  }

  /// Busca todos os usuários paginando (útil quando a API limita o `limit`).
  Future<List<User>> _fetchAllUsers(
      {int pageSize = 100, String? select}) async {
    final List<User> all = [];
    int skip = 0;

    while (true) {
      final batch = await getAllUsers(
          limit: pageSize,
          skip: skip,
          select:
              select ?? 'id,firstName,lastName,username,email,image,gender');
      if (batch.isEmpty) break;
      all.addAll(batch);
      if (batch.length < pageSize) break;
      skip += pageSize;
    }

    return all;
  }

  /// Busca um usuário específico por ID
  Future<User?> getUserById(int id) async {
    final uri = Uri.parse('$baseUrl/users/$id');
    final res = await getWithRetry(uri);

    if (res.statusCode == 404) {
      return null;
    }

    if (res.statusCode != 200) {
      throw Exception('Erro ao buscar user: ${res.statusCode} ${res.body}');
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    return User.fromJson(map);
  }

  /// Busca usuários por termo de pesquisa
  Future<List<User>> searchUsers(String query) async {
    final uri = Uri.parse('$baseUrl/users/search?q=$query');
    final res = await getWithRetry(uri);

    if (res.statusCode != 200) {
      throw Exception('Erro ao buscar users: ${res.statusCode} ${res.body}');
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (map['users'] as List).cast<Map<String, dynamic>>();
    return list.map(User.fromJson).toList();
  }

  /// Busca usuários com filtros avançados
  /// Busca usuários com filtros avançados aplicados localmente.
  ///
  /// Parâmetros suportados: `name`, `email`, `gender`.
  /// - `matchAll` (default true): se true, combina filtros com AND, caso contrário OR.
  /// - `pageSize`: número de itens por página ao buscar todos os usuários (padrão 100).
  Future<List<User>> searchUsersWithFilters({
    String? name,
    String? email,
    String? gender,
    bool matchAll = true,
    int pageSize = 100,
  }) async {
    // Coleta todos os usuários paginando para garantir que todos os resultados
    // estejam disponíveis para filtragem local.
    final allUsers = await _fetchAllUsers(pageSize: pageSize);

    // Se nenhum filtro foi passado, retorna todos (ou vazio, conforme preferir).
    if ((name == null || name.isEmpty) &&
        (email == null || email.isEmpty) &&
        (gender == null || gender.isEmpty)) {
      return allUsers;
    }

    final nameLower = name?.toLowerCase();
    final emailLower = email?.toLowerCase();
    final genderLower = gender?.toLowerCase();

    return allUsers.where((user) {
      final checks = <bool>[];

      if (nameLower != null && nameLower.isNotEmpty) {
        final fullName = user.fullName.toLowerCase();
        final username = user.username.toLowerCase();
        checks
            .add(fullName.contains(nameLower) || username.contains(nameLower));
      }

      if (emailLower != null && emailLower.isNotEmpty) {
        checks.add(user.email.toLowerCase().contains(emailLower));
      }

      if (genderLower != null && genderLower.isNotEmpty) {
        checks.add((user.gender ?? '').toLowerCase() == genderLower);
      }

      if (checks.isEmpty) return true;
      return matchAll ? checks.every((c) => c) : checks.any((c) => c);
    }).toList();
  }
}
