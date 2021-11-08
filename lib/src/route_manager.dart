import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'route_config.dart';

final Map<String, MuliRouteManager> _managers = {};

class MuliRouteManager extends ChangeNotifier {
  static const String defaultKey = 'ROOT';
  static MuliRouteManager get I => _managers[defaultKey]!;
  static MuliRouteManager? instanceFor(String key) => _managers[key]!;

  final GlobalKey<NavigatorState> _navigatorKey;
  final String key;
  final Map<Pattern, AbstractMuliRouteConfig> configs;
  final Pattern unknownPath;
  final _pages = <MuliRoutedPage>[];
  final bool debug;
  final MuliRouteManager? _parent;

  Completer? _haltCompleter, _pushRouteCompleter;
  bool _willHalt = false;
  bool _halted = false;

  late Uri _currentUri;

  MuliRouteManager({
    this.key = defaultKey,
    required this.unknownPath,
    required this.configs,
    required String initalPath,
    this.debug = kDebugMode,
    required GlobalKey<NavigatorState> navigatorKey,
  })  : _parent = null,
        _navigatorKey = navigatorKey {
    _managers[key] = this;
    _currentUri = Uri.parse(initalPath);
    push(_currentUri);
    _debugMessage('Instanticated $key Route Manager', m: 'b');
  }

  MuliRouteManager.nested({
    this.key = defaultKey,
    required this.unknownPath,
    required this.configs,
    required String initalPath,
    required MuliRouteManager parent,
    this.debug = kDebugMode,
    required GlobalKey<NavigatorState> navigatorKey,
  })  : _parent = parent,
        _navigatorKey = navigatorKey {
    _managers[key] = this;
    _currentUri = Uri.parse(initalPath);
    push(_currentUri);

    _debugMessage('Instanticated Nested $key Route Manager', m: 'b');
  }

  //? GETTERS
  Uri? get currentConfiguration {
    Uri uri = _currentUri;

    if (_parent != null) {
      final path = (_parent!.currentConfiguration?.path ?? '') + uri.path;
      uri = Uri(
        path: path,
        query: uri.query,
      );
    }

    return uri;
  }

  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  bool get halted => _halted;

  //? PUBLIC
  List<Page<Uri>> buildPages() {
    return _pages.map((e) => e.toPage()).toList();
  }

  Future<void> setNewRoutePath(Uri configuration) async {
    configuration = _cleanUri(configuration);
    _debugMessage('called setNewRoutePath with $configuration');
    updateAddressBar(configuration);
    _processPages(force: true);

    if (_haltCompleter != null && !_haltCompleter!.isCompleted) {
      await _haltCompleter!.future;
    }
    if (configuration.hasEmptyPath) {
      push(_currentUri);
    } else {
      replaceAll(configuration);
    }

    return SynchronousFuture(null);
  }

  //* Routing Specific

  bool canPop() => _pages.length > 1;
  void pop({dynamic result}) {
    if (canPop()) {
      _pages.removeLast();
      updateAddressBar(_pages.last.uri);
      _processPages();
      if (_pushRouteCompleter != null && !_pushRouteCompleter!.isCompleted) {
        _pushRouteCompleter!.complete(result);
      }
    } else {
      _debugMessage('Cannot pop as pages length less than 2');
    }
  }

  void errorRoute() {
    final page = _processURI(Uri.parse(
      unknownPath.toString(),
    ))!;

    _addPage(page);
    updateAddressBar(page.uri);
    _processPages();
  }

  Completer? push(Uri uri) {
    final canPush = _canPushUri(uri);
    if (!canPush) return null;
    _pushRouteCompleter = Completer();
    final page = _processURI(uri);
    if (page != null) {
      _addPage(page);
      updateAddressBar(page.uri);
      _processPages();
      return _pushRouteCompleter;
    } else {
      errorRoute();
    }
  }

  void pushReplacement(Uri uri) {
    if (_pages.isNotEmpty) {
      final page = _processURI(uri);
      if (page != null) {
        _replace(page);
        updateAddressBar(page.uri);
        _processPages();
      } else {
        errorRoute();
      }
    }
  }

  bool isRouteAlreadyInNavigator(Pattern pattern) {
    for (var page in _pages) {
      if (pattern.matchAsPrefix(page.uri.path) != null) {
        return true;
      }
    }
    return false;
  }

  void replaceAll(Uri uri) {
    final page = _processURI(uri);

    if (page != null) {
      _replaceAll(page);
      updateAddressBar(page.uri);
      _processPages();
    } else {
      errorRoute();
    }
  }

  void pushStack(List<Uri> paths) {
    final pages = <MuliRoutedPage>[];
    for (var uri in paths) {
      final page = _processURI(uri);

      if (page != null) {
        pages.add(page);
      } else {
        errorRoute();
        return;
      }
    }

    for (var element in pages) {
      _addPage(element);
      updateAddressBar(pages.last.uri);
      _processPages();
    }
  }

  void replaceStack(List<Uri> paths) {
    final pages = <MuliRoutedPage>[];
    for (var uri in paths) {
      final page = _processURI(uri);

      if (page != null) {
        pages.add(page);
      } else {
        errorRoute();
        return;
      }
    }

    _addAllReplaced(pages);
    updateAddressBar(pages.last.uri);
    _processPages();
  }

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? showSnackBar(
      SnackBar snackbar) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      _debugMessage("No valid context found to show snackbar", m: 'r');
      return null;
    }
    _debugMessage(
        "Showing Snackbar ${snackbar.key != null ? snackbar.key! : ''}",
        m: 'g');

    final completer =
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(snackbar);

    completer?.closed.then((value) {
      _debugMessage(
          "Closed Snackbar ${snackbar.key != null ? snackbar.key! : ''} Reason: $value",
          m: 'g');
    });
    return completer;
  }

  void hideSnackbar() {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
  }

  ScaffoldFeatureController<MaterialBanner, MaterialBannerClosedReason>?
      showMaterialBanner(MaterialBanner banner) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      _debugMessage("No valid context found to show banner", m: 'r');
      return null;
    }
    _debugMessage("Showing Banner ${banner.key != null ? banner.key! : ''}",
        m: 'g');
    final completer =
        ScaffoldMessenger.maybeOf(context)?.showMaterialBanner(banner);
    completer?.closed.then((value) {
      _debugMessage(
          "Closed Banner ${banner.key != null ? banner.key! : ''} Reason: $value",
          m: 'g');
    });
    return completer;
  }

  void hideMaterialBanner() {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    ScaffoldMessenger.maybeOf(context)?.hideCurrentMaterialBanner();
  }

  //? PRIVATE

  void _debugMessage(String message, {String? m = 'y'}) {
    if (debug) {
      String _b = '\x1B[32m';

      switch (m) {
        case 'r':
          _b = '\x1B[31m';
          break;
        case 'y':
          _b = '\x1B[33m';
          break;
        case 'b':
          _b = '\x1B[34m';
          break;
        default:
          _b = '\x1B[32m';
      }

      // ignore: avoid_print
      log('$_b$message$_b', name: 'Muli Manager: $key');
    }
  }

  void updateAddressBar(Uri uri) {
    _currentUri = uri;
    _processPages();
  }

  Iterable<Pattern> _matches(Uri uri) {
    final matchedRoute = configs.keys.where((element) {
      final match = element.matchAsPrefix(uri.path);
      return match != null;
    });

    return matchedRoute;
  }

  Uri _cleanUri(Uri uri) {
    if (_parent != null) {
      String path = _parent?.currentConfiguration?.path ?? '';

      for (var pattern in configs.keys) {
        final index = path.indexOf(pattern);
        if (index != -1) {
          _parent?.updateAddressBar(Uri.parse(path.substring(0, index)));
          break;
        }
      }
      path = _parent?.currentConfiguration?.path ?? '';
      final _updatedNestedUri = uri.path.replaceFirst(path, '');
      uri = Uri(path: _updatedNestedUri, query: uri.query);
      return uri;
    }
    return uri;
  }

  MuliRoutedPage? _processURI(Uri _uri) {
    Uri uri = _cleanUri(_uri);

    final matchedRoute = _matches(uri);
    if (matchedRoute.isEmpty) {
      _debugMessage(
        'cannot Navigate to/from $uri as no matching pattern exists.',
      );
      return null;
    }
    final match = matchedRoute.last;
    var page = configs[match]!;

    if (page.permissionsInterceptors.isNotEmpty) {
      final hasPerm = _hasAllPermission(page, uri);

      if (hasPerm != null) {
        _debugMessage('Redirecting to $hasPerm');

        return _processURI(Uri.parse(hasPerm.toString()));
      }
    }

    final arguments = <String>[];
    final matches = match.allMatches(uri.toString()).first;

    matches
        .groups(
      List.generate(matches.groupCount, (index) => index + 1),
    )
        .forEach((element) {
      if (element != null) arguments.add(element);
    });

    if (page.completer != null) {
      _haltCompleter = page.completer;
      _willHalt = true;
      page.completer?.future.then((_) {
        _willHalt = false;
        _halted = false;
        _haltCompleter = null;
        _processPages();
      });
    }
    return page.toRoutedPage(
      uri,
      parameters: uri.queryParameters,
      arguments: arguments,
    );
  }

  void _replace(MuliRoutedPage page) => _pages
    ..removeLast()
    ..add(page);
  void _replaceAll(MuliRoutedPage page) => _pages
    ..clear()
    ..add(page);
  void _addAll(List<MuliRoutedPage> pages) => _pages..addAll(pages);
  void _addAllReplaced(List<MuliRoutedPage> pages) => _pages
    ..clear()
    ..addAll(pages);

  void _addPage(MuliRoutedPage page) {
    _pages.add(page);
  }

  bool _canPushUri(Uri uri) {
    final canAddPage = _pages.isEmpty || _pages.last.uri != uri;
    return canAddPage;
  }

  Pattern? _hasAllPermission(AbstractMuliRouteConfig config, Uri uri) {
    for (var interceptor in config.permissionsInterceptors) {
      for (var permission in interceptor.permissions) {
        if (!permission.hasPermission(uri)) {
          _debugMessage('Permission $permission failed for route $uri ');
          return interceptor.redirectTo;
        }
      }
    }
    return null;
  }

  _processPages({bool force = false}) {
    if (!force) {
      if (_halted) return;
      if (_willHalt) {
        _halted = true;
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _managers.remove(key);
    _debugMessage('Removed From Memory', m: 'r');
    super.dispose();
  }
}
