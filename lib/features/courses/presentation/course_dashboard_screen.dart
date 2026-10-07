import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/entrance.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/models/course.dart';
import '../data/models/course_feed.dart';
import 'courses_provider.dart';
import 'widgets/course_card.dart';
import 'widgets/course_list_skeleton.dart';
import 'widgets/state_message.dart';
import 'widgets/offline_banner.dart';

class CourseDashboardScreen extends ConsumerWidget {
  const CourseDashboardScreen({super.key});

  static const _maxContentWidth = 640.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courses = ref.watch(coursesProvider);
    final theme = Theme.of(context);

    ref.listen(coursesProvider, (previous, next) {
      final isRefresh =
          previous is AsyncLoading<CourseFeed> && previous.hasValue;
      final failure = switch (next) {
        AsyncError(:final error, hasValue: true) => error,
        AsyncData(value: CourseFeed(:final refreshFailure?)) when isRefresh =>
          refreshFailure,
        _ => null,
      };
      if (failure != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(failureMessage(failure))));
      }
    });

    final feed = courses.value;
    final content = switch (courses) {
      AsyncValue(value: CourseFeed(:final courses)) when courses.isEmpty =>
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Entrance(
            child: StateMessage(
              icon: CupertinoIcons.book,
              title: 'No courses yet',
              message: 'Courses you enroll in will show up here.',
            ),
          ),
        ),
      AsyncValue(value: CourseFeed(:final courses)) => _CourseList(courses),
      AsyncValue(isLoading: true) => const SliverToBoxAdapter(
        child: CourseListSkeleton(),
      ),
      AsyncValue(:final error?) => SliverFillRemaining(
        hasScrollBody: false,
        child: Entrance(
          child: StateMessage(
            icon: error is NetworkFailure
                ? CupertinoIcons.wifi_slash
                : CupertinoIcons.exclamationmark_circle,
            title: error is NetworkFailure
                ? "You're offline"
                : "Couldn't load courses",
            message: failureMessage(error),
            actionLabel: 'Try Again',
            onAction: () => ref.invalidate(coursesProvider),
          ),
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
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            sliver: SliverConstrainedCrossAxis(
              maxExtent: _maxContentWidth,
              sliver: SliverToBoxAdapter(
                child: _AnimatedBanner(
                  child: switch (feed) {
                    CourseFeed(:final savedAt?, :final refreshFailure?) =>
                      Padding(
                        padding: const EdgeInsets.only(
                          top: AppSpacing.sm,
                          bottom: AppSpacing.xs,
                        ),
                        child: OfflineBanner(
                          failure: refreshFailure,
                          savedAt: savedAt,
                        ),
                      ),
                    _ => null,
                  },
                ),
              ),
            ),
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

class _AnimatedBanner extends StatelessWidget {
  const _AnimatedBanner({required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: child ?? const SizedBox(width: double.infinity),
      ),
    );
  }
}

class _CourseList extends StatelessWidget {
  const _CourseList(this.courses);

  final List<Course> courses;

  @override
  Widget build(BuildContext context) {
    return EntranceScope(
      child: SliverList.separated(
        itemCount: courses.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final course = courses[index];
          return Entrance(
            index: index,
            child: CourseCard(
              course: course,
              onOpen: () => context.push(AppRoutes.courseDetails(course.id)),
            ),
          );
        },
      ),
    );
  }
}
