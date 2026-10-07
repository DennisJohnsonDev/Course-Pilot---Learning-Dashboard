import '../../../core/network/mock/mock_route.dart';
import 'auth_remote_data_source.dart';

abstract final class DemoAccount {
  static const email = 'demo@coursepilot.app';
  static const password = 'password123';
}

const authMockRoutes = [
  MockRoute(method: 'POST', pathPattern: AuthEndpoints.login, handler: _login),
];

MockResponse _login(MockRequest request) {
  final (email, password) = switch (request.options.data) {
    {'email': final String email, 'password': final String password} => (
      email,
      password,
    ),
    _ => ('', ''),
  };

  final isDemoAccount =
      email.toLowerCase() == DemoAccount.email &&
      password == DemoAccount.password;

  if (!isDemoAccount) {
    return const MockResponse(401, {'message': 'Incorrect email or password.'});
  }

  return const MockResponse(200, {
    'accessToken': 'mock-access-token',
    'user': {'id': 'u_001', 'name': 'Alex Morgan', 'email': DemoAccount.email},
  });
}
