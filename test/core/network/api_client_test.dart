import 'package:course_pilot/core/error/app_failure.dart';
import 'package:course_pilot/core/network/api_client.dart';
import 'package:course_pilot/core/network/mock/mock_api_interceptor.dart';
import 'package:course_pilot/core/network/mock/mock_route.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

ApiClient _clientWith(List<MockRoute> routes) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
    ..interceptors.add(MockApiInterceptor(routes: routes));
  return ApiClient(dio);
}

void main() {
  test('resolves a matching route with path parameters', () async {
    final client = _clientWith([
      MockRoute(
        method: 'GET',
        pathPattern: '/courses/:id',
        handler: (request) =>
            MockResponse(200, {'id': request.pathParameters['id']}),
      ),
    ]);

    final body = await client.get<Map<String, Object?>>('/courses/42');

    expect(body, {'id': '42'});
  });

  test('maps 401 to UnauthorizedFailure', () async {
    final client = _clientWith([
      MockRoute(
        method: 'GET',
        pathPattern: '/me',
        handler: (_) => const MockResponse(401),
      ),
    ]);

    expect(client.get<Object?>('/me'), throwsA(isA<UnauthorizedFailure>()));
  });

  test('carries the server message on error responses', () async {
    final client = _clientWith([
      MockRoute(
        method: 'POST',
        pathPattern: '/auth/login',
        handler: (_) =>
            const MockResponse(422, {'message': 'Invalid credentials'}),
      ),
    ]);

    expect(
      client.post<Object?>('/auth/login'),
      throwsA(
        isA<ServerFailure>()
            .having((f) => f.message, 'message', 'Invalid credentials')
            .having((f) => f.statusCode, 'statusCode', 422),
      ),
    );
  });

  test('returns 404 for unknown routes', () async {
    final client = _clientWith(const []);

    expect(
      client.get<Object?>('/missing'),
      throwsA(isA<ServerFailure>().having((f) => f.statusCode, 'code', 404)),
    );
  });
}
