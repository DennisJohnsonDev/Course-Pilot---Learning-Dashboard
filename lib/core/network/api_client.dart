import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../error/app_failure.dart';
import '../storage/token_storage.dart';
import 'auth_interceptor.dart';
import 'dio_error_mapper.dart';
import 'mock/mock_api_interceptor.dart';
import 'mock/mock_routes.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  );

  dio.interceptors.add(AuthInterceptor(ref.watch(tokenStorageProvider)));
  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (line) => debugPrint(line.toString()),
      ),
    );
  }
  if (AppConfig.useMockApi) {
    dio.interceptors.add(
      MockApiInterceptor(
        routes: ref.watch(mockRoutesProvider),
        latency: AppConfig.mockLatency,
      ),
    );
  }

  return dio;
});

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(dioProvider)),
);

/// The single entry point for HTTP calls. Every transport error leaves this
/// class as an [AppFailure], so callers never deal with Dio types.
class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<T> get<T>(String path, {Map<String, Object?>? queryParameters}) {
    return _send(() => _dio.get<T>(path, queryParameters: queryParameters));
  }

  Future<T> post<T>(String path, {Object? body}) {
    return _send(() => _dio.post<T>(path, data: body));
  }

  Future<T> _send<T>(Future<Response<T>> Function() request) async {
    try {
      final response = await request();
      return response.data as T;
    } on DioException catch (exception) {
      throw mapDioException(exception);
    }
  }
}
