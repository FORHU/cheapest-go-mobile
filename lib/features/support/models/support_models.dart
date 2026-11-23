/// What the Support Chat reads, as api-v2 sends it — V2's `features/support/types.ts`.
///
/// `sender` becomes [SupportMessage.senderType] on the way in, as on V2, so the translation rule
/// (`lib/translation_view.dart`) reads the same field name the Agent's inbox does.
library;

class SupportConversation {
  const SupportConversation({
    required this.id,
    required this.reference,
    required this.status,
    required this.locale,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;

  /// The Chat Reference a customer quotes when they write in about the chat itself.
  final String reference;
  final String status;
  final String locale;
  final String createdAt;
  final String updatedAt;

  factory SupportConversation.fromJson(Map<String, dynamic> json) => SupportConversation(
        id: json['id'].toString(),
        reference: (json['reference'] ?? '').toString(),
        status: (json['status'] ?? '').toString(),
        locale: (json['locale'] ?? '').toString(),
        createdAt: (json['createdAt'] ?? '').toString(),
        updatedAt: (json['updatedAt'] ?? '').toString(),
      );
}

/// A file on a message. Named by id, never by a URL (ADR-0040): the bytes come through a route
/// that re-checks entitlement and redirects to a five-minute signed URL.
class SupportAttachment {
  const SupportAttachment({
    required this.id,
    required this.fileName,
    this.contentType = '',
    this.sizeBytes = 0,
    this.uploadedByType = 'guest',
    this.bytesDeleted = false,
  });

  final String id;
  final String fileName;
  final String contentType;
  final int sizeBytes;
  final String uploadedByType;

  /// Past its retention window. The transcript still shows the file was sent.
  final bool bytesDeleted;

  factory SupportAttachment.fromJson(Map<String, dynamic> json) => SupportAttachment(
        id: json['id'].toString(),
        fileName: (json['fileName'] ?? '').toString(),
        contentType: (json['contentType'] ?? '').toString(),
        sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
        uploadedByType: (json['uploadedByType'] ?? 'guest').toString(),
        bytesDeleted: json['bytesDeleted'] == true,
      );
}

enum TranslationStatus { pending, translated, untranslated }

TranslationStatus? _status(Object? raw) => switch (raw) {
      'pending' => TranslationStatus.pending,
      'translated' => TranslationStatus.translated,
      'untranslated' => TranslationStatus.untranslated,
      _ => null,
    };

class SupportMessage {
  const SupportMessage({
    required this.id,
    required this.senderType,
    required this.body,
    required this.createdAt,
    this.noticeCode,
    this.translatedBody,
    this.translatedLang,
    this.translationStatus,
    this.attachments = const [],
    this.pending = false,
  });

  final String id;

  /// `guest`, `agent` or `system`.
  final String senderType;
  final String body;
  final String? noticeCode;

  /// The stored rendering beside the author's words, never recomputed on read (ADR-0033).
  final String? translatedBody;
  final String? translatedLang;
  final TranslationStatus? translationStatus;
  final String createdAt;
  final List<SupportAttachment> attachments;

  /// Set only on a message this device is still sending; the server never sends it.
  final bool pending;

  factory SupportMessage.fromJson(Map<String, dynamic> json) => SupportMessage(
        id: json['id'].toString(),
        senderType: (json['sender'] ?? json['senderType'] ?? '').toString(),
        body: (json['body'] ?? '').toString(),
        noticeCode: json['notice']?.toString(),
        translatedBody: json['translatedBody']?.toString(),
        translatedLang: json['translatedLang']?.toString(),
        translationStatus: _status(json['translationStatus']),
        createdAt: (json['createdAt'] ?? '').toString(),
        attachments: [
          for (final a in (json['attachments'] as List? ?? const []))
            if (a is Map<String, dynamic>) SupportAttachment.fromJson(a),
        ],
      );
}

/// When the desk next opens: `ReopenOpening` on V2.
class SupportOpening {
  const SupportOpening({required this.day, required this.open, required this.timezone, required this.today});

  /// `sun` … `sat`.
  final String day;

  /// `HH:MM`.
  final String open;
  final String timezone;
  final bool today;

  static SupportOpening? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    return SupportOpening(
      day: (json['day'] ?? '').toString(),
      open: (json['open'] ?? '').toString(),
      timezone: (json['timezone'] ?? '').toString(),
      today: json['today'] == true,
    );
  }
}

/// Whether a person can be reached right now, and when they next can.
class SupportAvailability {
  const SupportAvailability({required this.humanAvailable, this.attachments = false, this.nextOpening});

  final bool humanAvailable;

  /// Whether a bucket is configured at all; false hides the paperclip.
  final bool attachments;
  final SupportOpening? nextOpening;

  factory SupportAvailability.fromJson(Map<String, dynamic> json) => SupportAvailability(
        humanAvailable: json['humanAvailable'] == true,
        attachments: json['attachments'] == true,
        nextOpening: SupportOpening.fromJson(json['nextOpening']),
      );
}
