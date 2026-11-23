/// The chat's state, as a reducer — V2's `supportReducer.ts`, line for line in behaviour.
///
/// Kept apart from HTTP and the stream because the interesting behaviour is neither: it is that
/// a message arrives more than once. The customer's own message comes back as the response to
/// the POST that sent it *and* over the stream; a reply arrives again each time its translation
/// moves on (ADR-0033).
library;

import 'package:cheapest_go_mobile/features/support/models/support_models.dart';

/// A message shown before the server has confirmed it.
class PendingSupportMessage {
  const PendingSupportMessage({required this.clientId, required this.body, required this.createdAt});

  final String clientId;
  final String body;
  final String createdAt;
}

class SupportState {
  const SupportState({
    this.conversation,
    this.confirmed = const [],
    this.pending = const [],
    this.unread = 0,
    this.panelOpen = false,
  });

  final SupportConversation? conversation;
  final List<SupportMessage> confirmed;
  final List<PendingSupportMessage> pending;
  final int unread;
  final bool panelOpen;

  SupportState copyWith({
    SupportConversation? conversation,
    List<SupportMessage>? confirmed,
    List<PendingSupportMessage>? pending,
    int? unread,
    bool? panelOpen,
  }) =>
      SupportState(
        conversation: conversation ?? this.conversation,
        confirmed: confirmed ?? this.confirmed,
        pending: pending ?? this.pending,
        unread: unread ?? this.unread,
        panelOpen: panelOpen ?? this.panelOpen,
      );

  // ── Actions ──────────────────────────────────────────────────────────────────

  SupportState opened(SupportConversation conversation, List<SupportMessage> messages) =>
      copyWith(conversation: conversation, confirmed: messages);

  SupportState sent(String clientId, String body, String at) =>
      copyWith(pending: [...pending, PendingSupportMessage(clientId: clientId, body: body, createdAt: at)]);

  SupportState confirmedSend(String clientId, SupportMessage message) => copyWith(
        confirmed: _withMessage(confirmed, message),
        pending: pending.where((p) => p.clientId != clientId).toList(),
      );

  /// Nothing is coming: the message never reached the server.
  SupportState sendFailed(String clientId) => copyWith(pending: pending.where((p) => p.clientId != clientId).toList());

  SupportState received(SupportMessage message) {
    // An update to a message already on screen — its translation arriving — is not new and
    // must not raise the unread badge again.
    final isNew = !confirmed.any((m) => m.id == message.id);
    return copyWith(
      confirmed: _withMessage(confirmed, message),
      // The stream beat the POST response to the customer's own message. Matching on the text
      // is imprecise, but the alternative is showing someone their own words twice.
      pending: message.senderType == 'guest' ? pending.where((p) => p.body != message.body).toList() : pending,
      // Only what arrived while nobody was reading, and only from the other side.
      unread: isNew && !panelOpen && message.senderType != 'guest' ? unread + 1 : unread,
    );
  }

  SupportState closed() => copyWith(panelOpen: false);

  /// Opening it is reading it.
  SupportState openedPanel() => copyWith(panelOpen: true, unread: 0);

  // ── Reads ────────────────────────────────────────────────────────────────────

  /// Whether a reply exists that the customer is waiting on the translation of.
  bool get awaitingTranslation => confirmed.any(isHeldForTranslation);

  /// Confirmed rows and anything in flight, in the order they were created rather than the order
  /// they arrived. A reply still being translated for this customer is left out until it settles.
  List<SupportMessage> get visibleMessages {
    final optimistic = [
      for (final p in pending)
        SupportMessage(id: 'pending-${p.clientId}', senderType: 'guest', body: p.body, createdAt: p.createdAt, pending: true),
    ];
    final shown = confirmed.where((m) => !isHeldForTranslation(m));
    return [...shown, ...optimistic]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }
}

/// The staff working language. A translation into anything else is for the customer.
const _agentLang = 'en';

/// A reply whose translation for this customer has not settled yet — held back until it has, so
/// a customer who writes Korean reads the Agent's reply in Korean rather than English first.
/// Only a translation *for this reader* holds anything.
bool isHeldForTranslation(SupportMessage m) =>
    m.translationStatus == TranslationStatus.pending &&
    (m.translatedLang?.isNotEmpty ?? false) &&
    m.translatedLang != _agentLang;

/// How far a translation has got. It only moves forward, so a copy further along is newer.
int _progress(SupportMessage m) => switch (m.translationStatus) {
      TranslationStatus.translated || TranslationStatus.untranslated => 2,
      TranslationStatus.pending => 1,
      null => 0,
    };

/// Add a message, or update the copy already on screen — never with an older copy, since the
/// copies do not arrive in order.
List<SupportMessage> _withMessage(List<SupportMessage> confirmed, SupportMessage message) {
  final index = confirmed.indexWhere((m) => m.id == message.id);
  if (index == -1) return [...confirmed, message];
  if (_progress(message) < _progress(confirmed[index])) return confirmed;
  return [...confirmed]..[index] = message;
}
