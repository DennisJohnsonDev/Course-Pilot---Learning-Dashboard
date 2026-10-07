import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/session_controller.dart';
import '../../features/courses/presentation/course_dashboard_screen.dart';
import '../../features/courses/presentation/course_details_screen.dart';
import '../../features/courses/presentation/widgets/course_card.dart';
import 'expand_page.dart';
import 'fade_page.dart';

abstract final class AppRoutes {
  static const login = '/login';
  static const courses = '/courses';

  static String courseDetails(int id) => '$courses/$id';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final isSignedIn = ValueNotifier(ref.read(sessionControllerProvider));
  ref
    ..listen(sessionControllerProvider, (_, next) => isSignedIn.value = next)
    ..onDispose(isSignedIn.dispose);

  final router = GoRouter(
    initialLocation: AppRoutes.courses,
    refreshListenable: isSignedIn,
    redirect: (context, state) {
      final isAtLogin = state.matchedLocation == AppRoutes.login;
      if (!isSignedIn.value) return isAtLogin ? null : AppRoutes.login;
      return isAtLogin ? AppRoutes.courses : null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) =>
            FadePage(key: state.pageKey, child: const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.courses,
        pageBuilder: (context, state) =>
            FadePage(key: state.pageKey, child: const CourseDashboardScreen()),
        routes: [
          GoRoute(
            path: ':id',
            redirect: (context, state) =>
                _courseId(state) == null ? AppRoutes.courses : null,
            pageBuilder: (context, state) {
              final id = _courseId(state)!;
              final details = CourseDetailsScreen(courseId: id);
              // A card passes its on-screen rect so it can grow into the page.
              return switch (state.extra) {
                final Rect origin => ExpandPage(
                  key: state.pageKey,
                  origin: origin,
                  from: LiveCourseCard(courseId: id),
                  child: details,
                ),
                _ => MaterialPage(key: state.pageKey, child: details),
              };
            },
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);

  return router;
});

int? _courseId(GoRouterState state) =>
    int.tryParse(state.pathParameters['id'] ?? '');
