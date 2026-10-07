import '../../../core/network/mock/mock_route.dart';
import 'course_remote_data_source.dart';

enum CourseMockScenario { success, empty, failure, offline }

/// Change the scenario in `main.dart` to preview empty and error states.
List<MockRoute> courseMockRoutes([
  CourseMockScenario scenario = CourseMockScenario.success,
]) => [
  MockRoute(
    method: 'GET',
    pathPattern: CourseEndpoints.courses,
    handler: (_) => switch (scenario) {
      CourseMockScenario.success => const MockResponse(200, _courses),
      CourseMockScenario.empty => const MockResponse(200, <Object?>[]),
      CourseMockScenario.failure => const MockResponse(500, {
        'message': 'Courses are unavailable right now.',
      }),
      CourseMockScenario.offline => const MockResponse.offline(),
    },
  ),
];

const _courses = [
  {
    'id': 1,
    'title': 'Python Programming',
    'instructor': 'John Smith',
    'progress': 65,
    'lessons': 20,
  },
  {
    'id': 2,
    'title': 'Generative AI',
    'instructor': 'Sarah Williams',
    'progress': 40,
    'lessons': 16,
  },
  {
    'id': 3,
    'title': 'Full Stack Development',
    'instructor': 'David Brown',
    'progress': 25,
    'lessons': 28,
  },
];
