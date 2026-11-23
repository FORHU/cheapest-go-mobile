import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cheapest_go_mobile/app/theme/app_theme.dart';
import 'package:cheapest_go_mobile/features/support/api/support_api.dart';
import 'package:cheapest_go_mobile/features/support/components/support_widget.dart';
import 'package:cheapest_go_mobile/features/support/lib/support_stream.dart';
import 'package:cheapest_go_mobile/features/support/models/support_models.dart';
import 'package:cheapest_go_mobile/features/support/stores/support_chat_store.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/errors/api_error.dart';
import 'package:cheapest_go_mobile/shared/lib/http.dart';

/// Support Chat at parity with V2 (#60): the store against a fake api-v2, the stream reader
/// against fake frames, and the launcher and panel as a customer meets them.
final _t = lookupAppLocalizations(const Locale('en'));

const _chat = SupportConversation(
    id: 'c1', reference: 'CHAT-7Q2', status: 'open', locale: 'en', createdAt: 't0', updatedAt: 't0');

class _FakeApi extends SupportApi {
    _FakeApi({this.transcript, this.available = true, this.attachments = true});

    SupportTranscript? transcript;
    bool available;
    bool attachments;
    bool failSend = false;
    final sent = <(String, List<String>)>[];
    final uploaded = <String>[];
    final reports = <(String, String)>[];
    int opened = 0;
    final streams = <StreamController<String>>[];

    @override
    Future<SupportAvailability> availability() async => SupportAvailability(
        humanAvailable: available,
        attachments: attachments,
        nextOpening: const SupportOpening(day: 'mon', open: '09:00', timezone: 'Asia/Manila', today: false),
    );

    @override
    Future<SupportTranscript?> conversation() async => transcript;

    @override
    Future<SupportConversation> openConversation(String locale) async {
        opened += 1;
        transcript ??= const SupportTranscript(_chat, []);
        return _chat;
    }

    @override
    Future<SupportMessage> send(String conversationId, String body, [List<String> attachmentIds = const []]) async {
        if (failSend) throw ApiError('down', status: 502);
        sent.add((body, attachmentIds));
        return SupportMessage(id: 'm${sent.length}', senderType: 'guest', body: body, createdAt: '2026-01-01T00:00:0${sent.length}Z');
    }

    @override
    Future<SupportAttachment> upload(String conversationId, String fileName, List<int> bytes) async {
        uploaded.add(fileName);
        return SupportAttachment(id: 'f${uploaded.length}', fileName: fileName);
    }

    @override
    Future<void> reportSuggestion(String articleId, String outcome, String locale) async => reports.add((articleId, outcome));

    @override
    Future<EventLines> openStream() async {
        final c = StreamController<String>();
        streams.add(c);
        return EventLines(c.stream, () => c.close());
    }
}

SupportChatStore _store(_FakeApi api, {bool pick = true}) => SupportChatStore(
    api: api,
    locale: () => 'en',
    pickFile: pick ? () async => const PickedSupportFile('passport.pdf', [1, 2, 3]) : null,
    openUrl: (_) async {},
);

Future<void> _pump(WidgetTester tester, SupportChatStore store, {bool visible = true}) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(body: Stack(children: [SupportWidget(store: store, visible: visible)])),
    ));
    await tester.pumpAndSettle();
}

void main() {
    group('SupportChatStore', () {
        test('looking does not create a chat; the first message does', () async {
            final api = _FakeApi();
            final store = _store(api)..setEnabled(true);
            addTearDown(store.dispose);

            await store.open();
            expect(api.opened, 0, reason: 'ADR-0044: opening the panel only reads');

            await store.send('Where is my voucher?');
            expect(api.opened, 1);
            expect(api.sent.single.$1, 'Where is my voucher?');
            expect(store.messages.single.id, 'm1');
            expect(store.conversation?.reference, 'CHAT-7Q2');
        });

        test('an attachment uploads before the message and goes with it', () async {
            final api = _FakeApi();
            final store = _store(api)..setEnabled(true);
            addTearDown(store.dispose);
            await Future<void>.delayed(Duration.zero);

            expect(store.canAttach, isTrue);
            await store.attach();
            expect(store.staged.single.fileName, 'passport.pdf');

            await store.send('Here it is');
            expect(api.sent.single.$2, ['f1']);
            expect(store.staged, isEmpty);
        });

        test('a failed send says so and keeps the staged files to retry', () async {
            final api = _FakeApi()..failSend = true;
            final store = _store(api)..setEnabled(true);
            addTearDown(store.dispose);
            await store.attach();

            await store.send('hello');
            expect(store.failed, isTrue);
            expect(store.messages, isEmpty);
            expect(store.staged, hasLength(1));
        });

        test('no paperclip when the API has no bucket', () async {
            final store = _store(_FakeApi(attachments: false))..setEnabled(true);
            addTearDown(store.dispose);
            await Future<void>.delayed(Duration.zero);
            expect(store.canAttach, isFalse);
        });

        test('a stream event refetches, and a reply that arrived while closed raises the badge', () async {
            final api = _FakeApi(transcript: const SupportTranscript(_chat, []));
            final store = _store(api)..setEnabled(true);
            addTearDown(store.dispose);
            await store.open();
            store.close();
            await Future<void>.delayed(Duration.zero);
            expect(api.streams, hasLength(1), reason: 'the stream opens once a conversation exists');

            api.transcript = SupportTranscript(_chat, [
                const SupportMessage(id: 'a1', senderType: 'agent', body: 'Hi, Mina here', createdAt: '2026-01-01T00:00:09Z'),
            ]);
            api.streams.single
                ..add('event: support')
                ..add('data: {"messageId":"a1"}')
                ..add('');
            await Future<void>.delayed(const Duration(milliseconds: 10));

            expect(store.unread, 1);
            expect(store.messages.single.body, 'Hi, Mina here');
        });

        test('signing out forgets the chat and hangs up', () async {
            final api = _FakeApi(transcript: const SupportTranscript(_chat, []));
            final store = _store(api)..setEnabled(true);
            addTearDown(store.dispose);
            await store.open();
            await store.send('mine');

            store.setEnabled(false);
            expect(store.conversation, isNull);
            expect(store.messages, isEmpty);
            expect(store.panelOpen, isFalse);
        });
    });

    group('SupportStream', () {
        test('reports support and open frames, ignores keep-alives, and reconnects when dropped', () async {
            final conns = <StreamController<String>>[];
            var changes = 0;
            final stream = SupportStream(
                connect: () async {
                    final c = StreamController<String>();
                    conns.add(c);
                    return EventLines(c.stream, () {});
                },
                onChange: () => changes++,
                minBackoff: const Duration(milliseconds: 5),
            )..start();
            addTearDown(stream.stop);
            await Future<void>.delayed(Duration.zero);

            conns.single
                ..add('event: open')..add('data: {}')..add('')
                ..add(': keep-alive')..add('')
                ..add('event: support')..add('data: {}')..add('');
            await Future<void>.delayed(Duration.zero);
            expect(changes, 2);

            await conns.single.close();
            await Future<void>.delayed(const Duration(milliseconds: 30));
            expect(conns, hasLength(2), reason: 'a dropped stream dials again');
        });

        test('stops for good on 401', () async {
            var calls = 0;
            final stream = SupportStream(
                connect: () async {
                    calls++;
                    throw ApiError('no', status: 401);
                },
                onChange: () {},
                minBackoff: const Duration(milliseconds: 5),
            )..start();
            await Future<void>.delayed(const Duration(milliseconds: 30));
            expect(calls, 1);
            expect(stream.running, isFalse);
        });
    });

    group('SupportWidget', () {
        testWidgets('nothing is drawn for an account that cannot use it, or under a sheet', (tester) async {
            final store = _store(_FakeApi());
            addTearDown(store.dispose);
            await _pump(tester, store);
            expect(find.byKey(const ValueKey('support-launcher')), findsNothing);

            store.setEnabled(true);
            await _pump(tester, store, visible: false);
            expect(find.byKey(const ValueKey('support-launcher')), findsNothing);
        });

        testWidgets('the launcher opens the panel on the common questions, with the desk hours', (tester) async {
            final store = _store(_FakeApi(available: false))..setEnabled(true);
            addTearDown(store.dispose);
            await _pump(tester, store);

            await tester.tap(find.byKey(const ValueKey('support-launcher')));
            await tester.pumpAndSettle();

            expect(find.text(_t.support_title), findsOneWidget);
            expect(find.text(_t.support_empty), findsOneWidget);
            expect(find.text(_t.support_quick_refunds), findsOneWidget);
            // A closed desk says so before anyone writes.
            expect(find.text(_t.support_reopens('Monday 9:00 AM (Asia/Manila)')), findsOneWidget);
        });

        testWidgets('a quick question answers from the Help Centre without starting a chat', (tester) async {
            final api = _FakeApi();
            final store = _store(api)..setEnabled(true);
            addTearDown(store.dispose);
            await _pump(tester, store);
            await tester.tap(find.byKey(const ValueKey('support-launcher')));
            await tester.pumpAndSettle();

            await tester.tap(find.text(_t.support_quick_refunds));
            await tester.pumpAndSettle();
            expect(find.text(_t.help_sections_refunds_title), findsOneWidget);
            expect(api.reports.single, ('refunds', 'opened'));

            await tester.ensureVisible(find.text(_t.support_thatAnsweredIt));
            await tester.pumpAndSettle();
            await tester.tap(find.text(_t.support_thatAnsweredIt));
            await tester.pumpAndSettle();
            expect(api.reports.last, ('refunds', 'solved'));
            expect(api.opened, 0);
        });

        testWidgets('a payment problem goes straight to a person', (tester) async {
            final api = _FakeApi();
            final store = _store(api)..setEnabled(true);
            addTearDown(store.dispose);
            await _pump(tester, store);
            await tester.tap(find.byKey(const ValueKey('support-launcher')));
            await tester.pumpAndSettle();

            await tester.tap(find.text(_t.support_quick_payment));
            await tester.pumpAndSettle();
            expect(api.sent.single.$1, _t.support_quick_payment);
            expect(find.text(_t.support_reference('CHAT-7Q2')), findsOneWidget);
        });

        testWidgets('typing and sending puts the message in the transcript', (tester) async {
            final api = _FakeApi();
            final store = _store(api)..setEnabled(true);
            addTearDown(store.dispose);
            await _pump(tester, store);
            await tester.tap(find.byKey(const ValueKey('support-launcher')));
            await tester.pumpAndSettle();

            await tester.enterText(find.byType(TextField), 'My booking is missing');
            await tester.pump();
            await tester.tap(find.byTooltip(_t.support_send));
            await tester.pumpAndSettle();

            expect(api.sent.single.$1, 'My booking is missing');
            expect(find.text('My booking is missing'), findsOneWidget);
        });

        testWidgets('an untranslated reply says so; a translated one offers the original', (tester) async {
            final api = _FakeApi(transcript: const SupportTranscript(_chat, [
                SupportMessage(id: 'a1', senderType: 'agent', body: 'We refunded you', createdAt: '2026-01-01T00:00:01Z',
                    translationStatus: TranslationStatus.untranslated, translatedLang: 'ko'),
                SupportMessage(id: 'a2', senderType: 'agent', body: 'Anything else?', createdAt: '2026-01-01T00:00:02Z',
                    translationStatus: TranslationStatus.translated, translatedLang: 'ko', translatedBody: '다른 문의 있으세요?'),
            ]));
            final store = _store(api)..setEnabled(true);
            addTearDown(store.dispose);
            await _pump(tester, store);
            await tester.tap(find.byKey(const ValueKey('support-launcher')));
            await tester.pumpAndSettle();

            expect(find.text(_t.support_notTranslated), findsOneWidget);
            expect(find.text('다른 문의 있으세요?'), findsOneWidget);

            await tester.tap(find.text(_t.support_showOriginal));
            await tester.pumpAndSettle();
            expect(find.text('Anything else?'), findsOneWidget);
        });

        testWidgets('the unread badge shows on the closed launcher', (tester) async {
            final api = _FakeApi(transcript: const SupportTranscript(_chat, []));
            final store = _store(api)..setEnabled(true);
            addTearDown(store.dispose);
            await store.open();
            store.close();
            api.transcript = const SupportTranscript(_chat, [
                SupportMessage(id: 'a1', senderType: 'agent', body: 'Hi', createdAt: '2026-01-01T00:00:01Z'),
            ]);
            await store.refresh();
            await _pump(tester, store);
            expect(find.text('1'), findsOneWidget);
        });

        testWidgets('a draft another screen asked with lands in an empty box', (tester) async {
            final store = _store(_FakeApi())..setEnabled(true);
            addTearDown(store.dispose);
            await _pump(tester, store);

            store.requestOpen(draft: 'About tee times');
            await tester.pumpAndSettle();
            expect(find.widgetWithText(TextField, 'About tee times'), findsOneWidget);
        });
    });
}
