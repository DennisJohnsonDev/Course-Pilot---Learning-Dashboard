import 'package:course_pilot/core/error/app_failure.dart';
import 'package:course_pilot/core/network/api_client.dart';
import 'package:course_pilot/core/network/mock/mock_api_interceptor.dart';
import 'package:course_pilot/core/network/mock/mock_route.dart';
import 'package:course_pilot/features/courses/data/course_mock_routes.dart';
import 'package:course_pilot/features/courses/data/course_remote_data_source.dart';
import 'package:course_pilot/features/courses/data/course_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

CourseRepository _repository(List<MockRoute> routes) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
    ..interceptors.add(MockApiInterceptor(routes: routes));
  return CourseRepository(remote: CourseRemoteDataSource(ApiClient(dio)));
}

void main() {
  test('fetches and parses courses', () async {
    final courses = await _repository(courseMockRoutes()).fetchCourses();

    expect(courses, hasLength(3));
    expect(courses.first.title, 'Python Programming');
    expect(courses.first.instructor, 'John Smith');
    expect(courses.first.progress, 65);
    expect(courses.first.lessons, 20);
  });

  test('returns an empty list when there are no courses', () async {
    final repository = _repository(courseMockRoutes(CourseMockScenario.empty));

    expect(await repository.fetchCourses(), isEmpty);
  });

  test('surfaces server errors as a ServerFailure', () async {
    final repository = _repository(
      courseMockRoutes(CourseMockScenario.failure),
    );

    await expectLater(
      repository.fetchCourses(),
      throwsA(
        isA<ServerFailure>()
            .having((f) => f.statusCode, 'statusCode', 500)
            .having(
              (f) => f.message,
              'message',
              'Courses are unavailable right now.',
            ),
      ),
    );
  });

  test('treats a malformed payload as a ServerFailure', () async {
    final repository = _repository([
      MockRoute(
        method: 'GET',
        pathPattern: CourseEndpoints.courses,
        handler: (_) => const MockResponse(200, [
          {'id': '1', 'title': 'Broken'},
        ]),
      ),
    ]);

    await expectLater(repository.fetchCourses(), throwsA(isA<ServerFailure>()));
  });
}
