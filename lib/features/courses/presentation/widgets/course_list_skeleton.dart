import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

class CourseListSkeleton extends StatefulWidget {
  const CourseListSkeleton({super.key});

  @override
  State<CourseListSkeleton> createState() => _CourseListSkeletonState();
}

class _CourseListSkeletonState extends State<CourseListSkeleton>
    with SingleTickerProviderStateMixin {
  late final _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highlight = Colors.white.withValues(alpha: isDark ? 0.05 : 0.6);

    return Semantics(
      label: 'Loading courses',
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _sweep,
          builder: (context, child) => ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                highlight.withValues(alpha: 0),
                highlight,
                highlight.withValues(alpha: 0),
              ],
              stops: const [0.3, 0.5, 0.7],
              transform: _Slide(_sweep.value * 2 - 1),
            ).createShader(bounds),
            child: child,
          ),
          child: const Column(
            children: [
              _SkeletonCard(titleWidth: 0.62),
              SizedBox(height: AppSpacing.md),
              _SkeletonCard(titleWidth: 0.45),
              SizedBox(height: AppSpacing.md),
              _SkeletonCard(titleWidth: 0.7),
            ],
          ),
        ),
      ),
    );
  }
}

class _Slide extends GradientTransform {
  const _Slide(this.offset);

  final double offset;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * offset, 0, 0);
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.titleWidth});

  final double titleWidth;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
            _Bone(widthFactor: titleWidth, height: 17),
            const SizedBox(height: AppSpacing.sm),
            const _Bone(widthFactor: 0.3, height: 12),
            const SizedBox(height: 26),
            const _Bone(widthFactor: 1, height: 6),
            const SizedBox(height: 22),
            const Row(
              children: [
                Expanded(child: _Bone(widthFactor: 0.3, height: 12)),
                _Bone(width: 92, height: 36, radius: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Bone extends StatelessWidget {
  const _Bone({
    required this.height,
    this.widthFactor,
    this.width,
    this.radius = 4,
  });

  final double height;
  final double? widthFactor;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final bone = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(radius),
      ),
    );

    if (widthFactor == null) return bone;
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: bone,
    );
  }
}
