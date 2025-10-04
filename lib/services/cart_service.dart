// services/cart/cart_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import './base_service.dart';
import '../../models/cart.dart';

/// Serviço para operações relacionadas aos carrinhos
class CartService extends BaseApiService {
  CartService({http.Client? client, String? baseUrl})
      : super(client: client, baseUrl: baseUrl ?? 'https://dummyjson.com');

  /// Obtém os últimos N carrinhos.
  /// Se sortBy/order não estiver disponível, ordena localmente por id desc.
  Future<List<Cart>> getLatestCarts({int limit = 10}) async {
    final trySorted =
        Uri.parse('$baseUrl/carts?limit=$limit&sortBy=id&order=desc');
    var res = await getWithRetry(trySorted);

    if (res.statusCode != 200) {
      // fallback sem sort, depois ordena localmente
      final fallback = Uri.parse('$baseUrl/carts?limit=$limit');
      res = await getWithRetry(fallback);
      if (res.statusCode != 200) {
        throw Exception('Erro ao buscar carts: ${res.statusCode} ${res.body}');
      }
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      final list = (map['carts'] as List).cast<Map<String, dynamic>>();
      list.sort((a, b) => (b['id'] as int).compareTo(a['id'] as int));
      return list.map(Cart.fromJson).toList();
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (map['carts'] as List).cast<Map<String, dynamic>>();
    return list.map(Cart.fromJson).toList();
  }

  /// Busca todos os carrinhos com paginação
  Future<List<Cart>> getAllCarts({
    int limit = 20,
    int skip = 0,
  }) async {
    final uri = Uri.parse('$baseUrl/carts?limit=$limit&skip=$skip');
    final res = await getWithRetry(uri);

    if (res.statusCode != 200) {
      throw Exception('Erro ao buscar carts: ${res.statusCode} ${res.body}');
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (map['carts'] as List).cast<Map<String, dynamic>>();
    return list.map(Cart.fromJson).toList();
  }

  /// Busca um carrinho específico por ID
  Future<Cart?> getCartById(int id) async {
    final uri = Uri.parse('$baseUrl/carts/$id');
    final res = await getWithRetry(uri);

    if (res.statusCode == 404) {
      return null;
    }

    if (res.statusCode != 200) {
      throw Exception('Erro ao buscar cart: ${res.statusCode} ${res.body}');
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    return Cart.fromJson(map);
  }

  /// Busca carrinhos de um usuário específico
  Future<List<Cart>> getCartsByUserId(int userId) async {
    final uri = Uri.parse('$baseUrl/carts/user/$userId');
    final res = await getWithRetry(uri);

    if (res.statusCode != 200) {
      throw Exception(
          'Erro ao buscar carts do usuário: ${res.statusCode} ${res.body}');
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (map['carts'] as List).cast<Map<String, dynamic>>();
    return list.map(Cart.fromJson).toList();
  }

  /// Cria um novo carrinho
  Future<Cart> createCart({
    required int userId,
    required List<Map<String, dynamic>> products,
  }) async {
    final uri = Uri.parse('$baseUrl/carts/add');
    final res = await postWithRetry(
      uri,
      body: jsonEncode({
        'userId': userId,
        'products': products,
      }),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Erro ao criar cart: ${res.statusCode} ${res.body}');
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    return Cart.fromJson(map);
  }

  /// Atualiza um carrinho existente
  Future<Cart> updateCart({
    required int id,
    Map<String, dynamic>? updates,
  }) async {
    final uri = Uri.parse('$baseUrl/carts/$id');
    final res = await putWithRetry(
      uri,
      body: jsonEncode(updates ?? {}),
    );

    if (res.statusCode != 200) {
      throw Exception('Erro ao atualizar cart: ${res.statusCode} ${res.body}');
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    return Cart.fromJson(map);
  }

  /// Remove um carrinho
  Future<bool> deleteCart(int id) async {
    final uri = Uri.parse('$baseUrl/carts/$id');
    final res = await deleteWithRetry(uri);

    if (res.statusCode != 200) {
      throw Exception('Erro ao deletar cart: ${res.statusCode} ${res.body}');
    }

    return true;
  }
}
