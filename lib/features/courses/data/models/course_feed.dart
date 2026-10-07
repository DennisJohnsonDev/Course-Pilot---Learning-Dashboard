import '../../../../core/error/app_failure.dart';
import 'course.dart';

class CourseFeed {
  const CourseFeed(this.courses) : savedAt = null, refreshFailure = null;

  const CourseFeed.cached(
    this.courses, {
    required DateTime this.savedAt,
    required AppFailure this.refreshFailure,
  });

  final List<Course> courses;

  /// Set only when fresh data couldn't be fetched and saved courses are shown.
  final DateTime? savedAt;
  final AppFailure? refreshFailure;

  bool get isCached => savedAt != null;
}
