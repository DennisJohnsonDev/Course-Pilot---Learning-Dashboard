import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/models/course.dart';
import '../data/models/lesson.dart';
import 'courses_provider.dart';
import 'widgets/dashboard_message.dart';
import 'widgets/lesson_tile.dart';
import 'widgets/progress_summary.dart';

class CourseDetailsScreen extends ConsumerWidget {
  const CourseDetailsScreen({required this.courseId, super.key});

  final int courseId;

  static const _maxContentWidth = 640.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final course = ref.watch(courseProvider(courseId));

    final content = switch (course) {
      AsyncValue(value: final course?) => _CourseContent(
        course: course,
        onComplete: (lesson) => _complete(context, ref, lesson),
      ),
      AsyncValue(hasValue: true) => const SliverFillRemaining(
        hasScrollBody: false,
        child: DashboardMessage(
          icon: CupertinoIcons.book,
          title: 'Course not found',
          message: 'This course is no longer available.',
        ),
      ),
      AsyncValue(:final error?) when !course.isLoading => SliverFillRemaining(
        hasScrollBody: false,
        child: DashboardMessage(
          icon: CupertinoIcons.exclamationmark_circle,
          title: "Couldn't load course",
          message: _messageFor(error),
          actionLabel: 'Try Again',
          onAction: () => ref.invalidate(coursesProvider),
        ),
      ),
      _ => const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator.adaptive()),
      ),
    };

    return Scaffold(
      appBar: AppBar(),
      body: CustomScrollView(
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
    );
  }

  Future<void> _complete(
    BuildContext context,
    WidgetRef ref,
    Lesson lesson,
  ) async {
    unawaited(HapticFeedback.lightImpact());
    try {
      await ref
          .read(coursesProvider.notifier)
          .completeLesson(courseId, lesson.id);
    } on Object catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(_messageFor(error))));
    }
  }
}

class _CourseContent extends StatelessWidget {
  const _CourseContent({required this.course, required this.onComplete});

  final Course course;
  final ValueChanged<Lesson> onComplete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SliverList.list(
      children: [
        Text(course.title, style: theme.textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          course.instructor,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        ProgressSummary(course: course),
        const SizedBox(height: AppSpacing.xxl),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('Lessons', style: theme.textTheme.titleMedium),
              const Spacer(),
              Text(
                '${course.completedLessons} of ${course.lessons.length} '
                'completed',
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
                  onComplete: () => onComplete(lesson),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

String _messageFor(Object error) =>
    error is AppFailure ? error.message : const UnknownFailure().message;
