import 'dart:developer';

import 'package:flutter/widgets.dart';

class MuliRouteObserver extends NavigatorObserver {
  final String _name = 'Muli Observer';

  String name(Route? route) {
    return route?.settings.name ?? 'Entry';
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    log('Route Change: ${name(previousRoute)} -> ${name(route)}', name: _name);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    log('Replaced: ${name(oldRoute)} <-> ${name(newRoute)}', name: _name);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    log('Route Change: ${name(previousRoute)} <- ${name(route)} ', name: _name);
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    log('Removed: ${name(previousRoute)}', name: _name);
  }
}
