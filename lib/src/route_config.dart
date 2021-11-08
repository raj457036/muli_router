import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'widgets/muli_page.dart';

import 'muli_route_state.dart';
import 'route_permission.dart';

typedef NoContextWidgetBuilder = Widget Function(MuliRouteState state);
typedef NoContextMuliPageBuilder = MuliPage Function(MuliRouteState state);

abstract class AbstractMuliRouteConfig {
  final String key;

  final List<MuliRoutePermissionInterceptor> permissionsInterceptors;
  final Completer<void>? completer;

  AbstractMuliRouteConfig({
    required this.key,
    this.completer,
    this.permissionsInterceptors = const [],
  });

  MuliRoutedPage toRoutedPage(
    Uri uri, {
    Map<String, String> parameters = const {},
    List<String> arguments = const [],
  });
}

class MuliWidgetRouteConfig extends AbstractMuliRouteConfig {
  final NoContextWidgetBuilder builder;

  MuliWidgetRouteConfig({
    required String key,
    required this.builder,
    Completer<void>? completer,
    List<MuliRoutePermissionInterceptor> permissionsInterceptors = const [],
  }) : super(
          key: key,
          completer: completer,
          permissionsInterceptors: permissionsInterceptors,
        );

  @override
  MuliRoutedPage toRoutedPage(
    Uri uri, {
    Map<String, String> parameters = const {},
    List<String> arguments = const [],
  }) {
    return MuliRoutedPage(
        content: builder(MuliRouteState(parameters, arguments)),
        uri: uri,
        parameters: parameters,
        permissions: permissionsInterceptors.toSet(),
        arguments: arguments);
  }
}

class MuliRouteConfig extends AbstractMuliRouteConfig {
  final NoContextMuliPageBuilder builder;

  MuliRouteConfig({
    required String key,
    required this.builder,
    Completer<void>? completer,
    List<MuliRoutePermissionInterceptor> permissionsInterceptors = const [],
  }) : super(
          key: key,
          completer: completer,
          permissionsInterceptors: permissionsInterceptors,
        );

  @override
  MuliRoutedPage toRoutedPage(
    Uri uri, {
    Map<String, String> parameters = const {},
    List<String> arguments = const [],
  }) {
    return MuliRoutedPage(
        content: builder(MuliRouteState(parameters, arguments)),
        uri: uri,
        parameters: parameters,
        permissions: permissionsInterceptors.toSet(),
        arguments: arguments);
  }
}

class MuliRoutedPage {
  final Widget content;
  final Uri uri;
  final Map<String, String> parameters;
  final Set<MuliRoutePermissionInterceptor> permissions;
  final List<String> arguments;

  MuliRoutedPage({
    required this.content,
    required this.uri,
    this.permissions = const {},
    this.parameters = const {},
    this.arguments = const [],
  });

  Page<Uri> toPage() {
    return MaterialPage<Uri>(
      child: content,
      name: uri.path,
    );
  }
}
