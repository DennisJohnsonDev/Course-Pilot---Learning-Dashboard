import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/network/api_client.dart';
import 'course_remote_data_source.dart';
import 'models/course.dart';

final courseRepositoryProvider = Provider<CourseRepository>(
  (ref) => CourseRepository(
    remote: CourseRemoteDataSource(ref.watch(apiClientProvider)),
  ),
);

class CourseRepository {
  CourseRepository({required this._remote});

  final CourseRemoteDataSource _remote;

  /// Returns an empty list when there are no courses; throws [AppFailure]
  /// on any failure.
  Future<List<Course>> fetchCourses() async {
    try {
      return await _remote.fetchCourses();
    } on AppFailure {
      rethrow;
    } on TypeError {
      throw const ServerFailure(
        message: 'We received unexpected course data. Please try again later.',
      );
    }
  }
}
