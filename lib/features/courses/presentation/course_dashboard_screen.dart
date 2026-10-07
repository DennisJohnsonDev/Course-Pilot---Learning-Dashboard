import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/models/course.dart';
import 'courses_provider.dart';
import 'widgets/course_card.dart';
import 'widgets/course_list_skeleton.dart';
import 'widgets/dashboard_message.dart';

class CourseDashboardScreen extends ConsumerWidget {
  const CourseDashboardScreen({super.key});

  static const _maxContentWidth = 640.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courses = ref.watch(coursesProvider);
    final theme = Theme.of(context);

    ref.listen(coursesProvider, (_, next) {
      if (next case AsyncError(:final error, hasValue: true)) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(_messageFor(error))));
      }
    });

    final content = switch (courses) {
      AsyncValue(value: final courses?) when courses.isEmpty =>
        const SliverFillRemaining(
          hasScrollBody: false,
          child: DashboardMessage(
            icon: CupertinoIcons.book,
            title: 'No courses yet',
            message: 'Courses you enroll in will show up here.',
          ),
        ),
      AsyncValue(value: final courses?) => _CourseList(courses),
      AsyncValue(isLoading: true) => const SliverToBoxAdapter(
        child: CourseListSkeleton(),
      ),
      AsyncValue(:final error?) => SliverFillRemaining(
        hasScrollBody: false,
        child: DashboardMessage(
          icon: CupertinoIcons.exclamationmark_circle,
          title: "Couldn't load courses",
          message: _messageFor(error),
          actionLabel: 'Try Again',
          onAction: () => ref.invalidate(coursesProvider),
        ),
      ),
      _ => const SliverToBoxAdapter(child: CourseListSkeleton()),
    };

    return Scaffold(
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('My Courses'),
            backgroundColor: theme.scaffoldBackgroundColor.withValues(
              alpha: 0.9,
            ),
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outlineVariant,
                width: 0,
              ),
            ),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size.square(44),
              onPressed: () =>
                  ref.read(sessionControllerProvider.notifier).signOut(),
              child: Text(
                'Sign Out',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          if (courses.hasValue)
            CupertinoSliverRefreshControl(
              onRefresh: () async {
                try {
                  ref.invalidate(coursesProvider);
                  await ref.read(coursesProvider.future);
                } on Object {
                  // Reported by the snackbar listener above.
                }
              },
            ),
          SliverSafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            sliver: SliverConstrainedCrossAxis(
              maxExtent: _maxContentWidth,
              sliver: content,
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseList extends StatelessWidget {
  const _CourseList(this.courses);

  final List<Course> courses;

  @override
  Widget build(BuildContext context) {
    return SliverList.separated(
      itemCount: courses.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final course = courses[index];
        return CourseCard(
          course: course,
          onOpen: () => context.push(AppRoutes.courseDetails(course.id)),
        );
      },
    );
  }
}

String _messageFor(Object error) =>
    error is AppFailure ? error.message : const UnknownFailure().message;
