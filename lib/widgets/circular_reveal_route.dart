import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Opens [child] with a circular reveal animation expanding from [revealFromRect] center.
class CircularRevealRoute extends PageRouteBuilder<void> {
  CircularRevealRoute({
    required this.revealFromRect,
    required Widget child,
    super.settings,
  }) : super(
          opaque: false,
          barrierColor: Colors.transparent,
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final size = MediaQuery.sizeOf(context);
            final center = revealFromRect.center;
            final maxRadius = _maxRadiusToCover(center, size);
            return _CircularRevealTransition(
              animation: animation,
              revealCenter: center,
              maxRadius: maxRadius,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 420),
          reverseTransitionDuration: const Duration(milliseconds: 320),
        );

  final Rect revealFromRect;

  static double _maxRadiusToCover(Offset center, Size size) {
    final corners = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ];
    return corners.map((c) => (center - c).distance).reduce(math.max);
  }
}

class _CircularRevealTransition extends AnimatedWidget {
  const _CircularRevealTransition({
    required this.animation,
    required this.revealCenter,
    required this.maxRadius,
    required this.child,
  }) : super(listenable: animation);

  final Animation<double> animation;
  final Offset revealCenter;
  final double maxRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final anim = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );
    final radius = maxRadius * anim.value;
    return ClipPath(
      clipper: _CircleRevealClipper(center: revealCenter, radius: radius),
      child: child,
    );
  }
}

class _CircleRevealClipper extends CustomClipper<Path> {
  _CircleRevealClipper({required this.center, required this.radius});

  final Offset center;
  final double radius;

  @override
  Path getClip(Size size) {
    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(_CircleRevealClipper old) {
    return center != old.center || radius != old.radius;
  }
}
