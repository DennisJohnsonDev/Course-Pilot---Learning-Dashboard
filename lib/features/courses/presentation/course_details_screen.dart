import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/entrance.dart';
import '../data/models/course.dart';
import '../data/models/lesson.dart';
import 'courses_provider.dart';
import 'widgets/lesson_tile.dart';
import 'widgets/progress_summary.dart';
import 'widgets/state_message.dart';

class CourseDetailsScreen extends ConsumerStatefulWidget {
  const CourseDetailsScreen({required this.courseId, super.key});

  final int courseId;

  @override
  ConsumerState<CourseDetailsScreen> createState() =>
      _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends ConsumerState<CourseDetailsScreen> {
  static const _maxContentWidth = 640.0;
  static const _titleRevealOffset = 48.0;

  final _isTitleVisible = ValueNotifier(false);

  @override
  void dispose() {
    _isTitleVisible.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth == 0) {
      _isTitleVisible.value = notification.metrics.pixels > _titleRevealOffset;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final course = ref.watch(courseProvider(widget.courseId));

    final content = switch (course) {
      AsyncValue(value: final course?) => _CourseContent(
        course: course,
        onComplete: _complete,
      ),
      AsyncValue(hasValue: true) => const SliverFillRemaining(
        hasScrollBody: false,
        child: Entrance(
          child: StateMessage(
            icon: CupertinoIcons.book,
            title: 'Course not found',
            message: 'This course is no longer available.',
          ),
        ),
      ),
      AsyncValue(:final error?) when !course.isLoading => SliverFillRemaining(
        hasScrollBody: false,
        child: Entrance(
          child: StateMessage(
            icon: CupertinoIcons.exclamationmark_circle,
            title: "Couldn't load course",
            message: failureMessage(error),
            actionLabel: 'Try Again',
            onAction: () => ref.invalidate(coursesProvider),
          ),
        ),
      ),
      _ => const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator.adaptive()),
      ),
    };

    return Scaffold(
      appBar: AppBar(
        title: ValueListenableBuilder(
          valueListenable: _isTitleVisible,
          builder: (context, isVisible, child) => AnimatedOpacity(
            opacity: isVisible ? 1 : 0,
            duration: AppMotion.fast,
            curve: AppMotion.easeOut,
            child: AnimatedSlide(
              offset: isVisible ? Offset.zero : const Offset(0, 0.3),
              duration: AppMotion.normal,
              curve: AppMotion.easeOut,
              child: child,
            ),
          ),
          child: Text(course.value?.title ?? ''),
        ),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: CustomScrollView(
          slivers: [
            SliverSafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              sliver: SliverConstrainedCrossAxis(
                maxExtent: _maxContentWidth,
                sliver: content,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _complete(Course course, Lesson lesson) async {
    final finishesCourse = course.completedLessons == course.lessons.length - 1;
    unawaited(
      finishesCourse
          ? HapticFeedback.mediumImpact()
          : HapticFeedback.lightImpact(),
    );

    try {
      await ref
          .read(coursesProvider.notifier)
          .completeLesson(course.id, lesson.id);
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(failureMessage(error))));
    }
  }
}

class _CourseContent extends StatelessWidget {
  const _CourseContent({required this.course, required this.onComplete});

  final Course course;
  final void Function(Course course, Lesson lesson) onComplete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return EntranceScope(
      child: SliverList.list(
        children: [
          Entrance(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course.title, style: theme.textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  course.instructor,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Entrance(index: 1, child: ProgressSummary(course: course)),
          const SizedBox(height: AppSpacing.xxl),
          Entrance(
            index: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('Lessons', style: theme.textTheme.titleMedium),
                      const Spacer(),
                      Text(
                        '${course.completedLessons} of '
                        '${course.lessons.length} completed',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Column(
                    children: [
                      for (final (index, lesson) in course.lessons.indexed) ...[
                        if (index > 0) const Divider(indent: 58),
                        LessonTile(
                          number: index + 1,
                          lesson: lesson,
                          onComplete: () => onComplete(course, lesson),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
