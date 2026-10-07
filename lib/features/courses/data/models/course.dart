import 'lesson.dart';

class Course {
  const Course({
    required this.id,
    required this.title,
    required this.instructor,
    required this.lessons,
  });

  factory Course.fromJson(Map<String, Object?> json) => Course(
    id: json['id']! as int,
    title: json['title']! as String,
    instructor: json['instructor']! as String,
    lessons: (json['lessons']! as List<Object?>)
        .cast<Map<String, Object?>>()
        .map(Lesson.fromJson)
        .toList(growable: false),
  );

  final int id;
  final String title;
  final String instructor;
  final List<Lesson> lessons;

  int get completedLessons => lessons.where((l) => l.isCompleted).length;

  /// Percentage from 0 to 100, derived from completed lessons.
  int get progress =>
      lessons.isEmpty ? 0 : (completedLessons * 100 / lessons.length).round();

  Course withLessonCompleted(int lessonId) => Course(
    id: id,
    title: title,
    instructor: instructor,
    lessons: [
      for (final lesson in lessons)
        lesson.id == lessonId ? lesson.completed() : lesson,
    ],
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'instructor': instructor,
    'lessons': [for (final lesson in lessons) lesson.toJson()],
  };
}
