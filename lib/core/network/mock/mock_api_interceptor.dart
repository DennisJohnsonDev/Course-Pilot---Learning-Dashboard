import 'package:dio/dio.dart';

import 'mock_route.dart';

/// Answers requests locally instead of hitting the network, so the rest of
/// the stack (interceptors, error mapping, repositories) runs unchanged.
class MockApiInterceptor extends Interceptor {
  MockApiInterceptor({required this.routes, this.latency = Duration.zero});

  final List<MockRoute> routes;
  final Duration latency;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    await Future<void>.delayed(latency);

    final mock = _resolve(options);
    if (mock.isOffline) {
      handler.reject(
        DioException.connectionError(
          requestOptions: options,
          reason: 'Mock network is offline',
        ),
        true,
      );
      return;
    }

    final response = Response<Object?>(
      requestOptions: options,
      statusCode: mock.statusCode,
      data: mock.data,
    );

    if (mock.isSuccessful) {
      handler.resolve(response, true);
    } else {
      handler.reject(
        DioException.badResponse(
          statusCode: mock.statusCode,
          requestOptions: options,
          response: response,
        ),
        true,
      );
    }
  }

  MockResponse _resolve(RequestOptions options) {
    for (final route in routes) {
      final parameters = route.match(options.method, options.path);
      if (parameters != null) {
        return route.handler(MockRequest(options, parameters));
      }
    }
    return MockResponse(404, {
      'message': 'No mock route for ${options.method} ${options.path}',
    });
  }
}
