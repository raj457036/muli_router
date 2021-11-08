import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'route_config.dart';
import 'route_manager.dart';

class MuliRouterDelgate extends RouterDelegate<Uri>
    with PopNavigatorRouterDelegateMixin<Uri>, ChangeNotifier {
  final List<NavigatorObserver> observers;
  late MuliRouteManager manager;

  MuliRouterDelgate({
    required Map<Pattern, AbstractMuliRouteConfig> configs,
    required Pattern unknownPath,
    required String initalPath,
    this.observers = const [],
    bool debugMode = kDebugMode,
    String? managerKey,
    MuliRouteManager? parent,
    void Function(MuliRouteManager)? onAssignedManager,
  }) : manager = parent != null
            ? MuliRouteManager.nested(
                key: managerKey ?? MuliRouteManager.defaultKey,
                configs: configs,
                unknownPath: unknownPath,
                initalPath: initalPath,
                debug: debugMode,
                parent: parent,
                navigatorKey: GlobalKey(),
              )
            : MuliRouteManager(
                key: managerKey ?? MuliRouteManager.defaultKey,
                configs: configs,
                unknownPath: unknownPath,
                initalPath: initalPath,
                debug: debugMode,
                navigatorKey: GlobalKey(),
              ) {
    manager.addListener(notifyListeners);
    if (onAssignedManager != null) {
      onAssignedManager(manager);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: manager.buildPages(),
      onPopPage: _onPopPage,
      observers: observers,
    );
  }

  bool _onPopPage(Route route, result) {
    if (!route.didPop(result)) {
      return false;
    }
    if (manager.canPop()) {
      manager.pop();
      return true;
    }
    return false;
  }

  @override
  Future<bool> popRoute() {
    if (manager.canPop()) {
      manager.pop();
      return Future.value(true);
    }
    return Future.value(false);
  }

  @override
  Uri? get currentConfiguration => manager.currentConfiguration;

  @override
  GlobalKey<NavigatorState>? get navigatorKey => manager.navigatorKey;

  @override
  Future<void> setNewRoutePath(configuration) =>
      manager.setNewRoutePath(configuration);

  @override
  void dispose() {
    manager.dispose();
    super.dispose();
  }
}
