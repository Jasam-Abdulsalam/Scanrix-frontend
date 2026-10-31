import 'package:flutter/widgets.dart';

/// Page snapping with a softer, springier settle than the default.
///
/// `PageView` wraps whatever physics it is given in its own
/// `PageScrollPhysics`, which doesn't override [spring], so the snap-back
/// spring is read from this class.
class CarouselSpringPhysics extends PageScrollPhysics {
  const CarouselSpringPhysics({super.parent});

  @override
  CarouselSpringPhysics applyTo(ScrollPhysics? ancestor) => CarouselSpringPhysics(parent: buildParent(ancestor));

  @override
  SpringDescription get spring => const SpringDescription(mass: 1, stiffness: 120, damping: 18);
}
