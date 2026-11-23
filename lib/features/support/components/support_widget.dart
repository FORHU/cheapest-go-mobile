/// The launcher and the panel above it — V2's `SupportWidget`, on every screen.
///
/// Where V2 puts it on a phone: bottom right, riding 92 logical pixels above the bottom of the
/// screen so it clears the bottom bar (V2 once had it under the bar's Settings button, where it
/// could not be tapped), 16 in from the edge. The panel opens above it at V2's 22rem × 32rem,
/// capped to the screen it opens on.
///
/// No signed-out prompt: V2 needs one because anyone may browse it, and mobile does not let
/// anyone in without an account (ADR-0005). The app passes [visible] false wherever there is no
/// account, onboarding is still owed, or a sheet or dialog is up and would sit under the button.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:cheapest_go_mobile/features/support/components/support_panel.dart';
import 'package:cheapest_go_mobile/features/support/stores/support_chat_store.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/chrome_skin.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/generated/tw_palette.dart';

class SupportWidget extends StatelessWidget {
  const SupportWidget({required this.store, required this.visible, super.key});

  final SupportChatStore store;
  final bool visible;

  /// V2's `bottom-[calc(env(safe-area-inset-bottom)+92px)]`.
  static const clearOfBar = 92.0;
  static const launcherSize = 56.0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        if (!visible || !store.enabled) return const SizedBox.shrink();

        final media = MediaQuery.of(context);
        final safeBottom = media.viewPadding.bottom;
        final keyboard = media.viewInsets.bottom;
        // With the keyboard up the panel rides on it rather than under it.
        final bottom = keyboard > 0 ? keyboard + 8 : safeBottom + clearOfBar;
        final right = media.viewPadding.right > 16 ? media.viewPadding.right : 16.0;
        final width = (media.size.width - 32).clamp(0.0, 352.0);
        // Above the launcher and the gap under it, below the status bar.
        final room = media.size.height - bottom - launcherSize - 12 - media.viewPadding.top - 16;
        final height = room.clamp(160.0, 512.0);

        return Positioned(
          right: right,
          bottom: bottom,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (store.panelOpen) ...[
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 50, offset: Offset(0, 25), spreadRadius: -12)],
                  ),
                  child: SizedBox(width: width, height: height, child: SupportPanel(store: store)),
                ),
                const SizedBox(height: 12),
              ],
              _Launcher(store: store),
            ],
          ),
        );
      },
    );
  }
}

class _Launcher extends StatelessWidget {
  const _Launcher({required this.store});

  final SupportChatStore store;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    // The bottom bar's skin, not the brand blue: both float over the page, as on V2.
    final skin = Theme.of(context).brightness == Brightness.dark ? ChromeSkin.dark : ChromeSkin.light;
    final open = store.panelOpen;
    final unread = store.unread;

    return Semantics(
      button: true,
      expanded: open,
      label: open ? t.support_close : t.support_open,
      excludeSemantics: true,
      child: SizedBox(
        width: SupportWidget.launcherSize,
        height: SupportWidget.launcherSize,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: skin.bar,
              shape: CircleBorder(side: BorderSide(color: skin.border)),
              elevation: 0,
              shadowColor: skin.dockShadow,
              child: InkWell(
                key: const ValueKey('support-launcher'),
                customBorder: const CircleBorder(),
                onTap: store.toggle,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: skin.dockShadow, blurRadius: 30, offset: const Offset(0, 10))],
                  ),
                  child: Center(
                    child: Icon(open ? LucideIcons.x : LucideIcons.messageCircle, size: 24, color: skin.icon),
                  ),
                ),
              ),
            ),
            if (!open && unread > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: TwPalette.rose600, borderRadius: BorderRadius.circular(999)),
                  child: Text(
                    unread > 9 ? '9+' : '$unread',
                    style: const TextStyle(fontSize: 12, height: 1.33, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
