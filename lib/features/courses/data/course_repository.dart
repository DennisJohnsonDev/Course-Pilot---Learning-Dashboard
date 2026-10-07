import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/cache_store.dart';
import 'course_local_data_source.dart';
import 'course_remote_data_source.dart';
import 'models/course.dart';
import 'models/course_feed.dart';

final courseRepositoryProvider = Provider<CourseRepository>(
  (ref) => CourseRepository(
    remote: CourseRemoteDataSource(ref.watch(apiClientProvider)),
    local: CourseLocalDataSource(ref.watch(cacheStoreProvider)),
  ),
);

class CourseRepository {
  CourseRepository({required this._remote, required this._local});

  final CourseRemoteDataSource _remote;
  final CourseLocalDataSource _local;

  /// Falls back to the last saved courses when fetching fails; throws
  /// [AppFailure] only when nothing usable is saved.
  Future<CourseFeed> fetchCourses() async {
    try {
      await _sendPendingCompletions();
      final courses = await _fetchRemote();
      await _save(courses);
      return CourseFeed(courses);
    } on UnauthorizedFailure {
      rethrow;
    } on AppFailure catch (failure) {
      final cached = _local.readCourses();
      if (cached == null) rethrow;
      return CourseFeed.cached(
        cached.courses,
        savedAt: cached.savedAt,
        refreshFailure: failure,
      );
    }
  }

  /// Saves the completion locally and queues it for the next fetch when the
  /// server can't be reached.
  Future<void> completeLesson(int courseId, int lessonId) async {
    try {
      await _remote.completeLesson(courseId, lessonId);
    } on UnauthorizedFailure {
      rethrow;
    } on AppFailure {
      await _local.addPendingCompletion((
        courseId: courseId,
        lessonId: lessonId,
      ));
    }

    try {
      await _local.markLessonCompleted(courseId, lessonId);
    } on Object {
      // The next successful fetch rewrites the cache.
    }
  }

  Future<void> _sendPendingCompletions() async {
    for (final completion in _local.readPendingCompletions()) {
      try {
        await _remote.completeLesson(completion.courseId, completion.lessonId);
      } on ServerFailure catch (failure) {
        final isRejected = (failure.statusCode ?? 500) < 500;
        if (!isRejected) rethrow;
      }
      await _local.removePendingCompletion(completion);
    }
  }

  Future<List<Course>> _fetchRemote() async {
    try {
      return await _remote.fetchCourses();
    } on TypeError {
      throw const ServerFailure(
        message: 'We received unexpected course data. Please try again later.',
      );
    }
  }

  Future<void> _save(List<Course> courses) async {
    try {
      await _local.saveCourses(courses);
    } on Object {
      // A failed cache write must not hide fresh data.
    }
  }
}
