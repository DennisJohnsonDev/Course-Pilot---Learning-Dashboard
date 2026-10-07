import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../theme/app_motion.dart';

/// Lets a theme change sweep across the screen in a circle.
///
/// The current frame is captured and laid over the app, the theme switches
/// underneath, and the capture is cut away from [center] outwards.
class ThemeReveal extends StatefulWidget {
  const ThemeReveal({required this.child, super.key});

  final Widget child;

  static Future<void> run(
    BuildContext context, {
    required Offset center,
    required VoidCallback change,
  }) => context.findAncestorStateOfType<_ThemeRevealState>()!._run(
    center,
    change,
  );

  @override
  State<ThemeReveal> createState() => _ThemeRevealState();
}

class _ThemeRevealState extends State<ThemeReveal>
    with SingleTickerProviderStateMixin {
  final _boundary = GlobalKey();
  late final AnimationController _progress;

  ui.Image? _snapshot;
  Offset _center = Offset.zero;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
  }

  @override
  void dispose() {
    _progress.dispose();
    _snapshot?.dispose();
    super.dispose();
  }

  Future<void> _run(Offset center, VoidCallback change) async {
    if (_snapshot != null) return;
    if (MediaQuery.disableAnimationsOf(context)) return change();

    // A capture needs a fully painted frame.
    await SchedulerBinding.instance.endOfFrame;
    if (!mounted) return;

    final boundary =
        _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final snapshot = boundary.toImageSync(
      pixelRatio: View.of(context).devicePixelRatio,
    );
    final box = context.findRenderObject()! as RenderBox;
    setState(() {
      _snapshot = snapshot;
      _center = box.globalToLocal(center);
    });
    change();

    await _progress.forward(from: 0);
    if (!mounted) return;
    setState(() => _snapshot = null);
    snapshot.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RepaintBoundary(key: _boundary, child: widget.child),
        if (_snapshot case final snapshot?)
          Positioned.fill(
            child: AbsorbPointer(
              child: AnimatedBuilder(
                animation: _progress,
                builder: (context, child) => ClipPath(
                  clipper: _OutsideCircle(
                    center: _center,
                    fraction: AppMotion.easeInOut.transform(_progress.value),
                  ),
                  child: child,
                ),
                child: RawImage(image: snapshot, fit: BoxFit.fill),
              ),
            ),
          ),
      ],
    );
  }
}

class _OutsideCircle extends CustomClipper<Path> {
  const _OutsideCircle({required this.center, required this.fraction});

  final Offset center;
  final double fraction;

  @override
  Path getClip(Size size) {
    final reach = [
      Offset.zero,
      size.topRight(Offset.zero),
      size.bottomLeft(Offset.zero),
      size.bottomRight(Offset.zero),
    ].map((corner) => (corner - center).distance).reduce(math.max);

    return Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addOval(Rect.fromCircle(center: center, radius: reach * fraction));
  }

  @override
  bool shouldReclip(_OutsideCircle oldClipper) =>
      oldClipper.fraction != fraction || oldClipper.center != center;
}
