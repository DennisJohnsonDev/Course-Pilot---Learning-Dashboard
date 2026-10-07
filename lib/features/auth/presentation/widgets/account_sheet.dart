import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/pressable.dart';
import '../../data/models/user.dart';
import 'user_avatar.dart';

/// Resolves to true when the user confirms signing out.
Future<bool> showAccountSheet(
  BuildContext context, {
  required User? user,
}) async {
  final signOut = await showModalBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => _AccountSheet(user: user),
  );
  return signOut ?? false;
}

class _AccountSheet extends StatefulWidget {
  const _AccountSheet({required this.user});

  final User? user;

  @override
  State<_AccountSheet> createState() => _AccountSheetState();
}

class _AccountSheetState extends State<_AccountSheet> {
  bool _confirming = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final user = widget.user;

    final account = Column(
      key: const ValueKey('account'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            UserAvatar(user: user, size: 56),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.name ?? 'Signed in',
                    style: theme.textTheme.titleLarge,
                  ),
                  if (user != null) ...[
                    const SizedBox(height: 2),
                    Text(user.email, style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        _SheetButton(
          icon: CupertinoIcons.square_arrow_right,
          label: 'Sign Out',
          background: colors.error.withValues(alpha: 0.1),
          foreground: colors.error,
          onPressed: () => setState(() => _confirming = true),
        ),
      ],
    );

    final confirmation = Column(
      key: const ValueKey('confirm'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Sign out?', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Your saved courses will be removed from this device.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(
              child: _SheetButton(
                label: 'Cancel',
                background: colors.onSurface.withValues(alpha: 0.06),
                foreground: colors.onSurface,
                onPressed: () => setState(() => _confirming = false),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _SheetButton(
                label: 'Sign Out',
                background: colors.error,
                foreground: colors.onError,
                onPressed: () => Navigator.pop(context, true),
              ),
            ),
          ],
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: AnimatedSize(
        duration: AppMotion.normal,
        curve: AppMotion.easeOut,
        alignment: Alignment.topCenter,
        child: AnimatedSwitcher(
          duration: AppMotion.slow,
          // Fades through: the old content leaves before the new arrives.
          switchInCurve: const Interval(0.4, 1, curve: AppMotion.easeOut),
          switchOutCurve: const Interval(0.6, 1),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.topCenter,
            children: [...previous, ?current],
          ),
          child: _confirming ? confirmation : account,
        ),
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final Color background;
  final Color foreground;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      backgroundColor: background,
      foregroundColor: foreground,
      elevation: 0,
    );

    return Pressable(
      child: icon == null
          ? FilledButton(onPressed: onPressed, style: style, child: Text(label))
          : FilledButton.icon(
              onPressed: onPressed,
              style: style,
              icon: Icon(icon, size: 20),
              label: Text(label),
            ),
    );
  }
}
