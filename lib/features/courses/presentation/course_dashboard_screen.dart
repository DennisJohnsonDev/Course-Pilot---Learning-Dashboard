import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_mode_controller.dart';
import '../../../core/widgets/entrance.dart';
import '../../../core/widgets/theme_reveal.dart';
import '../../auth/presentation/session_controller.dart';
import '../../auth/presentation/widgets/account_sheet.dart';
import '../data/models/course.dart';
import '../data/models/course_feed.dart';
import 'courses_provider.dart';
import 'widgets/course_card.dart';
import 'widgets/course_list_skeleton.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/offline_banner.dart';
import 'widgets/state_message.dart';

class CourseDashboardScreen extends ConsumerStatefulWidget {
  const CourseDashboardScreen({super.key});

  @override
  ConsumerState<CourseDashboardScreen> createState() =>
      _CourseDashboardScreenState();
}

class _CourseDashboardScreenState extends ConsumerState<CourseDashboardScreen>
    with SingleTickerProviderStateMixin {
  static const _maxContentWidth = 640.0;

  /// Critically damped: no bounce, and reversing mid-flight keeps velocity.
  static final _searchSpring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 300,
  );

  final _scroll = ScrollController();
  final _query = TextEditingController();
  final _searchFocus = FocusNode();
  late final _searchMotion = AnimationController(vsync: this);

  bool _searching = false;
  String _activeQuery = '';

  @override
  void initState() {
    super.initState();
    _query.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _query.dispose();
    _searchFocus.dispose();
    _searchMotion.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    final query = _query.text.trim();
    if (query == _activeQuery) return;
    if (_activeQuery.isEmpty && _scroll.hasClients) _scroll.jumpTo(0);
    setState(() => _activeQuery = query);
  }

  void _animateSearch({required bool open}) {
    final target = open ? 1.0 : 0.0;
    if (MediaQuery.disableAnimationsOf(context)) {
      _searchMotion.value = target;
      return;
    }
    unawaited(
      _searchMotion.animateWith(
        SpringSimulation(
          _searchSpring,
          _searchMotion.value,
          target,
          _searchMotion.velocity,
        ),
      ),
    );
  }

  void _openSearch() {
    unawaited(HapticFeedback.selectionClick());
    setState(() => _searching = true);
    _searchFocus.requestFocus();
    _animateSearch(open: true);
  }

  void _closeSearch() {
    setState(() => _searching = false);
    _query.clear();
    _searchFocus.unfocus();
    _animateSearch(open: false);
  }

  void _toggleTheme(Offset center) {
    unawaited(HapticFeedback.selectionClick());
    final brightness = Theme.of(context).brightness;
    unawaited(
      ThemeReveal.run(
        context,
        center: center,
        change: () => ref.read(themeModeProvider.notifier).toggle(brightness),
      ),
    );
  }

  Future<void> _openAccount() async {
    final signOut = await showAccountSheet(
      context,
      user: ref.read(currentUserProvider),
    );
    if (!signOut) return;
    unawaited(HapticFeedback.mediumImpact());
    await ref.read(sessionControllerProvider.notifier).signOut();
  }

  Future<void> _refresh() async {
    try {
      ref.invalidate(coursesProvider);
      await ref.read(coursesProvider.future);
    } on Object {
      // Reported by the snackbar listener.
    }
  }

  @override
  Widget build(BuildContext context) {
    final courses = ref.watch(coursesProvider);
    final user = ref.watch(currentUserProvider);
    final topInset = MediaQuery.paddingOf(context).top;
    final query = _searching ? _activeQuery : '';

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
      AsyncValue(value: CourseFeed(:final courses)) => switch ([
        for (final course in courses)
          if (_matches(course, query)) course,
      ]) {
        [] => SliverFillRemaining(
          hasScrollBody: false,
          child: Entrance(
            child: StateMessage(
              icon: CupertinoIcons.search,
              title: 'No matches',
              message: 'No courses match “$query”.',
            ),
          ),
        ),
        // A fresh key replays the cascade when search starts or ends.
        final matches => _CourseList(matches, key: ValueKey(query.isEmpty)),
      },
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

    return PopScope(
      canPop: !_searching,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _closeSearch();
      },
      child: Scaffold(
        body: Stack(
          children: [
            RefreshIndicator.adaptive(
              edgeOffset: topInset + DashboardHeader.barHeight,
              notificationPredicate: (notification) =>
                  courses.hasValue && notification.depth == 0,
              onRefresh: _refresh,
              child: CustomScrollView(
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  ListenableBuilder(
                    listenable: _searchMotion,
                    builder: (context, _) => SliverToBoxAdapter(
                      child: SizedBox(
                        height: DashboardHeader.extentFor(
                          topInset: topInset,
                          searchProgress: _searchMotion.value,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    sliver: SliverConstrainedCrossAxis(
                      maxExtent: _maxContentWidth,
                      sliver: SliverToBoxAdapter(
                        child: _AnimatedBanner(
                          child: switch (feed) {
                            CourseFeed(
                              :final savedAt?,
                              :final refreshFailure?,
                            ) =>
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
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ListenableBuilder(
                listenable: Listenable.merge([_scroll, _searchMotion]),
                builder: (context, _) => DashboardHeader(
                  scrollOffset: _scroll.hasClients ? _scroll.offset : 0,
                  searchProgress: _searchMotion.value,
                  searching: _searching,
                  queryController: _query,
                  focusNode: _searchFocus,
                  onOpenSearch: _openSearch,
                  onCloseSearch: _closeSearch,
                  onToggleTheme: _toggleTheme,
                  onOpenAccount: _openAccount,
                  user: user,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

bool _matches(Course course, String query) {
  final needle = query.toLowerCase();
  return course.title.toLowerCase().contains(needle) ||
      course.instructor.toLowerCase().contains(needle);
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
  const _CourseList(this.courses, {super.key});

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
              onOpen: (origin) => context.push(
                AppRoutes.courseDetails(course.id),
                extra: origin,
              ),
            ),
          );
        },
      ),
    );
  }
}
