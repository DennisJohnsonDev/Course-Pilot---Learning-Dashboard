import 'package:flutter/widgets.dart';

import '../theme/app_motion.dart';

/// Scales its child while pressed. Listens to raw pointers so the child keeps
/// ownership of the tap.
class Pressable extends StatefulWidget {
  const Pressable({required this.child, this.scale = 0.975, super.key});

  final Widget child;
  final double scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  static const _slop = 12.0;

  bool _down = false;
  Offset _origin = Offset.zero;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        _origin = event.position;
        _set(true);
      },
      // A finger that travels is scrolling, not pressing.
      onPointerMove: (event) {
        if ((event.position - _origin).distance > _slop) _set(false);
      },
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: _down ? AppMotion.instant : AppMotion.fast,
        curve: AppMotion.easeOut,
        child: widget.child,
      ),
    );
  }
}
