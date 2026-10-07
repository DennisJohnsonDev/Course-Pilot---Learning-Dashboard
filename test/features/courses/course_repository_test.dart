import 'dart:io';

import 'package:course_pilot/core/error/app_failure.dart';
import 'package:course_pilot/core/network/api_client.dart';
import 'package:course_pilot/core/network/mock/mock_api_interceptor.dart';
import 'package:course_pilot/core/network/mock/mock_route.dart';
import 'package:course_pilot/core/storage/cache_store.dart';
import 'package:course_pilot/features/courses/data/course_local_data_source.dart';
import 'package:course_pilot/features/courses/data/course_mock_routes.dart';
import 'package:course_pilot/features/courses/data/course_remote_data_source.dart';
import 'package:course_pilot/features/courses/data/course_repository.dart';
import 'package:course_pilot/features/courses/data/models/course.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  late Directory hiveDirectory;
  late CacheStore cacheStore;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('course_cache');
    Hive.init(hiveDirectory.path);
    cacheStore = await CacheStore.open();
  });

  tearDown(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  CourseRepository repository(List<MockRoute> routes) {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..interceptors.add(MockApiInterceptor(routes: routes));
    return CourseRepository(
      remote: CourseRemoteDataSource(ApiClient(dio)),
      local: CourseLocalDataSource(cacheStore),
    );
  }

  test('fetches and parses courses', () async {
    final feed = await repository(courseMockRoutes()).fetchCourses();

    expect(feed.isCached, isFalse);
    expect(feed.courses, hasLength(3));
    expect(feed.courses.first.title, 'Python Programming');
    expect(feed.courses.first.instructor, 'John Smith');
    expect(feed.courses.first.lessons, hasLength(4));
    expect(feed.courses.first.completedLessons, 2);
    expect(feed.courses.first.progress, 50);
  });

  test('returns an empty list when there are no courses', () async {
    final feed = await repository(
      courseMockRoutes(scenario: CourseMockScenario.empty),
    ).fetchCourses();

    expect(feed.courses, isEmpty);
  });

  test('surfaces server errors as a ServerFailure', () async {
    await expectLater(
      repository(
        courseMockRoutes(scenario: CourseMockScenario.failure),
      ).fetchCourses(),
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
    final malformed = repository([
      MockRoute(
        method: 'GET',
        pathPattern: CourseEndpoints.courses,
        handler: (_) => const MockResponse(200, [
          {'id': '1', 'title': 'Broken'},
        ]),
      ),
    ]);

    await expectLater(malformed.fetchCourses(), throwsA(isA<ServerFailure>()));
  });

  test('surfaces a NetworkFailure when offline with nothing saved', () async {
    await expectLater(
      repository(
        courseMockRoutes(scenario: CourseMockScenario.offline),
      ).fetchCourses(),
      throwsA(isA<NetworkFailure>()),
    );
  });

  test('serves saved courses when offline', () async {
    await repository(courseMockRoutes()).fetchCourses();

    final feed = await repository(
      courseMockRoutes(scenario: CourseMockScenario.offline),
    ).fetchCourses();

    expect(feed.isCached, isTrue);
    expect(feed.refreshFailure, isA<NetworkFailure>());
    expect(feed.courses.map((c) => c.title), [
      'Python Programming',
      'Generative AI',
      'Full Stack Development',
    ]);
  });

  test('serves saved courses when the server fails', () async {
    await repository(courseMockRoutes()).fetchCourses();

    final feed = await repository(
      courseMockRoutes(scenario: CourseMockScenario.failure),
    ).fetchCourses();

    expect(feed.isCached, isTrue);
    expect(feed.refreshFailure, isA<ServerFailure>());
    expect(feed.courses, hasLength(3));
  });

  test('ignores an unreadable saved entry', () async {
    await cacheStore.write('courses', {'unexpected': true});

    await expectLater(
      repository(
        courseMockRoutes(scenario: CourseMockScenario.offline),
      ).fetchCourses(),
      throwsA(isA<NetworkFailure>()),
    );
  });

  test('completes a lesson on the server and in the saved copy', () async {
    final routes = courseMockRoutes();
    final online = repository(routes);
    await online.fetchCourses();

    await online.completeLesson(1, 3);

    expect(_python(_savedCourses(cacheStore)).progress, 75);
    expect(_python((await online.fetchCourses()).courses).progress, 75);
  });

  test('keeps an offline completion and sends it once back online', () async {
    final routes = courseMockRoutes();
    await repository(routes).fetchCourses();

    final offline = repository(
      courseMockRoutes(scenario: CourseMockScenario.offline),
    );
    await offline.completeLesson(1, 3);

    final offlineFeed = await offline.fetchCourses();
    expect(offlineFeed.isCached, isTrue);
    expect(_python(offlineFeed.courses).progress, 75);

    final onlineFeed = await repository(routes).fetchCourses();
    expect(onlineFeed.isCached, isFalse);
    expect(_python(onlineFeed.courses).progress, 75);
    expect(CourseLocalDataSource(cacheStore).readPendingCompletions(), isEmpty);
  });

  test('drops a queued completion the server rejects', () async {
    final local = CourseLocalDataSource(cacheStore);
    await local.addPendingCompletion((courseId: 1, lessonId: 99));

    final feed = await repository(courseMockRoutes()).fetchCourses();

    expect(feed.isCached, isFalse);
    expect(local.readPendingCompletions(), isEmpty);
  });
}

List<Course> _savedCourses(CacheStore cacheStore) =>
    CourseLocalDataSource(cacheStore).readCourses()!.courses;

Course _python(List<Course> courses) =>
    courses.firstWhere((course) => course.id == 1);
