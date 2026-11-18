import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cheapest_go_mobile/app/router/v2_bottom_nav.dart';
import 'package:cheapest_go_mobile/app/theme/app_theme.dart';
import 'package:cheapest_go_mobile/features/ai_chat/api/chat_api.dart';
import 'package:cheapest_go_mobile/features/ai_chat/lib/conversations.dart';

import '../../test_helpers.dart';

class FakeChatApi extends ChatApi {
    final sent = <Map<String, String>>[];
    String reply = 'Tokyo in March is lovely.';
    Object? error;
    Completer<String>? pending;

    @override
    Future<String> send({required String message, required String conversationId, required String lang}) {
        sent.add({'message': message, 'conversationId': conversationId, 'lang': lang});
        if (error != null) return Future.error(error!);
        if (pending != null) return pending!.future;
        return Future.value(reply);
    }
}

/// V2's `/ai-chat` (`AiChatClient.tsx`), driven through the app's router.
void main() {
    late FakeChatApi api;
    final original = chatApi;

    setUp(() {
        SharedPreferences.setMockInitialValues({});
        api = FakeChatApi();
        chatApi = api;
    });
    tearDown(() => chatApi = original);

    Future<List<dynamic>> stored() async {
        final prefs = await SharedPreferences.getInstance();
        return jsonDecode(prefs.getString(ConversationStore.storageKey) ?? '[]') as List<dynamic>;
    }

    /// With V2's sidebar open the prompts stack in a narrow column, so the later ones start
    /// below the fold on a phone — on the web as well. Scroll to one before tapping it.
    Future<void> tapVisible(WidgetTester tester, String text) async {
        final finder = find.text(text).first;
        await tester.ensureVisible(finder);
        await tester.pump();
        await tester.tap(finder);
    }

    testWidgets('the bottom bar steps aside, as V2\'s does on /ai-chat', (tester) async {
        await pumpApp(tester, location: '/');
        expect(find.byType(V2BottomNav), findsOneWidget, reason: 'the bar is there on home');

        await pumpApp(tester, location: '/ai-chat');
        expect(find.byType(V2BottomNav), findsNothing);
    });

    testWidgets('opens on V2\'s greeting, its four prompts and the sidebar', (tester) async {
        await pumpApp(tester, location: '/ai-chat');

        expect(find.text("What's on the agenda today?"), findsOneWidget);
        expect(find.text('Find me cheap flights to Tokyo next month'), findsOneWidget);
        expect(find.text('What hotels are available in Bali for 2 adults?'), findsOneWidget);
        expect(find.text('Plan a 5-day trip to Paris on a budget'), findsOneWidget);
        expect(find.text("What's the cheapest day to fly to NYC?"), findsOneWidget);
        expect(find.text('CheapestGo AI'), findsOneWidget);
        expect(find.text('New chat'), findsOneWidget);
        expect(find.text('English'), findsOneWidget);
        expect(find.text('Ask anything...'), findsOneWidget);
        expect(find.text('Enter to send · Shift+Enter for new line'), findsOneWidget);
        expect(find.byTooltip('Close sidebar'), findsOneWidget);
        expect(find.byTooltip('Go to home'), findsOneWidget);
    });

    testWidgets('a prompt is sent, waits on a spinner, and the reply replaces it', (tester) async {
        api.pending = Completer<String>();
        await pumpApp(tester, location: '/ai-chat');

        await tapVisible(tester, 'Find me cheap flights to Tokyo next month');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(api.sent.single['message'], 'Find me cheap flights to Tokyo next month');
        expect(api.sent.single['lang'], 'en');
        expect(api.sent.single['conversationId'], isNotEmpty);
        expect(find.byKey(const Key('aiChat.thinking')), findsOneWidget);
        expect(find.text("What's on the agenda today?"), findsNothing);

        api.pending!.complete('Try Zipair from Manila.');
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('aiChat.thinking')), findsNothing);
        expect(find.text('Try Zipair from Manila.'), findsOneWidget);
    });

    testWidgets('typed text goes on the keyboard\'s send, and the field empties', (tester) async {
        await pumpApp(tester, location: '/ai-chat');

        await tester.enterText(find.byKey(const Key('aiChat.input')), '  Weekend in Cebu?  ');
        await tester.testTextInput.receiveAction(TextInputAction.send);
        await tester.pumpAndSettle();

        expect(api.sent.single['message'], 'Weekend in Cebu?');
        expect(find.text('Weekend in Cebu?'), findsWidgets);
        expect(find.text(api.reply), findsOneWidget);
        final field = tester.widget<TextField>(find.byKey(const Key('aiChat.input')));
        expect(field.controller!.text, isEmpty);
    });

    testWidgets('the send button does nothing with an empty field', (tester) async {
        await pumpApp(tester, location: '/ai-chat');
        await tester.enterText(find.byKey(const Key('aiChat.input')), '   ');
        await tester.tap(find.byKey(const Key('aiChat.send')));
        await tester.pumpAndSettle();
        expect(api.sent, isEmpty);
    });

    testWidgets('a failure is V2\'s apology in the thread, not an error screen', (tester) async {
        api.error = Exception('502');
        await pumpApp(tester, location: '/ai-chat');

        await tapVisible(tester, 'Plan a 5-day trip to Paris on a budget');
        await tester.pumpAndSettle();

        expect(find.text("Sorry, I couldn't reach the AI service. Please try again."), findsOneWidget);
    });

    testWidgets('?q= is asked on arrival, as V2\'s landing hands it over', (tester) async {
        await pumpApp(tester, location: '/ai-chat?q=${Uri.encodeComponent('Hotels in Seoul')}');

        expect(api.sent.single['message'], 'Hotels in Seoul');
        expect(find.text(api.reply), findsOneWidget);
    });

    testWidgets('a conversation is kept under V2\'s key and listed under Today', (tester) async {
        await pumpApp(tester, location: '/ai-chat');
        await tapVisible(tester, 'Find me cheap flights to Tokyo next month');
        await tester.pumpAndSettle();

        final saved = await stored();
        expect(saved, hasLength(1));
        expect(saved.single['title'], 'Find me cheap flights to Tokyo next month');
        expect(saved.single['messages'], [
            {'role': 'user', 'content': 'Find me cheap flights to Tokyo next month'},
            {'role': 'assistant', 'content': api.reply},
        ]);

        // The title appears in the history as well as in the thread.
        expect(find.text('TODAY'), findsOneWidget);
        expect(find.text('Find me cheap flights to Tokyo next month'), findsNWidgets(2));
    });

    testWidgets('New chat starts over, and the history brings the last one back', (tester) async {
        await pumpApp(tester, location: '/ai-chat');
        await tapVisible(tester, 'Find me cheap flights to Tokyo next month');
        await tester.pumpAndSettle();
        final firstId = api.sent.single['conversationId'];

        await tester.tap(find.text('New chat'));
        await tester.pumpAndSettle();
        expect(find.text("What's on the agenda today?"), findsOneWidget);

        await tapVisible(tester, 'Plan a 5-day trip to Paris on a budget');
        await tester.pumpAndSettle();
        expect(api.sent.last['conversationId'], isNot(firstId), reason: 'a new chat is a new session');
        expect(await stored(), hasLength(2));

        await tester.tap(find.byKey(ValueKey('aiChat.conversation.$firstId')));
        await tester.pumpAndSettle();
        expect(find.text('Plan a 5-day trip to Paris on a budget'), findsOneWidget, reason: 'only in the history now');
        expect(find.text('Find me cheap flights to Tokyo next month'), findsNWidgets(2));
    });

    testWidgets('the history from an earlier visit is there on arrival, grouped by age', (tester) async {
        final now = DateTime.now().millisecondsSinceEpoch;
        Map<String, dynamic> convo(String id, String title, int ageHours) => {
            'id': id,
            'title': title,
            'messages': [{'role': 'user', 'content': title}],
            'createdAt': now - ageHours * 3600000,
        };
        SharedPreferences.setMockInitialValues({
            ConversationStore.storageKey: jsonEncode([
                convo('a', 'Fresh one', 1),
                convo('b', 'From yesterday', 30),
                convo('c', 'Ancient', 24 * 7),
            ]),
        });

        await pumpApp(tester, location: '/ai-chat');

        expect(find.text('TODAY'), findsOneWidget);
        expect(find.text('YESTERDAY'), findsOneWidget);
        expect(find.text('OLDER'), findsOneWidget);
        expect(find.text('Fresh one'), findsOneWidget);
        expect(find.text('From yesterday'), findsOneWidget);
        expect(find.text('Ancient'), findsOneWidget);
    });

    testWidgets('the language picked is the language asked for', (tester) async {
        await pumpApp(tester, location: '/ai-chat');

        await tester.tap(find.text('English'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('aiChat.lang.ja')));
        await tester.pumpAndSettle();
        expect(find.text('日本語'), findsOneWidget);

        await tapVisible(tester, 'Find me cheap flights to Tokyo next month');
        await tester.pumpAndSettle();
        expect(api.sent.single['lang'], 'ja');
    });

    testWidgets('closing the sidebar moves New chat into the topbar', (tester) async {
        await pumpApp(tester, location: '/ai-chat');
        expect(find.byKey(const Key('aiChat.topbarNewChat')), findsNothing);

        await tester.tap(find.byTooltip('Close sidebar'));
        await tester.pumpAndSettle();

        expect(tester.getSize(find.byKey(const Key('aiChat.sidebar'))).width, 0);
        expect(find.byKey(const Key('aiChat.topbarNewChat')), findsOneWidget);
        expect(find.byTooltip('Open sidebar'), findsOneWidget);
    });

    testWidgets('Home leaves for the landing, bar and all', (tester) async {
        await pumpApp(tester, location: '/ai-chat');
        await tester.tap(find.byTooltip('Go to home'));
        await tester.pumpAndSettle();
        expect(find.byType(V2BottomNav), findsOneWidget);
    });

    testWidgets('dark, with a long thread, lays out at phone width', (tester) async {
        api.reply = 'A long answer. ' * 40;
        await pumpApp(tester, location: '/ai-chat', theme: AppTheme.dark);
        await tapVisible(tester, 'Plan a 5-day trip to Paris on a budget');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
    });

    group('conversations', () {
        test('groupByDate counts days back from now, as V2 does', () {
            const now = 10 * 86400000;
            Conversation at(int ms) => Conversation(id: '$ms', title: '', messages: const [], createdAt: ms);
            final g = groupByDate([at(now - 1), at(now - 86400000), at(now - 2 * 86400000)], now);
            expect(g.today.single.createdAt, now - 1);
            expect(g.yesterday.single.createdAt, now - 86400000);
            expect(g.older.single.createdAt, now - 2 * 86400000);
        });

        test('the title is the first question, cut at sixty', () {
            final long = 'x' * 80;
            expect(conversationTitle([ChatMessage.user(long)]), 'x' * 60);
            expect(conversationTitle(const []), 'New chat');
        });

        test('fifty are kept, newest first', () async {
            final list = [
                for (var i = 0; i < 55; i++)
                    Conversation(id: '$i', title: '$i', messages: const [], createdAt: i),
            ];
            await conversationStore.save(list);
            final back = await conversationStore.load();
            expect(back, hasLength(50));
            expect(back.first.id, '0');
        });

        test('an unreadable store is an empty history', () async {
            SharedPreferences.setMockInitialValues({ConversationStore.storageKey: 'not json'});
            expect(await conversationStore.load(), isEmpty);
        });
    });
}
