import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';

/// Grows the page out of [origin], the on-screen rect of the element that
/// opened it, while [from] (a live copy of that element) fades into the page.
/// Popping shrinks it back into place, and on iOS an edge swipe drives it.
class ExpandPage<T> extends Page<T> {
  const ExpandPage({
    required this.origin,
    required this.from,
    required this.child,
    super.key,
  });

  final Rect origin;
  final Widget from;
  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) => _ExpandRoute<T>(this);
}

class _ExpandRoute<T> extends PageRoute<T> {
  _ExpandRoute(ExpandPage<T> page) : super(settings: page);

  ExpandPage<T> get _page => settings as ExpandPage<T>;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 520);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 440);

  @override
  bool get maintainState => true;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  // Keeps the page underneath still, so the card grows out of a steady list.
  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) => false;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => _page.child;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => _ExpandTransition(route: this, child: child);

  void _startPopGesture() => navigator!.didStartUserGesture();

  void _updatePopGesture(double delta) => controller!.value -= delta;

  void _endPopGesture(double velocity) {
    final controller = this.controller!;
    final pops = velocity.abs() >= 1 ? velocity > 0 : controller.value < 0.5;

    if (pops) {
      navigator!.pop();
      if (controller.isAnimating) {
        controller.animateBack(
          0,
          duration: reverseTransitionDuration * controller.value,
          curve: AppMotion.easeOut,
        );
      }
    } else {
      controller.animateTo(
        1,
        duration: transitionDuration * (1 - controller.value),
        curve: AppMotion.easeOut,
      );
    }

    if (!controller.isAnimating) return navigator!.didStopUserGesture();
    late final AnimationStatusListener onSettled;
    onSettled = (_) {
      navigator?.didStopUserGesture();
      controller.removeStatusListener(onSettled);
    };
    controller.addStatusListener(onSettled);
  }
}

class _ExpandTransition extends StatefulWidget {
  const _ExpandTransition({required this.route, required this.child});

  final _ExpandRoute<dynamic> route;
  final Widget child;

  @override
  State<_ExpandTransition> createState() => _ExpandTransitionState();
}

class _ExpandTransitionState extends State<_ExpandTransition> {
  static const _edgeWidth = 20.0;

  bool _dragging = false;

  void _dragStart(DragStartDetails details) {
    _dragging = widget.route.popGestureEnabled;
    if (_dragging) widget.route._startPopGesture();
  }

  void _dragUpdate(DragUpdateDetails details) {
    if (!_dragging) return;
    widget.route._updatePopGesture(details.primaryDelta! / context.size!.width);
  }

  void _dragEnd(double velocity) {
    if (!_dragging) return;
    _dragging = false;
    widget.route._endPopGesture(velocity / context.size!.width);
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.route;
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final origin = route._page.origin;

    final value = route.animation!.value;
    // A finger drives the transition one to one.
    final t = route.popGestureInProgress
        ? value
        : AppMotion.emphasized.transform(value);
    final settled = value == 1 && !route.popGestureInProgress;

    final rect = Rect.lerp(origin, Offset.zero & size, t)!;
    final radius = BorderRadius.circular(lerpDouble(AppRadius.lg, 0, t)!);
    final lift = math.sin(math.pi * t);
    final fromOpacity = 1 - const Interval(0, 0.3).transform(t);
    final pageOpacity = const Interval(0.15, 0.55).transform(t);

    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.28 * value),
            ),
          ),
        ),
        Positioned.fromRect(
          rect: rect,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: lift > 0
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.16 * lift),
                        blurRadius: 32 * lift,
                        offset: Offset(0, 12 * lift),
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: radius,
              clipBehavior: settled ? Clip.none : Clip.antiAlias,
              child: ColoredBox(
                color: Color.lerp(
                  theme.colorScheme.surface,
                  theme.scaffoldBackgroundColor,
                  pageOpacity,
                )!,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _ScaledToWidth(
                        size: size,
                        child: Opacity(
                          opacity: pageOpacity,
                          child: widget.child,
                        ),
                      ),
                    ),
                    if (fromOpacity > 0)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: ExcludeSemantics(
                            child: _ScaledToWidth(
                              size: origin.size,
                              child: Opacity(
                                opacity: fromOpacity,
                                child: route._page.from,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (theme.platform == TargetPlatform.iOS)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: _edgeWidth + MediaQuery.paddingOf(context).left,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragStart: _dragStart,
              onHorizontalDragUpdate: _dragUpdate,
              onHorizontalDragEnd: (details) =>
                  _dragEnd(details.velocity.pixelsPerSecond.dx),
              onHorizontalDragCancel: () => _dragEnd(0),
            ),
          ),
      ],
    );
  }
}

/// Lays [child] out at [size] and scales it to the available width, so both
/// the card and the page keep their own layout while the container grows.
class _ScaledToWidth extends StatelessWidget {
  const _ScaledToWidth({required this.size, required this.child});

  final Size size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.fitWidth,
      alignment: Alignment.topCenter,
      child: SizedBox.fromSize(size: size, child: child),
    );
  }
}
