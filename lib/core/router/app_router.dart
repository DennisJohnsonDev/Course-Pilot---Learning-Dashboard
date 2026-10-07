import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/session_controller.dart';
import '../../features/courses/presentation/course_dashboard_screen.dart';
import '../../features/courses/presentation/course_details_screen.dart';

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
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.courses,
        builder: (context, state) => const CourseDashboardScreen(),
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

int? _courseId(GoRouterState state) =>
    int.tryParse(state.pathParameters['id'] ?? '');
