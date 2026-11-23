/// The live half of the chat: api-v2's `/support/stream`, followed for as long as it is wanted.
///
/// Flutter has no EventSource, so this does the two things one does for V2: read the frames as
/// they arrive, and come back when the connection drops. A frame names a message and does not
/// carry it, so all this reports is "something changed" — the store refetches, which is also how
/// a translation landing later reaches the screen.
///
/// Reconnecting asks for a refetch too ([onChange] after the `open` frame): whatever was written
/// while the line was down is in the transcript, not in a backlog this would replay.
library;

import 'dart:async';

import 'package:cheapest_go_mobile/shared/errors/api_error.dart';
import 'package:cheapest_go_mobile/shared/lib/http.dart';

class SupportStream {
  SupportStream({
    required this.connect,
    required this.onChange,
    this.minBackoff = const Duration(seconds: 2),
    this.maxBackoff = const Duration(seconds: 30),
  });

  final Future<EventLines> Function() connect;
  final void Function() onChange;
  final Duration minBackoff;
  final Duration maxBackoff;

  EventLines? _open;
  StreamSubscription<String>? _sub;
  Timer? _retry;
  bool _running = false;
  int _failures = 0;

  bool get running => _running;

  void start() {
    if (_running) return;
    _running = true;
    _failures = 0;
    unawaited(_connect());
  }

  /// Hang up now and dial again — after the app comes back from the background, where the OS
  /// has very likely cut the socket without telling anyone.
  void reconnect() {
    if (!_running) return;
    _hangUp();
    _failures = 0;
    unawaited(_connect());
  }

  void stop() {
    _running = false;
    _hangUp();
  }

  void _hangUp() {
    _retry?.cancel();
    _retry = null;
    unawaited(_sub?.cancel());
    _sub = null;
    _open?.close();
    _open = null;
  }

  Future<void> _connect() async {
    if (!_running) return;
    EventLines lines;
    try {
      lines = await connect();
    } on ApiError catch (e) {
      // Signed out, or the account cannot read a stream: retrying will not change that.
      if (e.status == 401 || e.status == 403) {
        stop();
        return;
      }
      _scheduleRetry();
      return;
    } catch (_) {
      _scheduleRetry();
      return;
    }
    if (!_running) {
      lines.close();
      return;
    }

    _open = lines;
    String? event;
    _sub = lines.lines.listen(
      (line) {
        if (line.isEmpty) {
          // End of a frame.
          if (event == 'support' || event == 'open') onChange();
          if (event == 'open') _failures = 0;
          event = null;
        } else if (line.startsWith('event:')) {
          event = line.substring(6).trim();
        }
        // `data:` is ignored on purpose (it names, it does not carry) and `:` lines are
        // the server's keep-alive.
      },
      onError: (_) => _dropped(),
      onDone: _dropped,
      cancelOnError: true,
    );
  }

  void _dropped() {
    _open?.close();
    _open = null;
    _sub = null;
    _scheduleRetry();
  }

  void _scheduleRetry() {
    if (!_running) return;
    _failures += 1;
    final factor = 1 << (_failures - 1).clamp(0, 5);
    final wait = minBackoff * factor;
    _retry?.cancel();
    _retry = Timer(wait > maxBackoff ? maxBackoff : wait, () => unawaited(_connect()));
  }
}
