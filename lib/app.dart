import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';

class CoursePilotApp extends StatelessWidget {
  const CoursePilotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Course Pilot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // Replaced by the app router once the first screen is built.
      home: const Scaffold(),
    );
  }
}
