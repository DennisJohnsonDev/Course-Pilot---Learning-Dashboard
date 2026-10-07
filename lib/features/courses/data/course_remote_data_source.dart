import '../../../core/network/api_client.dart';
import 'models/course.dart';

abstract final class CourseEndpoints {
  static const courses = '/courses';
  static const completeLessonPattern =
      '/courses/:courseId/lessons/:lessonId/complete';

  static String completeLesson(int courseId, int lessonId) =>
      '/courses/$courseId/lessons/$lessonId/complete';
}

class CourseRemoteDataSource {
  CourseRemoteDataSource(this._client);

  final ApiClient _client;

  Future<List<Course>> fetchCourses() async {
    final json = await _client.get<List<Object?>>(CourseEndpoints.courses);
    return json
        .cast<Map<String, Object?>>()
        .map(Course.fromJson)
        .toList(growable: false);
  }

  Future<void> completeLesson(int courseId, int lessonId) =>
      _client.post<Object?>(CourseEndpoints.completeLesson(courseId, lessonId));
}
