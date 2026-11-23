/// The customer's side of a Support Chat — V2's `support.api.ts`, against api-v2's
/// `/api/v2/support`.
///
/// Every call but [SupportApi.availability] needs an account (ADR-0032). The app requires one
/// anyway (ADR-0005), so nothing here has a signed-out path.
library;

import 'package:cheapest_go_mobile/features/support/models/support_models.dart';
import 'package:cheapest_go_mobile/shared/lib/http.dart';

class SupportTranscript {
  const SupportTranscript(this.conversation, this.messages);

  final SupportConversation conversation;
  final List<SupportMessage> messages;
}

class SupportApi {
  SupportApi({HttpClientAdapter? client}) : _http = client ?? http;

  final HttpClientAdapter _http;

  static const _base = '/api/v2/support';

  Map<String, dynamic> _data(Object? res) {
    final data = res is Map<String, dynamic> ? res['data'] : null;
    if (data is Map<String, dynamic>) return data;
    throw StateError('Unexpected support response');
  }

  /// Public — it says nothing about any chat.
  Future<SupportAvailability> availability() async => SupportAvailability.fromJson(
        _data(await _http.get('$_base/availability', options: const HttpRequestOptions(requiresAuth: false))),
      );

  /// Open a conversation, or resume the one already open. Idempotent on the server.
  Future<SupportConversation> openConversation(String locale) async =>
      SupportConversation.fromJson(_data(await _http.post('$_base/conversation', body: {'locale': locale})));

  /// The caller's conversation and its transcript, or null when they have never opened one.
  Future<SupportTranscript?> conversation() async {
    final res = await _http.get('$_base/conversation');
    final data = res is Map<String, dynamic> ? res['data'] : null;
    if (data is! Map<String, dynamic>) return null;
    return SupportTranscript(
      SupportConversation.fromJson(data['conversation'] as Map<String, dynamic>),
      [
        for (final m in (data['messages'] as List? ?? const []))
          if (m is Map<String, dynamic>) SupportMessage.fromJson(m),
      ],
    );
  }

  Future<SupportMessage> send(String conversationId, String body, [List<String> attachmentIds = const []]) async =>
      SupportMessage.fromJson(_data(await _http.post(
        '$_base/conversation/$conversationId/messages',
        body: attachmentIds.isEmpty ? {'body': body} : {'body': body, 'attachmentIds': attachmentIds},
      )));

  /// One file, before the message that will carry it. The answer names it by id.
  Future<SupportAttachment> upload(String conversationId, String fileName, List<int> bytes) async =>
      SupportAttachment.fromJson(_data(await _http.postFile(
        '$_base/conversation/$conversationId/attachments',
        field: 'file',
        bytes: bytes,
        fileName: fileName,
      )));

  /// The five-minute signed URL the API hands over after checking this reader may have the file.
  /// Asked for at the moment of opening, never stored.
  Future<String> attachmentUrl(String attachmentId) => _http.redirectTarget('$_base/attachments/$attachmentId');

  /// What the panel offered and what the customer did with it (ADR-0043). Never awaited by the
  /// caller and never surfaced: a failed counter is our problem, not the customer's.
  Future<void> reportSuggestion(String articleId, String outcome, String locale) async {
    try {
      await _http.post('$_base/suggestions', body: {'articleId': articleId, 'outcome': outcome, 'locale': locale});
    } catch (_) {}
  }

  /// The live stream. An event names a message; it does not carry one — the caller refetches.
  Future<EventLines> openStream() => _http.openEventStream('$_base/stream');
}
