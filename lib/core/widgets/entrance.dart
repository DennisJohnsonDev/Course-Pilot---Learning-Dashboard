import 'package:flutter/widgets.dart';

import '../theme/app_motion.dart';

/// Fades and lifts its child into place when it first appears, staggered by
/// [index].
class Entrance extends StatefulWidget {
  const Entrance({required this.child, this.index = 0, super.key});

  final Widget child;
  final int index;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance> {
  static const _step = Duration(milliseconds: 50);
  static const _maxStagger = 6;
  static const _rise = 12.0;

  late final bool _animates =
      !MediaQuery.disableAnimationsOf(context) &&
      EntranceScope._isFresh(context);

  @override
  Widget build(BuildContext context) {
    final steps = widget.index.clamp(0, _maxStagger);
    final total = AppMotion.slow + _step * steps;
    final start = (_step * steps).inMilliseconds / total.inMilliseconds;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: _animates ? 0 : 1, end: 1),
      duration: total,
      curve: Interval(start, 1, curve: AppMotion.easeOut),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * _rise),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Limits [Entrance] to items built shortly after this scope mounts, so list
/// rows recycled by scrolling don't animate in again.
class EntranceScope extends StatefulWidget {
  const EntranceScope({required this.child, super.key});

  final Widget child;

  static const _window = Duration(milliseconds: 700);

  static bool _isFresh(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<_EntranceScopeData>();
    return scope == null ||
        DateTime.now().difference(scope.mountedAt) < _window;
  }

  @override
  State<EntranceScope> createState() => _EntranceScopeState();
}

class _EntranceScopeState extends State<EntranceScope> {
  final _mountedAt = DateTime.now();

  @override
  Widget build(BuildContext context) =>
      _EntranceScopeData(mountedAt: _mountedAt, child: widget.child);
}

class _EntranceScopeData extends InheritedWidget {
  const _EntranceScopeData({required this.mountedAt, required super.child});

  final DateTime mountedAt;

  @override
  bool updateShouldNotify(_EntranceScopeData oldWidget) => false;
}
