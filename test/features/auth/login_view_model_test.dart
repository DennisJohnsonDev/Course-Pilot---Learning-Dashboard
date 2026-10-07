import 'package:course_pilot/core/network/api_client.dart';
import 'package:course_pilot/core/network/mock/mock_api_interceptor.dart';
import 'package:course_pilot/core/storage/cache_store.dart';
import 'package:course_pilot/core/storage/token_storage.dart';
import 'package:course_pilot/features/auth/data/auth_mock_routes.dart';
import 'package:course_pilot/features/auth/data/auth_remote_data_source.dart';
import 'package:course_pilot/features/auth/data/auth_repository.dart';
import 'package:course_pilot/features/auth/presentation/login_state.dart';
import 'package:course_pilot/features/auth/presentation/login_view_model.dart';
import 'package:course_pilot/features/auth/presentation/session_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _InMemoryTokenStorage implements TokenStorage {
  String? token;

  @override
  Future<String?> readAccessToken() async => token;

  @override
  Future<void> saveAccessToken(String token) async => this.token = token;

  @override
  Future<void> clear() async => token = null;
}

class _InMemoryCacheStore implements CacheStore {
  final entries = <String, CacheEntry>{};

  @override
  Future<void> write(String key, Object? data) async =>
      entries[key] = CacheEntry(data: data, savedAt: DateTime.now());

  @override
  CacheEntry? read(String key) => entries[key];

  @override
  Future<void> remove(String key) async => entries.remove(key);

  @override
  Future<void> clear() async => entries.clear();
}

void main() {
  late _InMemoryTokenStorage tokenStorage;
  late ProviderContainer container;

  setUp(() {
    tokenStorage = _InMemoryTokenStorage();
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..interceptors.add(MockApiInterceptor(routes: authMockRoutes));
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          AuthRepository(
            remote: AuthRemoteDataSource(ApiClient(dio)),
            tokenStorage: tokenStorage,
            cacheStore: _InMemoryCacheStore(),
          ),
        ),
      ],
    );
    container.listen(loginViewModelProvider, (_, _) {});
  });

  tearDown(() => container.dispose());

  LoginViewModel viewModel() => container.read(loginViewModelProvider.notifier);
  LoginState state() => container.read(loginViewModelProvider);

  test('starts idle without validation errors', () {
    expect(state().status, LoginStatus.idle);
    expect(state().emailError, isNull);
    expect(state().passwordError, isNull);
  });

  test('shows validation errors only after submitting', () async {
    viewModel().updateEmail('not-an-email');
    expect(state().emailError, isNull);

    await viewModel().submit();

    expect(state().emailError, 'Enter a valid email address.');
    expect(state().passwordError, 'Enter your password.');
    expect(state().status, LoginStatus.idle);
    expect(tokenStorage.token, isNull);
  });

  test('clears a validation error once the field becomes valid', () async {
    await viewModel().submit();
    expect(state().emailError, 'Enter your email address.');

    viewModel().updateEmail(DemoAccount.email);

    expect(state().emailError, isNull);
  });

  test('signs in with valid credentials', () async {
    viewModel()
      ..updateEmail('  ${DemoAccount.email} ')
      ..updatePassword(DemoAccount.password);

    final submission = viewModel().submit();
    expect(state().isSubmitting, isTrue);
    await submission;

    expect(state().status, LoginStatus.success);
    expect(container.read(sessionControllerProvider), isTrue);
    expect(tokenStorage.token, isNotNull);
  });

  test(
    'reports a failure for wrong credentials and clears it on edit',
    () async {
      viewModel()
        ..updateEmail(DemoAccount.email)
        ..updatePassword('wrong-password');

      await viewModel().submit();

      expect(state().status, LoginStatus.failure);
      expect(state().failureMessage, 'Incorrect email or password.');
      expect(container.read(sessionControllerProvider), isFalse);

      viewModel().updatePassword('wrong-password2');

      expect(state().failureMessage, isNull);
      expect(state().status, LoginStatus.idle);
    },
  );
}
