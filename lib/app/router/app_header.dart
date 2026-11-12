import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cheapest_go_mobile/features/home/components/stage_chrome.dart';
import 'package:cheapest_go_mobile/shared/components/ui_kit.dart';
import 'package:cheapest_go_mobile/features/auth/stores/auth_store.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/app_colors.dart';

/// The CheapestGo wordmark and profile button, shared by every tab but the map.
class AppHeader extends StatelessWidget {
  const AppHeader({this.onShowcase = false, super.key});

  /// True on the landing, where the header floats over the stage's photograph instead of
  /// sitting on a bar above it — as V2's does. The wordmark goes white to stay readable, and
  /// the ground behind it disappears so the picture runs to the top of the screen.
  final bool onShowcase;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Over the showcase the header floats, and the page scrolls underneath it. Without
    // something behind it the wordmark and whatever is passing below collide and both become
    // unreadable — so the top of the frame darkens into the header rather than cutting off.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: onShowcase ? null : Theme.of(context).scaffoldBackgroundColor,
        gradient: onShowcase
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xD9050A14), Color(0x00050A14)],
              )
            : null,
      ),
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
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontSize: 22,
                          // White over the photograph; "Go" keeps the accent either way.
                          color: onShowcase ? Colors.white : null,
                        ),
                  ),
                ),
              ),
              // On the landing V2 offers a Sign in pill rather than an avatar, so a visitor
              // who has not signed in is asked to; once signed in there is nothing to ask, and
              // the profile button is the way back to the account either way.
              if (onShowcase && !authStore.isAuthenticated)
                GradientPill(
                  label: 'Sign in',
                  onPressed: () => context.push('/login'),
                )
              else
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
