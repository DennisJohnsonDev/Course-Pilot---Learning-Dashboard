import '../../../core/storage/cache_store.dart';
import 'models/course.dart';

typedef CachedCourses = ({List<Course> courses, DateTime savedAt});

class CourseLocalDataSource {
  CourseLocalDataSource(this._cache);

  static const _key = 'courses';

  final CacheStore _cache;

  Future<void> saveCourses(List<Course> courses) =>
      _cache.write(_key, [for (final course in courses) course.toJson()]);

  CachedCourses? readCourses() {
    final entry = _cache.read(_key);
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
}
