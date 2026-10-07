import '../../../core/network/api_client.dart';
import 'models/course.dart';

abstract final class CourseEndpoints {
  static const courses = '/courses';
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
}
