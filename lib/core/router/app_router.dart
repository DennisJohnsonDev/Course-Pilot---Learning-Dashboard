import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/session_controller.dart';
import '../../features/courses/presentation/course_dashboard_screen.dart';
import '../../features/courses/presentation/course_details_screen.dart';
import '../theme/app_motion.dart';

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
        pageBuilder: (context, state) => _fadePage(state, const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.courses,
        pageBuilder: (context, state) =>
            _fadePage(state, const CourseDashboardScreen()),
        routes: [
          GoRoute(
            path: ':id',
            redirect: (context, state) =>
                _courseId(state) == null ? AppRoutes.courses : null,
            builder: (context, state) =>
                CourseDetailsScreen(courseId: _courseId(state)!),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);

  return router;
});

/// Signing in or out swaps the whole stack, so it fades instead of sliding.
Page<void> _fadePage(GoRouterState state, Widget child) => CustomTransitionPage(
  key: state.pageKey,
  child: child,
  transitionDuration: AppMotion.slow,
  reverseTransitionDuration: AppMotion.normal,
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    final curved = CurvedAnimation(parent: animation, curve: AppMotion.easeOut);
    // Keeps the platform's effect on this page when another is pushed on top.
    return Theme.of(context).pageTransitionsTheme.buildTransitions(
      ModalRoute.of(context)! as PageRoute<Object?>,
      context,
      kAlwaysCompleteAnimation,
      secondaryAnimation,
      FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween(begin: 0.98, end: 1.0).animate(curved),
          child: child,
        ),
      ),
    );
  },
);

int? _courseId(GoRouterState state) =>
    int.tryParse(state.pathParameters['id'] ?? '');
