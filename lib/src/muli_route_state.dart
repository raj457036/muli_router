import 'package:flutter/widgets.dart';

@immutable
class MuliRouteState {
  final Map<String, String> parameters;
  final List<String> arguments;

  const MuliRouteState(this.parameters, this.arguments);
}
