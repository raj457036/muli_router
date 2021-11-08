import 'package:flutter/material.dart';

import '../route_manager.dart';

typedef RouteMangerWidgetBuilder = Widget Function(MuliRouteManager manager);

class XLink extends StatelessWidget {
  final MuliRouteManager? manager;
  final RouteMangerWidgetBuilder builder;

  const XLink({Key? key, required this.builder, this.manager})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return builder(manager ?? MuliRouteManager.I);
  }
}
