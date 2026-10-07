import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/pressable.dart';
import '../../data/models/course.dart';
import '../courses_provider.dart';

class CourseCard extends StatelessWidget {
  const CourseCard({required this.course, required this.onOpen, super.key});

  final Course course;

  /// Receives the card's on-screen rect, so the page can grow out of it.
  final ValueChanged<Rect> onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    void open() {
      final box = context.findRenderObject()! as RenderBox;
      onOpen(box.localToGlobal(Offset.zero) & box.size);
    }

    return Semantics(
      button: true,
      label:
          '${course.title}, ${course.instructor}, '
          '${course.progress}% complete, ${_lessonsLabel(course.lessons.length)}',
      excludeSemantics: true,
      onTap: open,
      child: Pressable(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: open,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.screenPadding,
                AppSpacing.screenPadding,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(course.instructor, style: theme.textTheme.bodySmall),
                  const SizedBox(height: AppSpacing.screenPadding),
                  _ProgressRow(progress: course.progress),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.book,
                        size: 15,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _lessonsLabel(course.lessons.length),
                        style: theme.textTheme.bodySmall,
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: open,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          shape: const StadiumBorder(),
                          elevation: 0,
                          backgroundColor: colors.primary.withValues(
                            alpha: 0.1,
                          ),
                          foregroundColor: colors.primary,
                          textStyle: theme.textTheme.labelLarge?.copyWith(
                            fontSize: 14,
                          ),
                        ),
                        child: const Text('Continue'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The card for [courseId] as it looks right now, for the open transition.
class LiveCourseCard extends ConsumerWidget {
  const LiveCourseCard({required this.courseId, super.key});

  final int courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final course = ref.watch(courseProvider(courseId)).value;
    if (course == null) return const SizedBox.shrink();
    return CourseCard(course: course, onOpen: (_) {});
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.progress});

  final int progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(end: progress.clamp(0, 100) / 100),
      duration: AppMotion.slow * 2,
      curve: AppMotion.easeInOut,
      builder: (context, value, _) => Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(value: value, minHeight: 6),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            width: 48,
            child: Text(
              '${(value * 100).round()}%',
              textAlign: TextAlign.end,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _lessonsLabel(int lessons) =>
    lessons == 1 ? '1 lesson' : '$lessons lessons';
