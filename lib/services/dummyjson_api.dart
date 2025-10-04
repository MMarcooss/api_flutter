import 'package:http/http.dart' as http;

import './auth_service.dart';
import './user_service.dart';
import './cart_service.dart';
import '../models/user.dart';
import '../models/cart.dart';

/// Simple facade that composes the different services and shares tokens.
class DummyJsonApi {
  final AuthService auth;
  final UserService users;
  final CartService carts;

  DummyJsonApi({http.Client? client, String? baseUrl})
      : auth = AuthService(client: client, baseUrl: baseUrl),
        users = UserService(client: client, baseUrl: baseUrl),
        carts = CartService(client: client, baseUrl: baseUrl);

  /// Login and propagate tokens to the other services so they share auth state.
  Future<void> login(
      {required String username, required String password}) async {
    await auth.login(username: username, password: password);
    // propagate tokens
    users.setTokens(auth.accessToken, auth.refreshToken);
    carts.setTokens(auth.accessToken, auth.refreshToken);
  }

  Future<List<User>> getLatestUsers({int limit = 10}) =>
      users.getLatestUsers(limit: limit);
  Future<List<Cart>> getLatestCarts({int limit = 10}) =>
      carts.getLatestCarts(limit: limit);

  void logout() {
    auth.logout();
    users.setTokens(null, null);
    carts.setTokens(null, null);
  }
}
