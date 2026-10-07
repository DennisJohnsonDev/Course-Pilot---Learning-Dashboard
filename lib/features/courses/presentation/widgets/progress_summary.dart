import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../data/models/course.dart';

class ProgressSummary extends StatelessWidget {
  const ProgressSummary({required this.course, super.key});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final remaining = course.lessons.length - course.completedLessons;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: course.progress / 100),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                label: '${course.progress}% complete',
                excludeSemantics: true,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${(value * 100).round()}%',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'complete',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: value, minHeight: 8),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(switch (remaining) {
                0 => 'All lessons completed',
                1 => '1 lesson to go',
                _ => '$remaining lessons to go',
              }, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
