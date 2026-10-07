import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// Fades and settles the page in over a still screen. Signing in or out swaps
/// the whole stack, so the screen it replaces should not slide away.
class FadePage<T> extends Page<T> {
  const FadePage({required this.child, super.key});

  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) => _FadeRoute<T>(this);
}

class _FadeRoute<T> extends PageRoute<T> {
  _FadeRoute(FadePage<T> page) : super(settings: page);

  @override
  Duration get transitionDuration => const Duration(milliseconds: 560);

  @override
  Duration get reverseTransitionDuration => AppMotion.slow;

  @override
  bool get maintainState => true;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) => false;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => (settings as FadePage<T>).child;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Keeps the platform's effect on this page when another is pushed on top.
    return Theme.of(context).pageTransitionsTheme.buildTransitions(
      this,
      context,
      kAlwaysCompleteAnimation,
      secondaryAnimation,
      FadeTransition(
        opacity: animation.drive(CurveTween(curve: AppMotion.easeOut)),
        child: ScaleTransition(
          scale: animation.drive(
            Tween(
              begin: 0.94,
              end: 1.0,
            ).chain(CurveTween(curve: AppMotion.settle)),
          ),
          child: child,
        ),
      ),
    );
  }
}
