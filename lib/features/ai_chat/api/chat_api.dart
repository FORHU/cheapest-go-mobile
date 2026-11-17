import 'package:cheapest_go_mobile/shared/lib/http.dart';

/// The one call V2's `/ai-chat` makes: `POST /chat`, with V2's body.
///
/// api-v2 relays the message to ChatWonder under a session it keeps per `conversationId`, and
/// answers once the whole reply is in — `{ "response": "…" }`. Nothing is streamed, on the web
/// or here: the screen shows a spinner bubble until the reply lands, as V2's does.
class ChatApi {
    ChatApi({HttpClientAdapter? client}) : _client = client ?? http;

    final HttpClientAdapter _client;

    /// No account is needed on the server side, as on V2. The relay can be slow to answer a
    /// long itinerary, so it gets longer than the adapter's default 30 seconds.
    static const _options = HttpRequestOptions(
        useMobileApiKey: true,
        requiresAuth: false,
        timeout: Duration(seconds: 60),
    );

    /// The assistant's reply. Throws on any failure; the screen turns that into V2's apology.
    Future<String> send({
        required String message,
        required String conversationId,
        required String lang,
    }) async {
        final res = await _client.post(
            '/api/v2/chat',
            body: {'message': message, 'conversationId': conversationId, 'lang': lang},
            options: _options,
        );
        final body = res is Map<String, dynamic> ? res : const <String, dynamic>{};
        return body['response']?.toString() ?? '';
    }
}

/// Swapped for a fake in tests, as `flightsApi` is.
ChatApi chatApi = ChatApi();
