import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../data/models/lesson.dart';

class LessonTile extends StatelessWidget {
  const LessonTile({
    required this.number,
    required this.lesson,
    required this.onComplete,
    super.key,
  });

  final int number;
  final Lesson lesson;
  final VoidCallback onComplete;

  static const _duration = Duration(milliseconds: 260);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isCompleted = lesson.isCompleted;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 14,
      ),
      child: Row(
        children: [
          Expanded(
            child: MergeSemantics(
              child: Row(
                children: [
                  _StatusMark(number: number, isCompleted: isCompleted),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson.title,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        AnimatedDefaultTextStyle(
                          duration: _duration,
                          style: theme.textTheme.bodySmall!.copyWith(
                            color: isCompleted
                                ? colors.primary
                                : colors.onSurfaceVariant,
                          ),
                          child: Text(isCompleted ? 'Completed' : 'Pending'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: _duration,
            curve: Curves.easeOutCubic,
            child: AnimatedSwitcher(
              duration: _duration,
              child: isCompleted
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.md),
                      child: FilledButton(
                        onPressed: onComplete,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          shape: const StadiumBorder(),
                          backgroundColor: colors.primary.withValues(
                            alpha: 0.1,
                          ),
                          foregroundColor: colors.primary,
                          textStyle: theme.textTheme.labelLarge?.copyWith(
                            fontSize: 14,
                          ),
                        ),
                        child: Text(
                          'Mark complete',
                          semanticsLabel: 'Mark ${lesson.title} complete',
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusMark extends StatelessWidget {
  const _StatusMark({required this.number, required this.isCompleted});

  final int number;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AnimatedContainer(
      duration: LessonTile._duration,
      curve: Curves.easeOutCubic,
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted ? colors.primary : Colors.transparent,
        border: Border.all(
          color: isCompleted ? colors.primary : colors.outlineVariant,
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: LessonTile._duration,
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: animation,
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: isCompleted
            ? Icon(
                Icons.check_rounded,
                key: const ValueKey(true),
                size: 16,
                color: colors.onPrimary,
              )
            : ExcludeSemantics(
                key: const ValueKey(false),
                child: Text(
                  '$number',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
      ),
    );
  }
}
