import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:cheapest_go_mobile/features/support/lib/reopen_time.dart';
import 'package:cheapest_go_mobile/features/support/lib/support_state.dart';
import 'package:cheapest_go_mobile/features/support/lib/translation_view.dart';
import 'package:cheapest_go_mobile/features/support/models/support_models.dart';

/// The parts of V2's Support Chat that are rules rather than screens (#60): the reducer that
/// copes with every message arriving more than once, which text a customer sees, and the
/// "back at" line. Each case mirrors one in V2's own tests.
const _chat = SupportConversation(
    id: 'c1', reference: 'CHAT-1', status: 'open', locale: 'ko', createdAt: 't0', updatedAt: 't0');

SupportMessage _msg(String id, {
    String sender = 'agent',
    String body = 'hello',
    String at = '2026-01-01T00:00:01Z',
    TranslationStatus? status,
    String? lang,
    String? translated,
}) =>
    SupportMessage(
        id: id, senderType: sender, body: body, createdAt: at,
        translationStatus: status, translatedLang: lang, translatedBody: translated);

void main() {
    setUpAll(() => initializeDateFormatting());

    group('SupportState — the same message, more than once', () {
        test("the customer's own message shows at once and is replaced, not doubled, by the server's copy", () {
            var s = const SupportState().opened(_chat, const []).sent('x', 'hi', '2026-01-01T00:00:02Z');
            expect(s.visibleMessages.single.pending, isTrue);

            s = s.confirmedSend('x', _msg('m1', sender: 'guest', body: 'hi', at: '2026-01-01T00:00:02Z'));
            expect(s.visibleMessages.map((m) => m.id), ['m1']);
        });

        test('the stream beating the POST response still shows the message once', () {
            var s = const SupportState().opened(_chat, const []).sent('x', 'hi', '2026-01-01T00:00:02Z');
            s = s.received(_msg('m1', sender: 'guest', body: 'hi'));
            expect(s.visibleMessages.where((m) => m.body == 'hi'), hasLength(1));
        });

        test('a failed send takes the optimistic row away', () {
            final s = const SupportState().sent('x', 'hi', 't').sendFailed('x');
            expect(s.visibleMessages, isEmpty);
        });

        test('an older copy never replaces a newer one', () {
            var s = const SupportState().received(_msg('m1', status: TranslationStatus.translated, lang: 'ko', translated: '안녕'));
            s = s.received(_msg('m1', status: TranslationStatus.pending, lang: 'ko'));
            expect(s.confirmed.single.translationStatus, TranslationStatus.translated);
        });

        test('a reply is held while its translation for the customer is pending, then shown', () {
            var s = const SupportState().received(_msg('m1', status: TranslationStatus.pending, lang: 'ko'));
            expect(s.visibleMessages, isEmpty);
            expect(s.awaitingTranslation, isTrue);

            s = s.received(_msg('m1', status: TranslationStatus.translated, lang: 'ko', translated: '안녕'));
            expect(s.visibleMessages.single.id, 'm1');
            expect(s.awaitingTranslation, isFalse);
        });

        test("the customer's own message pending its English rendering is not held", () {
            final s = const SupportState().received(_msg('m1', sender: 'guest', status: TranslationStatus.pending, lang: 'en'));
            expect(s.visibleMessages.single.id, 'm1');
        });

        test('unread counts new replies while closed — not updates, not the customer, not while open', () {
            var s = const SupportState().received(_msg('a1'));
            expect(s.unread, 1);
            s = s.received(_msg('a1', status: TranslationStatus.translated, lang: 'ko', translated: 'x'));
            expect(s.unread, 1, reason: 'a translation landing is not a new message');
            s = s.received(_msg('g1', sender: 'guest'));
            expect(s.unread, 1);
            s = s.openedPanel();
            expect(s.unread, 0);
            s = s.received(_msg('a2'));
            expect(s.unread, 0);
        });

        test('rows are shown in the order written, not the order they arrived', () {
            final s = const SupportState()
                .received(_msg('b', at: '2026-01-01T00:00:05Z'))
                .received(_msg('a', at: '2026-01-01T00:00:01Z'));
            expect(s.visibleMessages.map((m) => m.id), ['a', 'b']);
        });
    });

    group('customerView — the translation language decides who it is for', () {
        test("an Agent's reply translated into Korean shows the Korean, with the original a tap away", () {
            final v = customerView(_msg('m', body: 'Hello', status: TranslationStatus.translated, lang: 'ko', translated: '안녕하세요'));
            expect(v.primary, '안녕하세요');
            expect(v.original, 'Hello');
            expect(v.label, ReaderLabel.translated);
        });

        test("the customer never sees the English rendering of their own words", () {
            final v = customerView(_msg('m', sender: 'guest', body: '환불', status: TranslationStatus.translated, lang: 'en', translated: 'refund'));
            expect(v.primary, '환불');
            expect(v.label, isNull);
        });

        test('a reply that could not be translated is shown as written, and says so', () {
            final v = customerView(_msg('m', body: 'Hello', status: TranslationStatus.untranslated, lang: 'ko'));
            expect(v.primary, 'Hello');
            expect(v.label, ReaderLabel.untranslated);
        });

        test('a system notice is shown as written', () {
            final v = customerView(_msg('m', sender: 'system', body: 'Chat closed', status: TranslationStatus.untranslated, lang: 'ko'));
            expect(v.label, isNull);
        });
    });

    group('formatReopen', () {
        test('names the weekday, the time and the timezone', () {
            final r = formatReopen(const SupportOpening(day: 'mon', open: '09:00', timezone: 'Asia/Manila', today: false), 'en')!;
            expect(r.today, isFalse);
            // intl, like the browser's Intl, puts a narrow no-break space before the meridiem.
            expect(r.when, 'Monday 9:00 AM (Asia/Manila)');
        });

        test('leaves the weekday out when it is later today', () {
            final r = formatReopen(const SupportOpening(day: 'mon', open: '13:30', timezone: 'Asia/Seoul', today: true), 'en')!;
            expect(r.today, isTrue);
            expect(r.when, '1:30 PM (Asia/Seoul)');
        });

        test('says nothing rather than something wrong', () {
            expect(formatReopen(null, 'en'), isNull);
            expect(formatReopen(const SupportOpening(day: 'mon', open: '9am', timezone: 'X', today: false), 'en'), isNull);
        });
    });
}
