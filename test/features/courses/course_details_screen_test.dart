import 'package:course_pilot/core/error/app_failure.dart';
import 'package:course_pilot/core/theme/app_theme.dart';
import 'package:course_pilot/features/courses/data/course_repository.dart';
import 'package:course_pilot/features/courses/data/models/course.dart';
import 'package:course_pilot/features/courses/data/models/course_feed.dart';
import 'package:course_pilot/features/courses/data/models/lesson.dart';
import 'package:course_pilot/features/courses/presentation/course_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _course = Course(
  id: 1,
  title: 'Python Programming',
  instructor: 'John Smith',
  lessons: [
    Lesson(id: 1, title: 'Introduction', isCompleted: true),
    Lesson(id: 2, title: 'Variables & Data Types', isCompleted: true),
    Lesson(id: 3, title: 'Functions', isCompleted: false),
    Lesson(id: 4, title: 'OOP', isCompleted: false),
  ],
);

class _FakeRepository implements CourseRepository {
  _FakeRepository({this.completionFailure});

  final AppFailure? completionFailure;
  final completed = <(int, int)>[];

  @override
  Future<CourseFeed> fetchCourses() async => const CourseFeed([_course]);

  @override
  Future<void> completeLesson(int courseId, int lessonId) async {
    if (completionFailure case final failure?) throw failure;
    completed.add((courseId, lessonId));
  }
}

Widget _details(CourseRepository repository, {int courseId = 1}) =>
    ProviderScope(
      overrides: [courseRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        theme: AppTheme.light,
        home: CourseDetailsScreen(courseId: courseId),
      ),
    );

void main() {
  testWidgets('shows the course, its progress and lesson statuses', (
    tester,
  ) async {
    await tester.pumpWidget(_details(_FakeRepository()));
    await tester.pumpAndSettle();

    expect(find.text('Python Programming'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('2 lessons to go'), findsOneWidget);
    expect(find.text('Completed'), findsNWidgets(2));
    expect(find.text('Pending'), findsNWidgets(2));
    expect(find.text('Mark complete'), findsNWidgets(2));
  });

  testWidgets('completing a lesson updates its status and the progress', (
    tester,
  ) async {
    final repository = _FakeRepository();
    await tester.pumpWidget(_details(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mark complete').first);
    await tester.pumpAndSettle();

    expect(repository.completed, [(1, 3)]);
    expect(find.text('75%'), findsOneWidget);
    expect(find.text('1 lesson to go'), findsOneWidget);
    expect(find.text('Completed'), findsNWidgets(3));
    expect(find.text('Mark complete'), findsOneWidget);
  });

  testWidgets('reverts the lesson when completion fails', (tester) async {
    await tester.pumpWidget(
      _details(_FakeRepository(completionFailure: const UnauthorizedFailure())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mark complete').first);
    await tester.pumpAndSettle();

    expect(find.text('50%'), findsOneWidget);
    expect(find.text('Pending'), findsNWidgets(2));
    expect(find.text(const UnauthorizedFailure().message), findsOneWidget);
  });

  testWidgets('shows a message for an unknown course', (tester) async {
    await tester.pumpWidget(_details(_FakeRepository(), courseId: 42));
    await tester.pumpAndSettle();

    expect(find.text('Course not found'), findsOneWidget);
  });
}
