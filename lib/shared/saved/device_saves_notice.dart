/// What to say, once, to somebody who had stays saved on the device. See #43 and ADR-0004.
///
/// Those saves were a `Set<String>` of hotel ids in SharedPreferences. A row on the server
/// needs a title and a link, and an id alone supplies neither — recovering them would mean a
/// lookup per saved hotel that silently drops anything the supplier no longer returns, and
/// that never runs at all for somebody who does not sign in.
///
/// So they are not migrated. They are announced and cleared, because the one thing worse
/// than losing a shortlist is losing it quietly.
library;
import 'package:shared_preferences/shared_preferences.dart';

const _legacyKey = 'cheapestgo_saved_hotel_ids';
const _noticeShownKey = 'cheapestgo_saved_migration_notice_shown';

class DeviceSavesNotice {
    const DeviceSavesNotice();

    /// How many stays were saved on this device and are about to be let go.
    ///
    /// Zero when there were none, or when this has already been said once — a notice that
    /// returns every launch is noise, not honesty.
    Future<int> pending() async {
        try {
            final prefs = await SharedPreferences.getInstance();
            if (prefs.getBool(_noticeShownKey) ?? false) return 0;
            return (prefs.getStringList(_legacyKey) ?? const []).length;
        } catch (_) {
            return 0;
        }
    }

    /// Said. Forget the device list and do not raise it again.
    Future<void> acknowledge() async {
        try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool(_noticeShownKey, true);
            await prefs.remove(_legacyKey);
        } catch (_) {}
    }
}

const deviceSavesNotice = DeviceSavesNotice();
