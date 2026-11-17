import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:cheapest_go_mobile/features/ai_chat/api/chat_api.dart';
import 'package:cheapest_go_mobile/features/ai_chat/lib/conversations.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/generated/tw_palette.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/generated/v2_roles.dart';

/// V2's `/ai-chat` at its phone size. See `features/chat/components/AiChatClient.tsx`.
///
/// The whole screen to itself: V2 hides its bottom bar here, so the route sits outside the tab
/// shell. A history sidebar on the left — open on arrival, as V2's is at every width — and the
/// conversation beside it: a topbar, the messages or the four starter prompts, and the input.
///
/// A reply arrives whole. api-v2's `/chat` answers once ChatWonder has finished, and V2 shows a
/// spinner bubble until then; this does the same rather than invent a stream the server does
/// not send.
///
/// `?q=` sends its question on arrival, which is how V2's landing and search hand one over.
class AiChatView extends StatefulWidget {
    const AiChatView({this.initialQuery, this.api, this.store, this.now, super.key});

    final String? initialQuery;
    final ChatApi? api;
    final ConversationStore? store;

    /// For tests: what "now" is when grouping the history.
    final DateTime Function()? now;

    @override
    State<AiChatView> createState() => _AiChatViewState();
}

/// V2's language list, by its own labels. Not translated there either: each names itself.
const _languages = <(String, String)>[
    ('en', 'English'),
    ('tl', 'Tagalog'),
    ('ceb', 'Cebuano'),
    ('ilo', 'Ilokano'),
    ('es', 'Español'),
    ('ja', '日本語'),
    ('ko', '한국어'),
    ('zh', '中文'),
];

/// V2 writes these in English in every locale — they are not in its translations, so they are
/// not in ours. Mirrored as written; a translation belongs in V2 first.
const _today = 'Today';
const _yesterday = 'Yesterday';
const _older = 'Older';
const _closeSidebar = 'Close sidebar';
const _openSidebar = 'Open sidebar';
const _unreachable = "Sorry, I couldn't reach the AI service. Please try again.";

/// V2's `useBrandName()` on this app's deployment.
const _brand = 'CheapestGo';

/// Tailwind's default transition, `cubic-bezier(0.4, 0, 0.2, 1)`.
const _ease = Curves.fastOutSlowIn;

class _AiChatViewState extends State<AiChatView> {
    late final ChatApi _api = widget.api ?? chatApi;
    late final ConversationStore _store = widget.store ?? conversationStore;

    final _input = TextEditingController();
    final _focus = FocusNode();
    final _scroll = ScrollController();

    List<Conversation> _conversations = const [];
    List<ChatMessage> _messages = const [];
    bool _loading = false;
    String _lang = 'en';
    bool _sidebarOpen = true;
    bool _langOpen = false;
    String _conversationId = newConversationId();

    DateTime _now() => widget.now?.call() ?? DateTime.now();

    @override
    void initState() {
        super.initState();
        _start();
    }

    /// History first, then the handed-over question — V2's effects run in that order, so a
    /// `?q=` conversation joins the list rather than replacing it.
    Future<void> _start() async {
        final loaded = await _store.load();
        if (!mounted) return;
        setState(() => _conversations = loaded);
        final q = widget.initialQuery;
        if (q != null && q.isNotEmpty) _send(q);
    }

    @override
    void dispose() {
        _input.dispose();
        _focus.dispose();
        _scroll.dispose();
        super.dispose();
    }

    /// Every change to the messages is written through, as V2's effect does.
    void _setMessages(List<ChatMessage> next) {
        setState(() => _messages = next);
        if (next.isNotEmpty) {
            final i = _conversations.indexWhere((c) => c.id == _conversationId);
            final updated = Conversation(
                id: _conversationId,
                title: conversationTitle(next),
                messages: next,
                createdAt: i >= 0 ? _conversations[i].createdAt : _now().millisecondsSinceEpoch,
            );
            final list = i >= 0
                ? [for (final c in _conversations) c.id == _conversationId ? updated : c]
                : [updated, ..._conversations];
            setState(() => _conversations = list);
            _store.save(list);
        }
        _scrollToEnd();
    }

    void _scrollToEnd() {
        WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_scroll.hasClients) return;
            _scroll.animateTo(
                _scroll.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
            );
        });
    }

    Future<void> _send(String text) async {
        final trimmed = text.trim();
        if (trimmed.isEmpty || _loading) return;

        _setMessages([..._messages, ChatMessage.user(trimmed)]);
        _input.clear();
        setState(() => _loading = true);
        _scrollToEnd();

        String reply;
        try {
            reply = await _api.send(message: trimmed, conversationId: _conversationId, lang: _lang);
        } catch (_) {
            reply = _unreachable;
        }
        if (!mounted) return;

        setState(() => _loading = false);
        _setMessages([..._messages, ChatMessage.assistant(reply)]);
        Future.delayed(const Duration(milliseconds: 50), () {
            if (mounted) _focus.requestFocus();
        });
    }

    void _newChat() {
        _setMessages(const []);
        _input.clear();
        setState(() => _conversationId = newConversationId());
        _focus.requestFocus();
    }

    void _loadConversation(Conversation c) {
        setState(() => _conversationId = c.id);
        _setMessages(c.messages);
        _input.clear();
    }

    @override
    Widget build(BuildContext context) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        final roles = dark ? V2Roles.dark : V2Roles.light;

        return Scaffold(
            backgroundColor: roles.background,
            body: SafeArea(
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                        _sidebar(context, dark),
                        Expanded(child: _main(context, dark)),
                    ],
                ),
            ),
        );
    }

    // ── Sidebar ─────────────────────────────────────────────────────────────────────────────

    Widget _sidebar(BuildContext context, bool dark) {
        final t = AppLocalizations.of(context)!;
        final groups = groupByDate(_conversations, _now().millisecondsSinceEpoch);
        final muted = dark ? TwPalette.slate300 : TwPalette.slate600;
        final currentLang = _languages.firstWhere((l) => l.$1 == _lang).$2;

        return AnimatedContainer(
            key: const Key('aiChat.sidebar'),
            duration: const Duration(milliseconds: 300),
            curve: _ease,
            width: _sidebarOpen ? 240 : 0,
            decoration: BoxDecoration(
                color: dark ? Colors.black.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.7),
                border: Border(
                    right: BorderSide(
                        color: dark ? Colors.white.withValues(alpha: 0.05) : TwPalette.slate200,
                    ),
                ),
            ),
            child: ClipRect(
                child: OverflowBox(
                    alignment: Alignment.centerLeft,
                    minWidth: 240,
                    maxWidth: 240,
                    child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Stack(
                            children: [
                                Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                        // Brand
                                        Padding(
                                            padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
                                            child: Row(
                                                children: [
                                                    _sparkleTile(28, 13),
                                                    const SizedBox(width: 8),
                                                    Flexible(
                                                        child: Text(
                                                            '$_brand AI',
                                                            overflow: TextOverflow.ellipsis,
                                                            style: TextStyle(
                                                                fontSize: 14,
                                                                fontWeight: FontWeight.w700,
                                                                color: dark ? Colors.white : TwPalette.slate900,
                                                            ),
                                                        ),
                                                    ),
                                                ],
                                            ),
                                        ),
                                        const SizedBox(height: 8),

                                        // New chat
                                        _sidebarButton(
                                            icon: LucideIcons.plus,
                                            iconSize: 15,
                                            label: t.ai_newChat,
                                            color: muted,
                                            dark: dark,
                                            onTap: _newChat,
                                        ),
                                        const SizedBox(height: 12),

                                        // Conversation history
                                        Expanded(
                                            child: ListView(
                                                padding: EdgeInsets.zero,
                                                children: [
                                                    ..._group(_today, groups.today, dark),
                                                    ..._group(_yesterday, groups.yesterday, dark),
                                                    ..._group(_older, groups.older, dark),
                                                ],
                                            ),
                                        ),

                                        // Language
                                        Container(
                                            padding: const EdgeInsets.only(top: 8),
                                            decoration: BoxDecoration(
                                                border: Border(
                                                    top: BorderSide(
                                                        color: dark
                                                            ? Colors.white.withValues(alpha: 0.05)
                                                            : TwPalette.slate100,
                                                    ),
                                                ),
                                            ),
                                            child: _sidebarButton(
                                                icon: LucideIcons.globe,
                                                iconSize: 14,
                                                label: currentLang,
                                                color: muted,
                                                dark: dark,
                                                onTap: () => setState(() => _langOpen = !_langOpen),
                                            ),
                                        ),
                                    ],
                                ),
                                if (_langOpen)
                                    Positioned(
                                        left: 0,
                                        right: 0,
                                        bottom: 40,
                                        child: _languageMenu(dark),
                                    ),
                            ],
                        ),
                    ),
                ),
            ),
        );
    }

    Widget _sidebarButton({
        required IconData icon,
        required double iconSize,
        required String label,
        required Color color,
        required bool dark,
        required VoidCallback onTap,
    }) {
        return Material(
            type: MaterialType.transparency,
            child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                hoverColor: dark ? Colors.white.withValues(alpha: 0.1) : TwPalette.slate100,
                child: SizedBox(
                    height: 36,
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                            children: [
                                Icon(icon, size: iconSize, color: color),
                                const SizedBox(width: 8),
                                Flexible(
                                    child: Text(
                                        label,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color),
                                    ),
                                ),
                            ],
                        ),
                    ),
                ),
            ),
        );
    }

    List<Widget> _group(String label, List<Conversation> items, bool dark) {
        if (items.isEmpty) return const [];
        return [
            Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                child: Text(
                    label.toUpperCase(),
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: dark ? TwPalette.slate500 : TwPalette.slate400,
                    ),
                ),
            ),
            for (final c in items) _conversationRow(c, dark),
            const SizedBox(height: 12),
        ];
    }

    Widget _conversationRow(Conversation c, bool dark) {
        final current = c.id == _conversationId;
        final color = current
            ? (dark ? TwPalette.blue300 : TwPalette.blue700)
            : (dark ? TwPalette.slate400 : TwPalette.slate600);
        return Material(
            type: MaterialType.transparency,
            child: InkWell(
                key: ValueKey('aiChat.conversation.${c.id}'),
                onTap: () => _loadConversation(c),
                borderRadius: BorderRadius.circular(12),
                child: Ink(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                        color: current
                            ? (dark ? TwPalette.blue900.withValues(alpha: 0.2) : TwPalette.blue50)
                            : null,
                        borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                        children: [
                            Opacity(
                                opacity: 0.5,
                                child: Icon(LucideIcons.messageSquare, size: 12, color: color),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(
                                    c.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: current ? FontWeight.w500 : FontWeight.w400,
                                        color: color,
                                    ),
                                ),
                            ),
                        ],
                    ),
                ),
            ),
        );
    }

    Widget _languageMenu(bool dark) {
        return Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
                color: dark ? TwPalette.slate900 : Colors.white,
                border: Border.all(color: dark ? Colors.white.withValues(alpha: 0.1) : TwPalette.slate200),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                    BoxShadow(color: Color(0x1A000000), blurRadius: 15, offset: Offset(0, 10), spreadRadius: -3),
                    BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 4), spreadRadius: -4),
                ],
            ),
            child: Material(
                type: MaterialType.transparency,
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                        for (final (code, label) in _languages)
                            InkWell(
                                key: ValueKey('aiChat.lang.$code'),
                                onTap: () => setState(() {
                                    _lang = code;
                                    _langOpen = false;
                                }),
                                child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    color: code == _lang
                                        ? (dark ? TwPalette.blue900.withValues(alpha: 0.3) : TwPalette.blue50)
                                        : null,
                                    child: Text(
                                        label,
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: code == _lang ? FontWeight.w500 : FontWeight.w400,
                                            color: code == _lang
                                                ? (dark ? TwPalette.blue400 : TwPalette.blue600)
                                                : (dark ? TwPalette.slate300 : TwPalette.slate700),
                                        ),
                                    ),
                                ),
                            ),
                    ],
                ),
            ),
        );
    }

    // ── Main ────────────────────────────────────────────────────────────────────────────────

    Widget _main(BuildContext context, bool dark) {
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                _topbar(context, dark),
                Expanded(child: _messages.isEmpty ? _empty(context, dark) : _thread(dark)),
                _composer(context, dark),
            ],
        );
    }

    Widget _topbar(BuildContext context, bool dark) {
        final t = AppLocalizations.of(context)!;
        const iconColor = TwPalette.slate400;
        return SizedBox(
            height: 48,
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                    children: [
                        IconButton(
                            onPressed: () => setState(() => _sidebarOpen = !_sidebarOpen),
                            tooltip: _sidebarOpen ? _closeSidebar : _openSidebar,
                            constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                            padding: EdgeInsets.zero,
                            icon: Icon(
                                _sidebarOpen ? LucideIcons.panelLeftClose : LucideIcons.panelLeft,
                                size: 18,
                                color: iconColor,
                            ),
                        ),
                        if (!_sidebarOpen) ...[
                            const SizedBox(width: 12),
                            Flexible(
                                child: InkWell(
                                    key: const Key('aiChat.topbarNewChat'),
                                    onTap: _newChat,
                                    // One run of text, so it clips cleanly while the sidebar is
                                    // still sliding shut and the room for it is a few pixels.
                                    child: ConstrainedBox(
                                        constraints: const BoxConstraints(minHeight: 36),
                                        child: Align(
                                            alignment: Alignment.centerLeft,
                                            widthFactor: 1,
                                            child: Text.rich(
                                                TextSpan(children: [
                                                    const WidgetSpan(
                                                        alignment: PlaceholderAlignment.middle,
                                                        child: Padding(
                                                            padding: EdgeInsets.only(right: 6),
                                                            child: Icon(LucideIcons.plus, size: 15, color: iconColor),
                                                        ),
                                                    ),
                                                    TextSpan(text: t.ai_newChat),
                                                ]),
                                                maxLines: 1,
                                                overflow: TextOverflow.clip,
                                                style: const TextStyle(fontSize: 14, color: iconColor),
                                            ),
                                        ),
                                    ),
                                ),
                            ),
                        ],
                        const Spacer(),
                        IconButton(
                            onPressed: () => context.go('/'),
                            tooltip: t.ai_goHome,
                            constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                            padding: EdgeInsets.zero,
                            icon: const Icon(LucideIcons.house, size: 18, color: iconColor),
                        ),
                    ],
                ),
            ),
        );
    }

    Widget _empty(BuildContext context, bool dark) {
        final t = AppLocalizations.of(context)!;
        final suggestions = [t.ai_suggestions_1, t.ai_suggestions_2, t.ai_suggestions_3, t.ai_suggestions_4];

        return LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: box.maxHeight),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            Text(
                                t.ai_greeting,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 24,
                                    height: 1.333,
                                    fontWeight: FontWeight.w700,
                                    color: dark ? Colors.white : TwPalette.slate800,
                                ),
                            ),
                            const SizedBox(height: 32),
                            ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 576),
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                        for (final (i, s) in suggestions.indexed) ...[
                                            if (i > 0) const SizedBox(height: 8),
                                            _suggestion(s, dark),
                                        ],
                                    ],
                                ),
                            ),
                        ],
                    ),
                ),
            ),
        );
    }

    Widget _suggestion(String text, bool dark) {
        return Material(
            type: MaterialType.transparency,
            child: InkWell(
                onTap: () => _send(text),
                borderRadius: BorderRadius.circular(12),
                child: Ink(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                        color: dark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.6),
                        border: Border.all(color: dark ? Colors.white.withValues(alpha: 0.1) : TwPalette.slate200),
                        borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                        text,
                        textAlign: TextAlign.left,
                        style: TextStyle(fontSize: 14, height: 1.43, color: dark ? TwPalette.slate300 : TwPalette.slate600),
                    ),
                ),
            ),
        );
    }

    Widget _thread(bool dark) {
        return ListView(
            controller: _scroll,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            children: [
                for (final (i, m) in _messages.indexed) ...[
                    if (i > 0) const SizedBox(height: 24),
                    _bubble(m, dark),
                ],
                if (_loading) ...[
                    if (_messages.isNotEmpty) const SizedBox(height: 24),
                    _thinking(dark),
                ],
            ],
        );
    }

    Widget _sparkleTile(double size, double icon, {bool softShadow = false}) {
        return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
                color: TwPalette.blue600,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                    BoxShadow(
                        color: TwPalette.blue600.withValues(alpha: softShadow ? 0.2 : 0.3),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                    ),
                ],
            ),
            child: Icon(LucideIcons.sparkles, size: icon, color: Colors.white),
        );
    }

    BoxDecoration _assistantSurface(bool dark) => BoxDecoration(
        color: dark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.7),
        border: Border.all(color: dark ? Colors.white.withValues(alpha: 0.1) : TwPalette.slate200),
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
        ),
    );

    Widget _bubble(ChatMessage m, bool dark) {
        final user = m.role == ChatRole.user;
        return LayoutBuilder(
            builder: (context, box) => Row(
                mainAxisAlignment: user ? MainAxisAlignment.end : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    if (!user) ...[
                        Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: _sparkleTile(28, 12, softShadow: true),
                        ),
                        const SizedBox(width: 12),
                    ],
                    // `max-w-[82%]` of the row, and still free to shrink beside the avatar the
                    // way a flex item does when the sidebar leaves the thread narrow.
                    Flexible(
                        child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: box.maxWidth * 0.82),
                        child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: user
                                ? BoxDecoration(
                                    color: TwPalette.blue600,
                                    borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        topRight: Radius.circular(16),
                                        bottomLeft: Radius.circular(16),
                                        bottomRight: Radius.circular(4),
                                    ),
                                    boxShadow: [
                                        BoxShadow(
                                            color: TwPalette.blue600.withValues(alpha: 0.15),
                                            blurRadius: 6,
                                            offset: const Offset(0, 4),
                                            spreadRadius: -1,
                                        ),
                                    ],
                                )
                                : _assistantSurface(dark),
                            child: Text(
                                m.content,
                                style: TextStyle(
                                    fontSize: 14,
                                    height: 1.625,
                                    color: user
                                        ? Colors.white
                                        : (dark ? TwPalette.slate100 : TwPalette.slate800),
                                ),
                            ),
                        ),
                        ),
                    ),
                ],
            ),
        );
    }

    Widget _thinking(bool dark) {
        return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: _sparkleTile(28, 12, softShadow: true),
                ),
                const SizedBox(width: 12),
                Container(
                    key: const Key('aiChat.thinking'),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: _assistantSurface(dark),
                    child: const _Spinner(),
                ),
            ],
        );
    }

    Widget _composer(BuildContext context, bool dark) {
        final t = AppLocalizations.of(context)!;
        return Center(
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 672),
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                            ListenableBuilder(
                                listenable: Listenable.merge([_input, _focus]),
                                builder: (context, _) {
                                    final focused = _focus.hasFocus;
                                    final canSend = _input.text.trim().isNotEmpty && !_loading;
                                    return AnimatedContainer(
                                        duration: const Duration(milliseconds: 150),
                                        curve: _ease,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                            color: dark
                                                ? Colors.white.withValues(alpha: 0.05)
                                                : Colors.white.withValues(alpha: 0.7),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                                color: focused
                                                    ? (dark ? TwPalette.blue500 : TwPalette.blue400)
                                                    : (dark ? Colors.white.withValues(alpha: 0.1) : TwPalette.slate200),
                                            ),
                                            boxShadow: [
                                                if (focused)
                                                    BoxShadow(
                                                        color: TwPalette.blue500.withValues(alpha: 0.1),
                                                        spreadRadius: 2,
                                                    ),
                                                const BoxShadow(
                                                    color: Color(0x0D000000),
                                                    blurRadius: 2,
                                                    offset: Offset(0, 1),
                                                ),
                                            ],
                                        ),
                                        child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                                Expanded(
                                                    child: TextField(
                                                        key: const Key('aiChat.input'),
                                                        controller: _input,
                                                        focusNode: _focus,
                                                        minLines: 1,
                                                        // `max-h-40`: about seven lines of text-sm.
                                                        maxLines: 7,
                                                        // V2's Enter sends; the keyboard's action key is
                                                        // a phone's Enter.
                                                        textInputAction: TextInputAction.send,
                                                        onSubmitted: _send,
                                                        style: TextStyle(
                                                            fontSize: 14,
                                                            height: 1.43,
                                                            color: dark ? Colors.white : TwPalette.slate900,
                                                        ),
                                                        decoration: InputDecoration(
                                                            isCollapsed: true,
                                                            border: InputBorder.none,
                                                            hintText: t.ai_askAnything,
                                                            hintStyle: const TextStyle(
                                                                fontSize: 14,
                                                                color: TwPalette.slate400,
                                                            ),
                                                        ),
                                                    ),
                                                ),
                                                const SizedBox(width: 8),
                                                _sendButton(canSend),
                                            ],
                                        ),
                                    );
                                },
                            ),
                            const SizedBox(height: 8),
                            Text(
                                t.ai_sendHint,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 10, color: TwPalette.slate400),
                            ),
                        ],
                    ),
                ),
            ),
        );
    }

    Widget _sendButton(bool enabled) {
        return Opacity(
            opacity: enabled ? 1 : 0.3,
            child: Material(
                color: TwPalette.blue600,
                borderRadius: BorderRadius.circular(12),
                shadowColor: TwPalette.blue600.withValues(alpha: 0.2),
                elevation: 1,
                child: InkWell(
                    key: const Key('aiChat.send'),
                    onTap: enabled ? () => _send(_input.text) : null,
                    borderRadius: BorderRadius.circular(12),
                    child: const SizedBox(
                        width: 32,
                        height: 32,
                        child: Icon(LucideIcons.send, size: 14, color: Colors.white),
                    ),
                ),
            ),
        );
    }
}

/// V2's `Loader2` with `animate-spin`: one turn a second, linear.
class _Spinner extends StatefulWidget {
    const _Spinner();

    @override
    State<_Spinner> createState() => _SpinnerState();
}

class _SpinnerState extends State<_Spinner> with SingleTickerProviderStateMixin {
    late final AnimationController _turn =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();

    @override
    void dispose() {
        _turn.dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        return RotationTransition(
            turns: _turn,
            child: const Icon(LucideIcons.loaderCircle, size: 15, color: TwPalette.slate400),
        );
    }
}
