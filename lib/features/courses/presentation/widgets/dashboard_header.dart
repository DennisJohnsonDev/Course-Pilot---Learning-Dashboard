import 'dart:ui' show ImageFilter, lerpDouble;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/entrance.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../auth/data/models/user.dart';
import '../../../auth/presentation/widgets/user_avatar.dart';

/// A large title that settles into a compact bar as the list scrolls, with a
/// search button that grows into the search field.
///
/// Drawn over the list rather than inside it: a focused field inside a pinned
/// sliver asks the list to reveal it and yanks it back to the top.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    required this.scrollOffset,
    required this.searchProgress,
    required this.searching,
    required this.queryController,
    required this.focusNode,
    required this.onOpenSearch,
    required this.onCloseSearch,
    required this.onToggleTheme,
    required this.onOpenAccount,
    required this.user,
    super.key,
  });

  static const barHeight = 56.0;
  static const _collapseBand = 16.0;
  static const _expandedRowCenter = 38.0;
  static const _actionSize = 40.0;
  static const _avatarSize = 36.0;
  static const _cancelWidth = 84.0;
  static const _gutter = AppSpacing.lg;

  /// How much room the list leaves above its first row.
  static double extentFor({
    required double topInset,
    required double searchProgress,
  }) => topInset + barHeight + _collapseBand * (1 - searchProgress);

  final double scrollOffset;
  final double searchProgress;
  final bool searching;
  final TextEditingController queryController;
  final FocusNode focusNode;
  final VoidCallback onOpenSearch;
  final VoidCallback onCloseSearch;

  /// Receives the toggle's centre, where the new theme spreads from.
  final ValueChanged<Offset> onToggleTheme;
  final VoidCallback onOpenAccount;
  final User? user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final topInset = MediaQuery.paddingOf(context).top;
    final t = searchProgress.clamp(0.0, 1.0);

    final minExtent = topInset + barHeight;
    final maxExtent = extentFor(topInset: topInset, searchProgress: t);
    final extent = (maxExtent - scrollOffset).clamp(minExtent, maxExtent);
    final collapse =
        ((topInset + barHeight + _collapseBand - extent) / _collapseBand).clamp(
          0.0,
          1.0,
        );
    final scrolledUnder = scrollOffset > maxExtent - minExtent + 0.5;

    final rowCenter =
        topInset + lerpDouble(_expandedRowCenter, barHeight / 2, collapse)!;
    final chromeOpacity = 1 - const Interval(0, 0.5).transform(t);
    final cancelOpacity = const Interval(0.4, 1).transform(t);

    return SizedBox(
      height: extent,
      child: ClipRect(
        child: BackdropFilter(
          enabled: scrolledUnder,
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: AnimatedContainer(
            duration: AppMotion.fast,
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor.withValues(
                alpha: scrolledUnder ? 0.82 : 1,
              ),
              border: Border(
                bottom: BorderSide(
                  color: colors.outlineVariant.withValues(
                    alpha: scrolledUnder ? 1 : 0,
                  ),
                  width: 0.5,
                ),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final right = constraints.maxWidth - _gutter;
                final searchStart = Rect.fromCenter(
                  center: Offset(
                    right -
                        _avatarSize -
                        _actionSize -
                        AppSpacing.sm * 2 -
                        _actionSize / 2,
                    rowCenter,
                  ),
                  width: _actionSize,
                  height: _actionSize,
                );
                final searchEnd = Rect.fromLTRB(
                  _gutter,
                  rowCenter - 22,
                  right - _cancelWidth,
                  rowCenter + 22,
                );

                return Stack(
                  children: [
                    Positioned(
                      left: _gutter,
                      right: _gutter,
                      top: rowCenter - 22,
                      height: 44,
                      child: IgnorePointer(
                        ignoring: searching,
                        child: Opacity(
                          opacity: chromeOpacity,
                          child: Row(
                            children: [
                              Expanded(
                                child: Transform.translate(
                                  offset: Offset(-12 * t, 0),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Transform.scale(
                                      scale: lerpDouble(1, 0.75, collapse),
                                      alignment: Alignment.centerLeft,
                                      child: Entrance(
                                        child: Semantics(
                                          header: true,
                                          child: Text(
                                            'My Courses',
                                            maxLines: 1,
                                            style: theme
                                                .textTheme
                                                .headlineMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Transform.translate(
                                offset: Offset(16 * t, 0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(
                                      width: _actionSize + AppSpacing.sm,
                                    ),
                                    Entrance(
                                      index: 2,
                                      child: _ThemeButton(
                                        onToggle: onToggleTheme,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Entrance(
                                      index: 3,
                                      child: Semantics(
                                        button: true,
                                        label: 'Account',
                                        child: Pressable(
                                          scale: 0.92,
                                          child: GestureDetector(
                                            onTap: onOpenAccount,
                                            child: UserAvatar(
                                              user: user,
                                              size: _avatarSize,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: _gutter,
                      top: rowCenter - _actionSize / 2,
                      height: _actionSize,
                      width: _cancelWidth - AppSpacing.sm,
                      child: IgnorePointer(
                        ignoring: !searching,
                        child: Opacity(
                          opacity: cancelOpacity,
                          child: Transform.translate(
                            offset: Offset(20 * (1 - t), 0),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: onCloseSearch,
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(0, _actionSize),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xs,
                                  ),
                                ),
                                child: const Text('Cancel', maxLines: 1),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fromRect(
                      rect: Rect.lerp(searchStart, searchEnd, t)!,
                      child: Entrance(
                        index: 1,
                        child: _SearchPill(
                          progress: t,
                          searching: searching,
                          controller: queryController,
                          focusNode: focusNode,
                          fieldWidth: searchEnd.width - 44 - 40,
                          onOpen: onOpenSearch,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// The search button and the field are one object at two sizes, so the field
/// reads as the button opening up rather than something replacing it.
class _SearchPill extends StatelessWidget {
  const _SearchPill({
    required this.progress,
    required this.searching,
    required this.controller,
    required this.focusNode,
    required this.fieldWidth,
    required this.onOpen,
  });

  final double progress;
  final bool searching;
  final TextEditingController controller;
  final FocusNode focusNode;
  final double fieldWidth;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hintStyle = theme.textTheme.bodyLarge?.copyWith(
      color: colors.onSurfaceVariant,
    );

    return Semantics(
      button: !searching,
      label: searching ? null : 'Search courses',
      child: Pressable(
        scale: searching ? 1 : 0.92,
        child: Material(
          color: Color.lerp(
            colors.onSurface.withValues(alpha: 0.06),
            colors.surface,
            progress,
          ),
          shape: StadiumBorder(
            side: BorderSide(
              color: colors.outlineVariant.withValues(alpha: progress),
              width: 0.5,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: searching ? focusNode.requestFocus : onOpen,
            child: Stack(
              children: [
                Positioned(
                  left: lerpDouble(10, 14, progress),
                  top: 0,
                  bottom: 0,
                  child: Icon(
                    CupertinoIcons.search,
                    size: 20,
                    color: Color.lerp(
                      colors.onSurface,
                      colors.onSurfaceVariant,
                      progress,
                    ),
                  ),
                ),
                Positioned(
                  left: 44,
                  top: 0,
                  bottom: 0,
                  width: fieldWidth,
                  child: IgnorePointer(
                    ignoring: !searching,
                    child: Opacity(
                      opacity: const Interval(0.35, 1).transform(progress),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => focusNode.unfocus(),
                          style: theme.textTheme.bodyLarge,
                          cursorColor: colors.primary,
                          decoration: InputDecoration(
                            isCollapsed: true,
                            filled: false,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            hintText: 'Search courses',
                            hintStyle: hintStyle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 2,
                  top: 0,
                  bottom: 0,
                  child: ValueListenableBuilder(
                    valueListenable: controller,
                    builder: (context, value, _) {
                      final visible = searching && value.text.isNotEmpty;
                      return IgnorePointer(
                        ignoring: !visible,
                        child: AnimatedOpacity(
                          opacity: visible ? 1 : 0,
                          duration: AppMotion.fast,
                          child: IconButton(
                            onPressed: controller.clear,
                            tooltip: 'Clear',
                            visualDensity: VisualDensity.compact,
                            icon: Icon(
                              CupertinoIcons.clear_circled_solid,
                              size: 18,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeButton extends StatelessWidget {
  const _ThemeButton({required this.onToggle});

  final ValueChanged<Offset> onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      label: isDark ? 'Switch to light mode' : 'Switch to dark mode',
      child: Pressable(
        scale: 0.9,
        child: Material(
          color: colors.onSurface.withValues(alpha: 0.06),
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              final box = context.findRenderObject()! as RenderBox;
              onToggle(box.localToGlobal(box.size.center(Offset.zero)));
            },
            child: SizedBox.square(
              dimension: DashboardHeader._actionSize,
              child: AnimatedSwitcher(
                duration: AppMotion.slow,
                switchInCurve: AppMotion.settle,
                switchOutCurve: AppMotion.easeOut,
                transitionBuilder: (child, animation) => RotationTransition(
                  turns: Tween(begin: -0.25, end: 0.0).animate(animation),
                  child: ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                ),
                child: Icon(
                  isDark
                      ? CupertinoIcons.sun_max_fill
                      : CupertinoIcons.moon_fill,
                  key: ValueKey(isDark),
                  size: 19,
                  color: colors.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
