/// The chat itself — V2's `SupportPanel`, `QuickQuestions`, `AutomatedAnswer`, `Bubble` and
/// `Attachment`, at the sizes and colours V2 draws them.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:cheapest_go_mobile/features/support/lib/quick_questions.dart';
import 'package:cheapest_go_mobile/features/support/lib/reopen_time.dart';
import 'package:cheapest_go_mobile/features/support/lib/translation_view.dart';
import 'package:cheapest_go_mobile/features/support/models/support_models.dart';
import 'package:cheapest_go_mobile/features/support/stores/support_chat_store.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/generated/tw_palette.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/generated/tw_scale.dart';

class _Tone {
  const _Tone(this.dark);

  final bool dark;

  Color get surface => dark ? TwPalette.slate900 : Colors.white;
  Color get border => dark ? Colors.white.withValues(alpha: 0.10) : TwPalette.slate200;
  Color get heading => dark ? Colors.white : TwPalette.slate900;
  Color get muted => dark ? TwPalette.slate400 : TwPalette.slate500;
  Color get faint => TwPalette.slate400;
}

TextStyle _text(TwFont font, Color color, {FontWeight weight = FontWeight.w400, FontStyle? style}) =>
    TextStyle(fontSize: font.size, height: font.height, color: color, fontWeight: weight, fontStyle: style);

class SupportPanel extends StatefulWidget {
  const SupportPanel({required this.store, super.key});

  final SupportChatStore store;

  @override
  State<SupportPanel> createState() => _SupportPanelState();
}

class _SupportPanelState extends State<SupportPanel> {
  final _draft = TextEditingController();
  final _box = FocusNode();
  final _scroll = ScrollController();
  QuickQuestion? _answer;
  int _shown = -1;
  bool _translating = false;

  SupportChatStore get _store => widget.store;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onStore);
    _takeDraft();
  }

  @override
  void dispose() {
    _store.removeListener(_onStore);
    _draft.dispose();
    _box.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onStore() {
    _takeDraft();
    // Follow the conversation as it grows, including when a held reply finally appears.
    final count = _store.messages.length;
    if (count != _shown || _store.translating != _translating) {
      _shown = count;
      _translating = _store.translating;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
      });
    }
  }

  /// A draft a screen asked with goes into an empty box, never over the customer's own words.
  void _takeDraft() {
    final offered = _store.takeDraft();
    if (offered == null) return;
    if (_draft.text.trim().isEmpty) _draft.text = offered;
    _box.requestFocus();
  }

  void _send() {
    final text = _draft.text;
    if (text.trim().isEmpty || _store.sending) return;
    _draft.clear();
    setState(() {});
    _store.send(text);
  }

  void _pick(QuickQuestion q, AppLocalizations t) {
    if (alwaysAPerson.contains(q)) {
      _store.reportSuggestion(q.articleId, 'sent_anyway');
      _store.send(q.chip(t));
      return;
    }
    _store.reportSuggestion(q.articleId, 'opened');
    setState(() => _answer = q);
  }

  /// Ends it with no chat in the queue, which is the point of answering it here.
  void _solved() {
    final q = _answer;
    if (q != null) _store.reportSuggestion(q.articleId, 'solved');
    setState(() => _answer = null);
  }

  /// Sends the question as the customer's own words, starting an ordinary chat.
  void _askAPerson(QuickQuestion q, AppLocalizations t) {
    _store.reportSuggestion(q.articleId, 'sent_anyway');
    setState(() => _answer = null);
    _store.send(q.chip(t));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final tone = _Tone(Theme.of(context).brightness == Brightness.dark);

    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final messages = _store.messages;
        final reference = _store.conversation?.reference;
        final availability = _store.availability;
        final reopen = availability != null && !availability.humanAvailable
            ? formatReopen(availability.nextOpening, Localizations.localeOf(context).languageCode)
            : null;

        return Semantics(
          label: t.support_title,
          container: true,
          child: Material(
            color: tone.surface,
            elevation: 0,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TwRadius.n2xl),
              side: BorderSide(color: tone.border),
            ),
            child: Column(
              children: [
                _Header(tone: tone, reference: reference, onClose: _store.close),
                if (reopen != null)
                  // Said before they write: someone messaging at 2am should know when an answer
                  // is coming rather than watching an empty chat.
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: TwSpace.of(4), vertical: TwSpace.of(2)),
                    decoration: BoxDecoration(
                      color: tone.dark ? TwPalette.amber950.withValues(alpha: 0.4) : TwPalette.amber50,
                      border: Border(
                        bottom: BorderSide(color: tone.dark ? TwPalette.amber900.withValues(alpha: 0.5) : TwPalette.amber200),
                      ),
                    ),
                    child: Text(
                      reopen.today ? t.support_reopensToday(reopen.when) : t.support_reopens(reopen.when),
                      style: _text(TwText.xs, tone.dark ? TwPalette.amber200 : TwPalette.amber900),
                    ),
                  ),
                Expanded(
                  child: ListView(
                    controller: _scroll,
                    padding: EdgeInsets.symmetric(horizontal: TwSpace.of(4), vertical: TwSpace.of(3)),
                    children: [
                      if (messages.isEmpty && _answer == null)
                        _QuickQuestions(tone: tone, onPick: (q) => _pick(q, t)),
                      if (_answer != null)
                        _AutomatedAnswer(
                          tone: tone,
                          question: _answer!,
                          onSolved: _solved,
                          onPerson: () => _askAPerson(_answer!, t),
                        ),
                      for (final m in messages)
                        Padding(
                          padding: EdgeInsets.only(bottom: TwSpace.of(3)),
                          child: _Bubble(key: ValueKey(m.id), message: m, tone: tone, onOpenFile: _store.openAttachment),
                        ),
                      if (_store.translating)
                        Text(t.support_translating, textAlign: TextAlign.center, style: _text(TwText.xs, tone.faint)),
                    ],
                  ),
                ),
                if (_store.failed)
                  Padding(
                    padding: EdgeInsets.fromLTRB(TwSpace.of(4), 0, TwSpace.of(4), TwSpace.of(1)),
                    child: Semantics(
                      liveRegion: true,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(t.support_sendFailed,
                            style: _text(TwText.xs, tone.dark ? TwPalette.rose400 : TwPalette.rose600)),
                      ),
                    ),
                  ),
                if (_store.staged.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.fromLTRB(TwSpace.of(3), 0, TwSpace.of(3), TwSpace.of(1)),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: TwSpace.of(1.5),
                        runSpacing: TwSpace.of(1.5),
                        children: [
                          for (final f in _store.staged) _StagedChip(tone: tone, file: f, onRemove: () => _store.unstage(f.id)),
                        ],
                      ),
                    ),
                  ),
                _Composer(
                  tone: tone,
                  controller: _draft,
                  focusNode: _box,
                  sending: _store.sending,
                  attaching: _store.attaching,
                  canAttach: _store.canAttach,
                  onAttach: _store.attach,
                  onSend: _send,
                  onChanged: () => setState(() {}),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.tone, required this.reference, required this.onClose});

  final _Tone tone;
  final String? reference;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.fromLTRB(TwSpace.of(4), TwSpace.of(3), TwSpace.of(2), TwSpace.of(3)),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: tone.border))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.support_title, style: _text(TwText.sm, tone.heading, weight: FontWeight.w600)),
                // The Chat Reference: what a customer quotes when they write in about the chat.
                if (reference != null && reference!.isNotEmpty)
                  Text(t.support_reference(reference!), style: _text(TwText.xs, tone.muted)),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            tooltip: t.support_close,
            visualDensity: VisualDensity.compact,
            icon: Icon(LucideIcons.x, size: 16, color: tone.faint),
          ),
        ],
      ),
    );
  }
}

/// The common questions, tappable, offered before anything is typed (ADR-0044).
class _QuickQuestions extends StatelessWidget {
  const _QuickQuestions({required this.tone, required this.onPick});

  final _Tone tone;
  final ValueChanged<QuickQuestion> onPick;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(top: TwSpace.of(4), bottom: TwSpace.of(3)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.support_empty, textAlign: TextAlign.center, style: _text(TwText.sm, tone.muted)),
          SizedBox(height: TwSpace.of(2)),
          for (final q in quickQuestions)
            Padding(
              padding: EdgeInsets.only(bottom: TwSpace.of(1.5)),
              child: OutlinedButton(
                onPressed: () => onPick(q),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.symmetric(horizontal: TwSpace.of(3), vertical: TwSpace.of(2)),
                  backgroundColor: tone.dark ? Colors.white.withValues(alpha: 0.05) : null,
                  side: BorderSide(color: tone.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TwRadius.xl)),
                  foregroundColor: tone.dark ? TwPalette.slate200 : TwPalette.slate700,
                  textStyle: _text(TwText.sm, tone.heading),
                ),
                child: Text(q.chip(t), textAlign: TextAlign.left),
              ),
            ),
        ],
      ),
    );
  }
}

/// A Help Centre answer, labelled automated and attributed to the Help Centre, never to an Agent.
class _AutomatedAnswer extends StatelessWidget {
  const _AutomatedAnswer({required this.tone, required this.question, required this.onSolved, required this.onPerson});

  final _Tone tone;
  final QuickQuestion question;
  final VoidCallback onSolved;
  final VoidCallback onPerson;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Container(
      margin: EdgeInsets.only(bottom: TwSpace.of(3)),
      padding: EdgeInsets.all(TwSpace.of(3)),
      decoration: BoxDecoration(
        color: tone.dark ? Colors.white.withValues(alpha: 0.05) : TwPalette.slate50,
        borderRadius: BorderRadius.circular(TwRadius.n2xl),
        border: Border.all(color: tone.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.support_automated.toUpperCase(),
              style: _text(const TwFont(11, 1.4), tone.faint, weight: FontWeight.w500)),
          SizedBox(height: TwSpace.of(1)),
          Text(question.title(t), style: _text(TwText.sm, tone.heading, weight: FontWeight.w500)),
          SizedBox(height: TwSpace.of(1)),
          Text(question.body(t), style: _text(TwText.sm, tone.dark ? TwPalette.slate300 : TwPalette.slate700)),
          SizedBox(height: TwSpace.of(3)),
          Wrap(
            spacing: TwSpace.of(2),
            runSpacing: TwSpace.of(2),
            children: [
              FilledButton(onPressed: onSolved, child: Text(t.support_thatAnsweredIt)),
              OutlinedButton(onPressed: onPerson, child: Text(t.support_talkToAPerson)),
            ],
          ),
        ],
      ),
    );
  }
}

/// One message. Which text to show is [customerView]'s decision, shared in spirit with the inbox.
class _Bubble extends StatefulWidget {
  const _Bubble({required this.message, required this.tone, required this.onOpenFile, super.key});

  final SupportMessage message;
  final _Tone tone;
  final Future<void> Function(String id) onOpenFile;

  @override
  State<_Bubble> createState() => _BubbleState();
}

class _BubbleState extends State<_Bubble> {
  bool _original = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final m = widget.message;
    final tone = widget.tone;
    final view = customerView(m);

    if (m.senderType == 'system') {
      return Text(view.primary,
          textAlign: TextAlign.center, style: _text(TwText.xs, tone.faint, style: FontStyle.italic));
    }

    final mine = m.senderType == 'guest';
    final background = mine
        ? (tone.dark ? Colors.white : TwPalette.slate900)
        : (tone.dark ? TwPalette.slate800 : TwPalette.slate100);
    final foreground = mine
        ? (tone.dark ? TwPalette.slate900 : Colors.white)
        : (tone.dark ? TwPalette.slate100 : TwPalette.slate900);
    final labelColor = mine
        ? (tone.dark ? TwPalette.slate500 : TwPalette.slate300)
        : (tone.dark ? TwPalette.slate400 : TwPalette.slate500);

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: 0.85,
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Align(
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: Opacity(
            opacity: m.pending ? 0.6 : 1,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: TwSpace.of(3), vertical: TwSpace.of(2)),
              decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(TwRadius.n2xl)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_original && view.original != null ? view.original! : view.primary,
                      style: _text(TwText.sm, foreground)),
                  if (m.attachments.isNotEmpty) ...[
                    SizedBox(height: TwSpace.of(1.5)),
                    for (final f in m.attachments)
                      _AttachmentRow(file: f, color: foreground, onOpen: () => widget.onOpenFile(f.id)),
                  ],
                  if (view.label != null) ...[
                    SizedBox(height: TwSpace.of(1)),
                    if (view.label == ReaderLabel.translated && view.original != null)
                      GestureDetector(
                        onTap: () => setState(() => _original = !_original),
                        child: Text(
                          _original ? t.support_showTranslation : t.support_showOriginal,
                          style: _text(const TwFont(11, 1.4), labelColor)
                              .copyWith(decoration: TextDecoration.underline, decorationColor: labelColor),
                        ),
                      )
                    else
                      Text(
                        view.label == ReaderLabel.pending ? t.support_translating : t.support_notTranslated,
                        style: _text(const TwFont(11, 1.4), labelColor),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One file on a message. Opening it asks the API, which re-checks and redirects (ADR-0040).
class _AttachmentRow extends StatelessWidget {
  const _AttachmentRow({required this.file, required this.color, required this.onOpen});

  final SupportAttachment file;
  final Color color;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final style = _text(TwText.xs, color);
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LucideIcons.fileText, size: 14, color: color),
        SizedBox(width: TwSpace.of(1.5)),
        Flexible(
          child: Text(
            file.fileName,
            overflow: TextOverflow.ellipsis,
            style: file.bytesDeleted
                ? style.copyWith(decoration: TextDecoration.lineThrough, decorationColor: color)
                : style.copyWith(decoration: TextDecoration.underline, decorationColor: color),
          ),
        ),
        // The row stays so the transcript still says a file was sent; only the bytes are gone.
        if (file.bytesDeleted) Text(' · ${t.support_fileExpired}', style: style),
      ],
    );
    return Padding(
      padding: EdgeInsets.only(bottom: TwSpace.of(1)),
      child: file.bytesDeleted
          ? Opacity(opacity: 0.7, child: row)
          : Semantics(link: true, child: InkWell(onTap: onOpen, child: row)),
    );
  }
}

class _StagedChip extends StatelessWidget {
  const _StagedChip({required this.tone, required this.file, required this.onRemove});

  final _Tone tone;
  final SupportAttachment file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final color = tone.heading;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: TwSpace.of(2), vertical: TwSpace.of(1)),
      decoration: BoxDecoration(
        color: tone.dark ? Colors.white.withValues(alpha: 0.10) : TwPalette.slate100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.fileText, size: 12, color: color),
          SizedBox(width: TwSpace.of(1)),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(file.fileName, overflow: TextOverflow.ellipsis, style: _text(TwText.xs, color)),
          ),
          SizedBox(width: TwSpace.of(1)),
          Semantics(
            button: true,
            label: t.support_removeFile,
            child: InkWell(onTap: onRemove, child: Icon(LucideIcons.x, size: 12, color: tone.faint)),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.tone,
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.attaching,
    required this.canAttach,
    required this.onAttach,
    required this.onSend,
    required this.onChanged,
  });

  final _Tone tone;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final bool attaching;
  final bool canAttach;
  final VoidCallback onAttach;
  final VoidCallback onSend;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final canSend = !sending && controller.text.trim().isNotEmpty;
    final spinner = SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(strokeWidth: 2, color: tone.muted),
    );

    return Container(
      padding: EdgeInsets.all(TwSpace.of(3)),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: tone.border))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              minLines: 1,
              maxLines: 4,
              maxLength: 4000,
              textInputAction: TextInputAction.newline,
              onChanged: (_) => onChanged(),
              style: _text(TwText.sm, tone.heading),
              decoration: InputDecoration(
                hintText: t.support_placeholder,
                counterText: '',
                isDense: true,
                filled: tone.dark,
                fillColor: Colors.white.withValues(alpha: 0.05),
                contentPadding: EdgeInsets.symmetric(horizontal: TwSpace.of(3), vertical: TwSpace.of(2)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TwRadius.lg),
                  borderSide: BorderSide(color: tone.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TwRadius.lg),
                  borderSide: BorderSide(color: tone.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TwRadius.lg),
                  borderSide: const BorderSide(color: TwPalette.blue400),
                ),
              ),
            ),
          ),
          if (canAttach) ...[
            SizedBox(width: TwSpace.of(2)),
            SizedBox(
              width: 36,
              height: 36,
              child: IconButton(
                onPressed: attaching ? null : onAttach,
                tooltip: t.support_attach,
                padding: EdgeInsets.zero,
                icon: attaching ? spinner : Icon(LucideIcons.paperclip, size: 16, color: TwPalette.slate500),
              ),
            ),
          ],
          SizedBox(width: TwSpace.of(2)),
          SizedBox(
            width: 36,
            height: 36,
            child: Tooltip(
              message: t.support_send,
              child: FilledButton(
                onPressed: canSend ? onSend : null,
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TwRadius.lg)),
                ),
                child: sending
                    ? spinner
                    : Semantics(label: t.support_send, child: const Icon(LucideIcons.send, size: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
