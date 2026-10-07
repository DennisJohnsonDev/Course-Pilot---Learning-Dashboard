import 'package:course_pilot/features/courses/data/models/course.dart';
import 'package:course_pilot/features/courses/data/models/lesson.dart';
import 'package:flutter_test/flutter_test.dart';

Course _course(List<bool> completed) => Course(
  id: 1,
  title: 'Python Programming',
  instructor: 'John Smith',
  lessons: [
    for (final (index, isCompleted) in completed.indexed)
      Lesson(id: index + 1, title: 'Lesson $index', isCompleted: isCompleted),
  ],
);

void main() {
  test('derives progress from completed lessons', () {
    expect(_course([true, true, false, false]).progress, 50);
    expect(_course([true, false, false]).progress, 33);
    expect(_course([true, true, false]).progress, 67);
    expect(_course([true, true]).progress, 100);
  });

  test('reports zero progress for a course without lessons', () {
    expect(_course([]).progress, 0);
  });

  test('completing a lesson returns an updated copy', () {
    final course = _course([true, false, false]);

    final updated = course.withLessonCompleted(2);

    expect(updated.completedLessons, 2);
    expect(updated.progress, 67);
    expect(updated.lessons[1].isCompleted, isTrue);
    expect(course.completedLessons, 1);
  });

  test('round-trips through JSON', () {
    final course = _course([true, false]);

    final decoded = Course.fromJson(course.toJson());

    expect(decoded.toJson(), course.toJson());
  });
}
