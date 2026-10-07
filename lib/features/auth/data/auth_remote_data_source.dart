import '../../../core/network/api_client.dart';
import 'models/login_response.dart';

abstract final class AuthEndpoints {
  static const login = '/auth/login';
}

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._client);

  final ApiClient _client;

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final json = await _client.post<Map<String, Object?>>(
      AuthEndpoints.login,
      body: {'email': email, 'password': password},
    );
    return LoginResponse.fromJson(json);
  }
}
