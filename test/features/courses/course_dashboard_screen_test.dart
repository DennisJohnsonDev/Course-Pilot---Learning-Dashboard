import 'dart:async';

import 'package:course_pilot/core/error/app_failure.dart';
import 'package:course_pilot/core/theme/app_theme.dart';
import 'package:course_pilot/features/courses/data/models/course.dart';
import 'package:course_pilot/features/courses/presentation/course_dashboard_screen.dart';
import 'package:course_pilot/features/courses/presentation/courses_provider.dart';
import 'package:course_pilot/features/courses/presentation/widgets/course_list_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _course = Course(
  id: 1,
  title: 'Python Programming',
  instructor: 'John Smith',
  progress: 65,
  lessons: 20,
);

Widget _dashboard(Future<List<Course>> Function() load) => ProviderScope(
  overrides: [coursesProvider.overrideWith((ref) => load())],
  child: MaterialApp(
    theme: AppTheme.light,
    home: const CourseDashboardScreen(),
  ),
);

void main() {
  testWidgets('shows a skeleton while loading', (tester) async {
    await tester.pumpWidget(_dashboard(() => Completer<List<Course>>().future));
    await tester.pump();

    expect(find.byType(CourseListSkeleton), findsOneWidget);
  });

  testWidgets('lists courses with progress, lessons and Continue', (
    tester,
  ) async {
    await tester.pumpWidget(_dashboard(() async => [_course]));
    await tester.pumpAndSettle();

    expect(find.text('Python Programming'), findsOneWidget);
    expect(find.text('John Smith'), findsOneWidget);
    expect(find.text('65%'), findsOneWidget);
    expect(find.text('20 lessons'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('shows the empty state', (tester) async {
    await tester.pumpWidget(_dashboard(() async => []));
    await tester.pumpAndSettle();

    expect(find.text('No courses yet'), findsOneWidget);
  });

  testWidgets('shows the failure and recovers on Try Again', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      _dashboard(() async {
        attempts++;
        if (attempts == 1) throw const ServerFailure(message: 'Server down.');
        return [_course];
      }),
    );
    await tester.pumpAndSettle();

    expect(find.text("Couldn't load courses"), findsOneWidget);
    expect(find.text('Server down.'), findsOneWidget);

    await tester.tap(find.text('Try Again'));
    await tester.pumpAndSettle();

    expect(find.text('Python Programming'), findsOneWidget);
  });
}
