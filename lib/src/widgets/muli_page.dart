import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

enum Breakpoint { xs, s, m, l, xl }

class ScreenData {
  final Size size;
  final Constraints constraints;
  final Orientation orientation;

  ScreenData({
    required this.size,
    required this.constraints,
    required this.orientation,
  });

  Breakpoint get breakpoint {
    final width = size.width;
    if (width > 1199) {
      return Breakpoint.xl;
    }
    if (width > 991) {
      return Breakpoint.l;
    }
    if (width > 767) {
      return Breakpoint.m;
    }
    if (width > 599) {
      return Breakpoint.s;
    }
    return Breakpoint.xs;
  }

  bool get isXS => size.width < 600;
  bool get isS => size.width > 599;
  bool get isM => size.width > 767;
  bool get isL => size.width > 991;
  bool get isXL => size.width > 1199;

  Breakpoint get bp => breakpoint;
}

typedef PageBuilder = Widget Function(BuildContext context, ScreenData data);

class MuliResponsiveBuilder extends StatelessWidget {
  final PageBuilder builder;

  const MuliResponsiveBuilder({
    Key? key,
    required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (BuildContext context, Orientation orientation) {
        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            final data = ScreenData(
              size: size,
              constraints: constraints,
              orientation: orientation,
            );
            return builder(context, data);
          },
        );
      },
    );
  }
}

@immutable
abstract class MuliPage extends StatelessWidget {
  const MuliPage({
    Key? key,
  }) : super(key: key);

  @override
  MuliResponsiveBuilder build(BuildContext context);
}
