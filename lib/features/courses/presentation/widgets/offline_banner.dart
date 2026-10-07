import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/theme/app_spacing.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    required this.failure,
    required this.savedAt,
    super.key,
  });

  final AppFailure failure;
  final DateTime savedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isOffline = failure is NetworkFailure;

    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Icon(
                isOffline
                    ? CupertinoIcons.wifi_slash
                    : CupertinoIcons.arrow_clockwise,
                size: 18,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOffline ? "You're offline" : "Couldn't refresh",
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Showing courses saved ${_describeAge(savedAt)}.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _describeAge(DateTime savedAt) {
  final age = DateTime.now().difference(savedAt);
  return switch (age) {
    _ when age.inMinutes < 1 => 'just now',
    _ when age.inHours < 1 => '${age.inMinutes} min ago',
    _ when age.inDays < 1 => '${age.inHours} hr ago',
    _ when age.inDays == 1 => 'yesterday',
    _ => '${age.inDays} days ago',
  };
}
