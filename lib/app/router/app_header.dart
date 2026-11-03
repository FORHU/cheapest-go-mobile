import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cheapest_go_mobile/shared/components/ui_kit.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/app_colors.dart';

/// The CheapestGo wordmark and profile button, shared by every tab but the map.
class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text.rich(
                    TextSpan(children: [
                      const TextSpan(text: 'Cheapest'),
                      TextSpan(text: 'Go', style: TextStyle(color: c.accent)),
                    ]),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 22),
                  ),
                ),
              ),
              CircleIconButton(
                icon: Icons.person_outline_rounded,
                tooltip: 'Profile and account',
                onPressed: () => context.push('/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
