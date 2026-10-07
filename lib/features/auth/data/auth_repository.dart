import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import 'auth_remote_data_source.dart';
import 'models/user.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    remote: AuthRemoteDataSource(ref.watch(apiClientProvider)),
    tokenStorage: ref.watch(tokenStorageProvider),
  ),
);

class AuthRepository {
  AuthRepository({required this._remote, required this._tokenStorage});

  final AuthRemoteDataSource _remote;
  final TokenStorage _tokenStorage;

  Future<User> signIn({required String email, required String password}) async {
    final response = await _remote.login(email: email, password: password);
    await _tokenStorage.saveAccessToken(response.accessToken);
    return response.user;
  }

  Future<bool> hasSession() async {
    try {
      return await _tokenStorage.readAccessToken() != null;
    } on PlatformException {
      // An unreadable keychain/keystore should land the user on Login, not crash.
      return false;
    }
  }

  Future<void> signOut() => _tokenStorage.clear();
}
