import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_controller.dart';
import 'core/widgets/theme_reveal.dart';

class CoursePilotApp extends ConsumerWidget {
  const CoursePilotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Course Pilot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      // ThemeReveal animates the switch; a crossfade underneath would muddy it.
      themeAnimationStyle: AnimationStyle.noAnimation,
      routerConfig: ref.watch(appRouterProvider),
      builder: (context, child) => AnnotatedRegion(
        value: Theme.of(context).brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: ThemeReveal(child: child!),
      ),
    );
  }
}
