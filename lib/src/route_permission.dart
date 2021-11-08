import 'package:equatable/equatable.dart';

abstract class MuliRoutePermission extends Equatable {
  bool hasPermission(Uri uri);

  @override
  List<Object?> get props => [runtimeType];
}

class MuliRoutePermissionInterceptor {
  final List<MuliRoutePermission> permissions;
  final Pattern redirectTo;

  MuliRoutePermissionInterceptor({
    required this.permissions,
    required this.redirectTo,
  });
}
