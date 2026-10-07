import 'package:hive_ce/hive.dart';

import '../../../core/network/mock/mock_route.dart';
import 'course_remote_data_source.dart';

enum CourseMockScenario { success, empty, failure, offline }

const courseMockStorageBox = 'mock_course_completions';

/// Change the scenario in `main.dart` to preview empty, error and offline
/// states. [storage] plays the backend database so completions survive
/// restarts; without it they live in memory.
List<MockRoute> courseMockRoutes({
  CourseMockScenario scenario = CourseMockScenario.success,
  Box<bool>? storage,
}) {
  final completed = <String>{...?storage?.keys.cast<String>()};

  MockResponse? unavailable() => switch (scenario) {
    CourseMockScenario.failure => const MockResponse(500, {
      'message': 'Courses are unavailable right now.',
    }),
    CourseMockScenario.offline => const MockResponse.offline(),
    _ => null,
  };

  List<Map<String, Object?>> courses() => [
    for (final course in _courses)
      {
        ...course,
        'lessons': [
          for (final lesson in course['lessons']! as List<Map<String, Object?>>)
            {
              ...lesson,
              'isCompleted':
                  lesson['isCompleted'] == true ||
                  completed.contains(_key(course['id'], lesson['id'])),
            },
        ],
      },
  ];

  return [
    MockRoute(
      method: 'GET',
      pathPattern: CourseEndpoints.courses,
      handler: (_) =>
          unavailable() ??
          switch (scenario) {
            CourseMockScenario.empty => const MockResponse(200, <Object?>[]),
            _ => MockResponse(200, courses()),
          },
    ),
    MockRoute(
      method: 'POST',
      pathPattern: CourseEndpoints.completeLessonPattern,
      handler: (request) {
        if (unavailable() case final response?) return response;

        final courseId = int.tryParse(request.pathParameters['courseId']!);
        final lessonId = int.tryParse(request.pathParameters['lessonId']!);
        final exists = _courses.any(
          (course) =>
              course['id'] == courseId &&
              (course['lessons']! as List<Map<String, Object?>>).any(
                (lesson) => lesson['id'] == lessonId,
              ),
        );
        if (!exists) {
          return const MockResponse(404, {'message': 'Lesson not found.'});
        }

        final key = _key(courseId, lessonId);
        completed.add(key);
        storage?.put(key, true);
        return const MockResponse(204);
      },
    ),
  ];
}

String _key(Object? courseId, Object? lessonId) => '$courseId/$lessonId';

const _courses = [
  {
    'id': 1,
    'title': 'Python Programming',
    'instructor': 'John Smith',
    'lessons': [
      {'id': 1, 'title': 'Introduction', 'isCompleted': true},
      {'id': 2, 'title': 'Variables & Data Types', 'isCompleted': true},
      {'id': 3, 'title': 'Functions', 'isCompleted': false},
      {'id': 4, 'title': 'OOP', 'isCompleted': false},
    ],
  },
  {
    'id': 2,
    'title': 'Generative AI',
    'instructor': 'Sarah Williams',
    'lessons': [
      {'id': 1, 'title': 'What Is Generative AI', 'isCompleted': true},
      {'id': 2, 'title': 'Large Language Models', 'isCompleted': true},
      {'id': 3, 'title': 'Prompt Engineering', 'isCompleted': false},
      {
        'id': 4,
        'title': 'Retrieval-Augmented Generation',
        'isCompleted': false,
      },
      {'id': 5, 'title': 'Responsible AI', 'isCompleted': false},
    ],
  },
  {
    'id': 3,
    'title': 'Full Stack Development',
    'instructor': 'David Brown',
    'lessons': [
      {'id': 1, 'title': 'How the Web Works', 'isCompleted': true},
      {'id': 2, 'title': 'Building Interfaces', 'isCompleted': false},
      {'id': 3, 'title': 'REST APIs', 'isCompleted': false},
      {'id': 4, 'title': 'Databases', 'isCompleted': false},
    ],
  },
  {
    'id': 4,
    'title': 'UI/UX Design Fundamentals',
    'instructor': 'Emily Davis',
    'lessons': [
      {'id': 1, 'title': 'Design Thinking', 'isCompleted': true},
      {'id': 2, 'title': 'Typography', 'isCompleted': true},
      {'id': 3, 'title': 'Color Theory', 'isCompleted': true},
      {'id': 4, 'title': 'Prototyping', 'isCompleted': true},
    ],
  },
  {
    'id': 5,
    'title': 'Data Science with Pandas',
    'instructor': 'Michael Chen',
    'lessons': [
      {'id': 1, 'title': 'DataFrames', 'isCompleted': true},
      {'id': 2, 'title': 'Cleaning Data', 'isCompleted': false},
      {'id': 3, 'title': 'Grouping & Aggregation', 'isCompleted': false},
      {'id': 4, 'title': 'Visualization', 'isCompleted': false},
      {'id': 5, 'title': 'Case Study', 'isCompleted': false},
    ],
  },
  {
    'id': 6,
    'title': 'Flutter & Dart',
    'instructor': 'Priya Patel',
    'lessons': [
      {'id': 1, 'title': 'Dart Basics', 'isCompleted': true},
      {'id': 2, 'title': 'Widgets', 'isCompleted': true},
      {'id': 3, 'title': 'State Management', 'isCompleted': true},
      {'id': 4, 'title': 'Navigation', 'isCompleted': false},
      {'id': 5, 'title': 'Testing', 'isCompleted': false},
    ],
  },
  {
    'id': 7,
    'title': 'Cloud Computing Essentials',
    'instructor': 'Robert Taylor',
    'lessons': [
      {'id': 1, 'title': 'Cloud Models', 'isCompleted': false},
      {'id': 2, 'title': 'Compute & Storage', 'isCompleted': false},
      {'id': 3, 'title': 'Networking', 'isCompleted': false},
      {'id': 4, 'title': 'Security', 'isCompleted': false},
    ],
  },
  {
    'id': 8,
    'title': 'Machine Learning Foundations',
    'instructor': 'Laura Martinez',
    'lessons': [
      {'id': 1, 'title': 'What Is Machine Learning', 'isCompleted': true},
      {'id': 2, 'title': 'Regression', 'isCompleted': false},
      {'id': 3, 'title': 'Classification', 'isCompleted': false},
      {'id': 4, 'title': 'Model Evaluation', 'isCompleted': false},
      {'id': 5, 'title': 'Neural Networks', 'isCompleted': false},
      {'id': 6, 'title': 'Deploying Models', 'isCompleted': false},
    ],
  },
  {
    'id': 9,
    'title': 'Cybersecurity Basics',
    'instructor': 'James Wilson',
    'lessons': [
      {'id': 1, 'title': 'Threat Landscape', 'isCompleted': true},
      {'id': 2, 'title': 'Passwords & Authentication', 'isCompleted': true},
      {'id': 3, 'title': 'Network Security', 'isCompleted': false},
      {'id': 4, 'title': 'Secure Coding', 'isCompleted': false},
    ],
  },
  {
    'id': 10,
    'title': 'Product Management',
    'instructor': 'Olivia Anderson',
    'lessons': [
      {'id': 1, 'title': 'Product Discovery', 'isCompleted': true},
      {'id': 2, 'title': 'Roadmaps', 'isCompleted': true},
      {'id': 3, 'title': 'Metrics That Matter', 'isCompleted': true},
      {'id': 4, 'title': 'Working with Stakeholders', 'isCompleted': false},
    ],
  },
];
