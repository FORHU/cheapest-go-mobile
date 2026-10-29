import 'package:flutter/material.dart';
import 'package:cheapest_go_mobile/features/auth/stores/auth_store.dart';
import 'package:cheapest_go_mobile/shared/auth/permissions.dart';
import 'package:cheapest_go_mobile/shared/auth/rbac.dart';

/// Declarative RBAC Gate Widget (mirrors `next-template-v1/src/features/auth/components/Can.tsx`)
class Can extends StatelessWidget {
  const Can({
    super.key,
    required this.permission,
    required this.child,
    this.fallback = const SizedBox.shrink(),
    this.permissionContext = const PermissionContext(),
  });

  final Permission permission;
  final Widget child;
  final Widget fallback;
  final PermissionContext permissionContext;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: authStore,
      builder: (context, _) {
        if (authStore.can(permission, context: permissionContext)) {
          return child;
        }
        return fallback;
      },
    );
  }
}
