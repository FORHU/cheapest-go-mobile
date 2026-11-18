import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// V2's chat history, as `AiChatClient.tsx` keeps it: on the device, never on the account.
///
/// V2 writes it to `localStorage` under `cheap_conversations`, newest first, capped at fifty.
/// This is the same list under the same key in SharedPreferences, so the shape a conversation
/// has on the web is the shape it has here. Like V2's, it goes with the app — it is not a
/// **Saved Trip** and makes no claim to follow the account.

enum ChatRole { user, assistant }

@immutable
class ChatMessage {
    const ChatMessage(this.role, this.content);
    const ChatMessage.user(this.content) : role = ChatRole.user;
    const ChatMessage.assistant(this.content) : role = ChatRole.assistant;

    final ChatRole role;
    final String content;

    Map<String, dynamic> toJson() => {'role': role.name, 'content': content};

    static ChatMessage? tryParse(Object? json) {
        if (json is! Map) return null;
        final role = ChatRole.values.where((r) => r.name == json['role']).firstOrNull;
        final content = json['content'];
        if (role == null || content is! String) return null;
        return ChatMessage(role, content);
    }
}

@immutable
class Conversation {
    const Conversation({
        required this.id,
        required this.title,
        required this.messages,
        required this.createdAt,
    });

    final String id;
    final String title;
    final List<ChatMessage> messages;

    /// Milliseconds since the epoch, as V2's `Date.now()`.
    final int createdAt;

    Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'messages': [for (final m in messages) m.toJson()],
        'createdAt': createdAt,
    };

    static Conversation? tryParse(Object? json) {
        if (json is! Map) return null;
        final id = json['id'];
        final title = json['title'];
        final createdAt = json['createdAt'];
        final messages = json['messages'];
        if (id is! String || title is! String || createdAt is! num || messages is! List) return null;
        return Conversation(
            id: id,
            title: title,
            createdAt: createdAt.toInt(),
            messages: messages.map(ChatMessage.tryParse).whereType<ChatMessage>().toList(),
        );
    }
}

/// V2's title: the first thing the person asked, cut at sixty characters.
String conversationTitle(List<ChatMessage> messages) {
    final first = messages.where((m) => m.role == ChatRole.user).firstOrNull?.content;
    if (first == null) return 'New chat';
    return first.length > 60 ? first.substring(0, 60) : first;
}

/// V2's `newConversationId`: some random base-36, then the time in base 36.
String newConversationId({Random? random, DateTime? now}) {
    final r = random ?? Random();
    const digits = '0123456789abcdefghijklmnopqrstuvwxyz';
    final noise = List.generate(11, (_) => digits[r.nextInt(36)]).join();
    return noise + (now ?? DateTime.now()).millisecondsSinceEpoch.toRadixString(36);
}

/// V2's three history groups. A day is twenty-four hours back from now, not a calendar day —
/// that is how V2 counts it, so a chat from 11pm yesterday is still "Today" at 9am.
({List<Conversation> today, List<Conversation> yesterday, List<Conversation> older}) groupByDate(
    List<Conversation> conversations,
    int nowMs,
) {
    const day = 86400000;
    final today = <Conversation>[];
    final yesterday = <Conversation>[];
    final older = <Conversation>[];
    for (final c in conversations) {
        final diff = nowMs - c.createdAt;
        if (diff < day) {
            today.add(c);
        } else if (diff < 2 * day) {
            yesterday.add(c);
        } else {
            older.add(c);
        }
    }
    return (today: today, yesterday: yesterday, older: older);
}

class ConversationStore {
    const ConversationStore();

    static const storageKey = 'cheap_conversations';
    static const maxStored = 50;

    /// An unreadable store is an empty history, as V2's `catch { return [] }` makes it.
    Future<List<Conversation>> load() async {
        try {
            final prefs = await SharedPreferences.getInstance();
            final raw = prefs.getString(storageKey);
            if (raw == null) return [];
            final decoded = jsonDecode(raw);
            if (decoded is! List) return [];
            return decoded.map(Conversation.tryParse).whereType<Conversation>().toList();
        } catch (_) {
            return [];
        }
    }

    Future<void> save(List<Conversation> conversations) async {
        try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(
                storageKey,
                jsonEncode([for (final c in conversations.take(maxStored)) c.toJson()]),
            );
        } catch (_) {}
    }
}

const conversationStore = ConversationStore();
