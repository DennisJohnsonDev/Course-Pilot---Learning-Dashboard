import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/course_repository.dart';
import '../data/models/course.dart';

final coursesProvider = FutureProvider.autoDispose<List<Course>>(
  (ref) => ref.watch(courseRepositoryProvider).fetchCourses(),
  // Failures wait for the user to retry instead of retrying in the background.
  retry: (_, _) => null,
);
