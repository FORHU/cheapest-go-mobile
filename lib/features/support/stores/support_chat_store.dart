/// The customer's Support Chat: one conversation, held open — V2's `useSupportChat` plus the
/// open-request store (`supportWidget.store.ts`), as one ChangeNotifier.
///
/// What is on screen is [SupportState] (a pure reducer); this owns talking to the server. Three
/// things it has to get right, as on V2:
///
///  * a stream event names a message, it does not carry one, so the transcript is refetched and
///    every row replayed through the reducer, which keeps the newer copy
///  * the customer's own message is shown before the server answers, and removed again by
///    whichever confirmation arrives first
///  * the stream is opened only once a conversation exists — before that there is nothing to
///    follow, and a chat is *created* by writing to it, never by looking (ADR-0044)
///
/// No assistant and no "talk to a human" button: ADR-0031 settled that support is answered by
/// people, so a new chat is already waiting for one. That is all V2's escalation is.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:cheapest_go_mobile/features/support/api/support_api.dart';
import 'package:cheapest_go_mobile/features/support/lib/support_state.dart';
import 'package:cheapest_go_mobile/features/support/lib/support_stream.dart';
import 'package:cheapest_go_mobile/features/support/models/support_models.dart';

/// A file the customer chose, read into memory for upload.
class PickedSupportFile {
  const PickedSupportFile(this.name, this.bytes);

  final String name;
  final List<int> bytes;
}

class SupportChatStore extends ChangeNotifier {
  SupportChatStore({
    SupportApi? api,
    required this.locale,
    this.pickFile,
    this.openUrl,
  }) : _api = api ?? SupportApi() {
    _stream = SupportStream(connect: _api.openStream, onChange: () => unawaited(refresh()));
  }

  final SupportApi _api;

  /// The app's language, asked at the moment a conversation is opened.
  final String Function() locale;

  /// The platform's file chooser. Injected so the store can be tested without one.
  final Future<PickedSupportFile?> Function()? pickFile;

  /// Opens an attachment's signed URL outside the app.
  final Future<void> Function(Uri url)? openUrl;

  late final SupportStream _stream;

  SupportState _state = const SupportState();
  SupportAvailability? availability;
  bool sending = false;
  bool failed = false;
  bool attaching = false;

  /// Uploaded and waiting for the message that will carry them.
  List<SupportAttachment> staged = const [];

  /// Whether this account may use the chat. The app composes it from who is signed in.
  bool enabled = false;

  // Whether the conversation has been asked for since the chat was enabled.
  bool _started = false;
  // A refresh in flight, and whether another was asked for meanwhile.
  bool _refreshing = false;
  bool _refreshAgain = false;
  bool _disposed = false;
  // Bumped on every disable, so an answer meant for the previous account is dropped.
  int _session = 0;

  String? _draft;

  SupportConversation? get conversation => _state.conversation;
  List<SupportMessage> get messages => _state.visibleMessages;
  bool get translating => _state.awaitingTranslation;
  int get unread => _state.unread;
  bool get panelOpen => _state.panelOpen;

  /// Hidden rather than offered-and-refused when no bucket is configured.
  bool get canAttach => availability?.attachments == true && pickFile != null;

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  /// Signed in or out. Signing out forgets the chat: the next account is somebody else's.
  void setEnabled(bool value) {
    if (value == enabled) return;
    enabled = value;
    _session += 1;
    _stream.stop();
    _state = const SupportState();
    staged = const [];
    sending = failed = attaching = false;
    _started = false;
    _draft = null;
    if (value) unawaited(_loadAvailability());
    _notify();
  }

  /// Back from the background: the socket is probably gone, and so may be the desk's hours.
  void resumed() {
    if (!enabled) return;
    unawaited(_loadAvailability());
    if (_state.conversation != null) {
      _stream.reconnect();
      unawaited(refresh());
    }
  }

  Future<void> _loadAvailability() async {
    final session = _session;
    try {
      final next = await _api.availability();
      if (session != _session) return;
      availability = next;
    } catch (_) {
      if (session != _session) return;
      availability = null;
    }
    _notify();
  }

  // ── Panel ────────────────────────────────────────────────────────────────────

  /// Another screen asking for the chat — the settings sheet. A [draft] goes into an empty box
  /// for the customer to send; nothing is sent for them.
  void requestOpen({String? draft}) {
    final text = draft?.trim();
    _draft = (text == null || text.isEmpty) ? null : text;
    unawaited(open());
  }

  /// The pending draft, once.
  String? takeDraft() {
    final d = _draft;
    _draft = null;
    return d;
  }

  Future<void> open() async {
    if (!enabled) return;
    _state = _state.openedPanel();
    _notify();
    if (_started) return;
    _started = true;

    final session = _session;
    // Read only: looking does not create a chat (ADR-0044).
    final found = await _api.conversation().catchError((Object _) => null);
    if (session != _session || found == null) return;
    _state = _state.opened(found.conversation, found.messages);
    _stream.start();
    _notify();
  }

  void close() {
    _state = _state.closed();
    _notify();
  }

  void toggle() => panelOpen ? close() : unawaited(open());

  /// Pull the transcript and replay it; the reducer decides what is new.
  Future<void> refresh() async {
    if (!enabled) return;
    if (_refreshing) {
      _refreshAgain = true;
      return;
    }
    _refreshing = true;
    final session = _session;
    try {
      do {
        _refreshAgain = false;
        final found = await _api.conversation().catchError((Object _) => null);
        if (session != _session) return;
        if (found == null) continue;
        var next = _state.copyWith(conversation: found.conversation);
        for (final m in found.messages) {
          next = next.received(m);
        }
        _state = next;
        _notify();
      } while (_refreshAgain);
    } finally {
      _refreshing = false;
    }
  }

  // ── Writing ──────────────────────────────────────────────────────────────────

  /// A chat to write into, created on demand. Attaching and sending are both writing, and either
  /// can be first.
  Future<SupportConversation> _conversationForWriting() async {
    final existing = _state.conversation;
    if (existing != null) return existing;
    final session = _session;
    final conversation = await _api.openConversation(locale());
    if (session == _session) {
      _state = _state.opened(conversation, const []);
      _stream.start();
    }
    return conversation;
  }

  Future<void> send(String body) async {
    final text = body.trim();
    if (text.isEmpty || !enabled) return;
    final files = staged;
    final session = _session;

    final clientId = '${DateTime.now().microsecondsSinceEpoch}-${identityHashCode(Object())}';
    _state = _state.sent(clientId, text, DateTime.now().toUtc().toIso8601String());
    sending = true;
    failed = false;
    _notify();

    try {
      final conversation = await _conversationForWriting();
      final message = await _api.send(conversation.id, text, [for (final f in files) f.id]);
      if (session != _session) return;
      _state = _state.confirmedSend(clientId, message);
      // Only once bound to a message; a failed send leaves them staged to retry.
      staged = const [];
    } catch (_) {
      if (session != _session) return;
      _state = _state.sendFailed(clientId);
      failed = true;
    } finally {
      if (session == _session) {
        sending = false;
        _notify();
      }
    }
  }

  Future<void> attach() async {
    final pick = pickFile;
    if (pick == null || !enabled || attaching) return;
    final session = _session;
    final PickedSupportFile? file;
    try {
      file = await pick();
    } catch (_) {
      return;
    }
    if (file == null || session != _session) return;

    attaching = true;
    failed = false;
    _notify();
    try {
      final conversation = await _conversationForWriting();
      final stored = await _api.upload(conversation.id, file.name, file.bytes);
      if (session != _session) return;
      staged = [...staged, stored];
    } catch (_) {
      if (session != _session) return;
      failed = true;
    } finally {
      if (session == _session) {
        attaching = false;
        _notify();
      }
    }
  }

  void unstage(String id) {
    staged = staged.where((a) => a.id != id).toList();
    _notify();
  }

  /// Asks the API for a fresh signed URL and opens it. Nothing durable is held (ADR-0040).
  Future<void> openAttachment(String id) async {
    final open = openUrl;
    if (open == null) return;
    try {
      await open(Uri.parse(await _api.attachmentUrl(id)));
    } catch (_) {}
  }

  /// What a tapped question became (ADR-0043). Fire and forget.
  void reportSuggestion(String articleId, String outcome) =>
      unawaited(_api.reportSuggestion(articleId, outcome, locale()));

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _stream.stop();
    super.dispose();
  }
}
