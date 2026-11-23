/// Which text the customer sees first for a message, and what to say about it — V2's
/// `readerView(message, false)` from `translationView.ts`.
///
/// **The translation's language decides who it is for**, not who sent the message: a
/// translation into English is for the inbox, anything else is for the customer. So a customer
/// never sees the English rendering of their own sentence, and a Korean-speaking Agent's Korean
/// reply is shown exactly as typed. The author's words stay one tap away on anything translated.
library;

import 'package:cheapest_go_mobile/features/support/models/support_models.dart';

enum ReaderLabel { translated, pending, untranslated }

class ReaderView {
  const ReaderView({required this.primary, this.original, this.label});

  /// What to show first.
  final String primary;

  /// The author's own words, when [primary] is not them — for "Show original".
  final String? original;

  /// What to tell the reader, or null when there is nothing to say.
  final ReaderLabel? label;
}

const _agentLang = 'en';

ReaderView customerView(SupportMessage m) {
  final asWritten = ReaderView(primary: m.body);
  final status = m.translationStatus;
  if (status == null) return asWritten;
  if (m.senderType != 'guest' && m.senderType != 'agent') return asWritten;
  if (!_forCustomer(m)) return asWritten;

  if (status == TranslationStatus.translated && (m.translatedBody?.isNotEmpty ?? false)) {
    return ReaderView(primary: m.translatedBody!, original: m.body, label: ReaderLabel.translated);
  }
  return ReaderView(
    primary: m.body,
    label: status == TranslationStatus.pending ? ReaderLabel.pending : ReaderLabel.untranslated,
  );
}

bool _forCustomer(SupportMessage m) {
  final lang = m.translatedLang;
  if (lang != null && lang.isNotEmpty) return lang != _agentLang;
  // A row from before the language was recorded up front: outbound was for the customer.
  return m.senderType == 'agent';
}
