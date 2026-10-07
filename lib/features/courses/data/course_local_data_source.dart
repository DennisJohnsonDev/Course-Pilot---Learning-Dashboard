import '../../../core/storage/cache_store.dart';
import 'models/course.dart';

typedef CachedCourses = ({List<Course> courses, DateTime savedAt});
typedef LessonCompletion = ({int courseId, int lessonId});

class CourseLocalDataSource {
  CourseLocalDataSource(this._cache);

  static const _coursesKey = 'courses';
  static const _pendingKey = 'pending_lesson_completions';

  final CacheStore _cache;

  Future<void> saveCourses(List<Course> courses) => _cache.write(_coursesKey, [
    for (final course in courses) course.toJson(),
  ]);

  CachedCourses? readCourses() {
    final entry = _cache.read(_coursesKey);
    if (entry == null) return null;

    try {
      final courses = (entry.data! as List<Object?>)
          .cast<Map<String, Object?>>()
          .map(Course.fromJson)
          .toList(growable: false);
      return (courses: courses, savedAt: entry.savedAt);
    } on TypeError {
      return null;
    }
  }

  Future<void> markLessonCompleted(int courseId, int lessonId) async {
    final cached = readCourses();
    if (cached == null) return;

    await saveCourses([
      for (final course in cached.courses)
        course.id == courseId ? course.withLessonCompleted(lessonId) : course,
    ]);
  }

  List<LessonCompletion> readPendingCompletions() {
    final data = _cache.read(_pendingKey)?.data;
    if (data is! List<Object?>) return const [];

    return [
      for (final item in data)
        if (item case {
          'courseId': final int courseId,
          'lessonId': final int lessonId,
        })
          (courseId: courseId, lessonId: lessonId),
    ];
  }

  Future<void> addPendingCompletion(LessonCompletion completion) =>
      _savePending({...readPendingCompletions(), completion});

  Future<void> removePendingCompletion(LessonCompletion completion) =>
      _savePending(readPendingCompletions().toSet()..remove(completion));

  Future<void> _savePending(Set<LessonCompletion> completions) =>
      _cache.write(_pendingKey, [
        for (final c in completions)
          {'courseId': c.courseId, 'lessonId': c.lessonId},
      ]);
}
