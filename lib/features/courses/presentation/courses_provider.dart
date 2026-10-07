import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/course_repository.dart';
import '../data/models/course.dart';
import '../data/models/course_feed.dart';

final coursesProvider =
    AsyncNotifierProvider.autoDispose<CoursesNotifier, CourseFeed>(
      CoursesNotifier.new,
      // Failures wait for the user to retry instead of retrying in the background.
      retry: (_, _) => null,
    );

final courseProvider = Provider.autoDispose.family<AsyncValue<Course?>, int>(
  (ref, id) => ref
      .watch(coursesProvider)
      .whenData(
        (feed) => feed.courses.where((course) => course.id == id).firstOrNull,
      ),
);

class CoursesNotifier extends AsyncNotifier<CourseFeed> {
  @override
  Future<CourseFeed> build() =>
      ref.watch(courseRepositoryProvider).fetchCourses();

  Future<void> completeLesson(int courseId, int lessonId) async {
    final feed = state.value;
    final course = feed?.courses.where((c) => c.id == courseId).firstOrNull;
    if (feed == null || course == null) return;

    state = AsyncData(feed.replacing(course.withLessonCompleted(lessonId)));
    try {
      await ref
          .read(courseRepositoryProvider)
          .completeLesson(courseId, lessonId);
    } on Object {
      if (ref.mounted) state = AsyncData(feed);
      rethrow;
    }
  }
}
