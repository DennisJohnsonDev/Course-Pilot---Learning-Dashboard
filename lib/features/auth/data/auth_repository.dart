import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/cache_store.dart';
import '../../../core/storage/token_storage.dart';
import 'auth_remote_data_source.dart';
import 'models/user.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    remote: AuthRemoteDataSource(ref.watch(apiClientProvider)),
    tokenStorage: ref.watch(tokenStorageProvider),
    cacheStore: ref.watch(cacheStoreProvider),
  ),
);

class AuthRepository {
  AuthRepository({
    required this._remote,
    required this._tokenStorage,
    required this._cacheStore,
  });

  final AuthRemoteDataSource _remote;
  final TokenStorage _tokenStorage;
  final CacheStore _cacheStore;

  static const _userKey = 'user';

  Future<User> signIn({required String email, required String password}) async {
    final response = await _remote.login(email: email, password: password);
    await _tokenStorage.saveAccessToken(response.accessToken);
    await _cacheStore.write(_userKey, response.user.toJson());
    return response.user;
  }

  User? savedUser() {
    try {
      return switch (_cacheStore.read(_userKey)?.data) {
        final Map<String, Object?> json => User.fromJson(json),
        _ => null,
      };
    } on Object {
      return null;
    }
  }

  Future<bool> hasSession() async {
    try {
      return await _tokenStorage.readAccessToken() != null;
    } on PlatformException {
      // An unreadable keychain/keystore should land the user on Login, not crash.
      return false;
    }
  }

  Future<void> signOut() async {
    await _tokenStorage.clear();
    await _cacheStore.clear();
  }
}
