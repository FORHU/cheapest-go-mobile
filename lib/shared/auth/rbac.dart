import 'package:cheapest_go_mobile/shared/auth/permissions.dart';
import 'package:cheapest_go_mobile/shared/auth/roles.dart';

class PermissionContext {
  const PermissionContext({
    this.resourceOwnerId,
    this.tenantId,
  });

  final String? resourceOwnerId;
  final String? tenantId;
}

typedef PermissionEvaluator = bool Function(
  PermissionContext context,
  String? userId,
);

bool hasPermission(
  Role role,
  Permission permission, {
  PermissionContext context = const PermissionContext(),
  String? userId,
}) {
  switch (role) {
    case Role.admin:
      return true;
    case Role.supportAgent:
      return permission != Permission.adminAccess;
    case Role.user:
      return switch (permission) {
        Permission.bookingsCreate ||
        Permission.tripsRead ||
        Permission.savedManage =>
          true,
        Permission.bookingsCancel || Permission.profileEdit =>
          context.resourceOwnerId == null || context.resourceOwnerId == userId,
        Permission.adminAccess => false,
      };
    case Role.guest:
      return permission == Permission.savedManage;
  }
}
