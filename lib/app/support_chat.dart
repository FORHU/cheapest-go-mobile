/// Support Chat, composed into the app (FORHU/cheapest-go-mobile#60).
///
/// The support feature may not reach into auth or onboarding, so this is where it is told who is
/// signed in, handed the platform's file chooser and browser, and told when a sheet or dialog is
/// up. The widget itself is mounted once, above every route, in `app.dart`.
library;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cheapest_go_mobile/features/auth/stores/auth_store.dart';
import 'package:cheapest_go_mobile/features/onboarding/lib/onboarding_markers.dart';
import 'package:cheapest_go_mobile/features/onboarding/stores/onboarding_store.dart';
import 'package:cheapest_go_mobile/features/support/stores/support_chat_store.dart';
import 'package:cheapest_go_mobile/shared/stores/ui_store.dart';

/// What V2's file input accepts: photos and PDFs.
const _accepted = ['jpg', 'jpeg', 'png', 'webp', 'gif', 'heic', 'pdf'];

Future<PickedSupportFile?> _pickFile() async {
  final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: _accepted);
  if (file == null) return null;
  return PickedSupportFile(file.name, await file.xFile.readAsBytes());
}

Future<void> _open(Uri url) async {
  await launchUrl(url, mode: LaunchMode.externalApplication);
}

final SupportChatStore supportChatStore = SupportChatStore(
  locale: () => uiSettingsStore.language,
  pickFile: _pickFile,
  openUrl: _open,
);

/// The chat is for an account that is through the gate: signed in, and not still owing
/// onboarding — the same moment the rest of the app opens up.
bool _eligible() =>
    authStore.isAuthenticated &&
    (onboardingStore.status == OnboardingStatus.completed || onboardingStore.status == OnboardingStatus.notRequired);

void wireSupportChat() {
  void sync() => supportChatStore.setEnabled(_eligible());
  authStore.addListener(sync);
  onboardingStore.addListener(sync);
  sync();
}

/// How many sheets and dialogs are up, across every navigator. The launcher steps aside while
/// any is, rather than floating over a sheet's own buttons.
final ValueNotifier<int> popupsShowing = ValueNotifier<int>(0);

/// One per navigator — an observer can only watch one — all counting into [popupsShowing].
class PopupTracker extends NavigatorObserver {
  void _bump(Route<dynamic>? route, int by) {
    if (route is PopupRoute) {
      final next = popupsShowing.value + by;
      popupsShowing.value = next < 0 ? 0 : next;
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _bump(route, 1);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _bump(route, -1);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) => _bump(route, -1);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _bump(oldRoute, -1);
    _bump(newRoute, 1);
  }
}
