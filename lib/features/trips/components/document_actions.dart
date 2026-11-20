/// Print and Download PDF, as V2's document pages set them. See `travel-document-view.tsx`.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/lib/document_pdf.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/app_colors.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/generated/tw_palette.dart';

/// A document that can be printed and saved as it is drawn.
///
/// Wraps the document in the boundary its PDF is painted from. While a PDF is being made the
/// document is drawn in the light theme for a frame, as V2 drops `dark` from the copy it
/// photographs: paper is white, and a dark receipt in someone's expense claim is a defect.
class PrintableDocument extends StatefulWidget {
    const PrintableDocument({required this.child, super.key});

    final Widget child;

    @override
    State<PrintableDocument> createState() => PrintableDocumentState();
}

class PrintableDocumentState extends State<PrintableDocument> {
    final _boundary = GlobalKey();
    bool _forPaper = false;

    /// The document as a PDF, painted from what is on screen.
    Future<Uint8List> toPdf() async {
        final dark = Theme.of(context).brightness == Brightness.dark;
        if (dark) {
            setState(() => _forPaper = true);
            await WidgetsBinding.instance.endOfFrame;
        }
        try {
            final boundary = _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
            return await renderBoundaryAsPdf(boundary);
        } finally {
            if (dark && mounted) setState(() => _forPaper = false);
        }
    }

    @override
    Widget build(BuildContext context) {
        Widget child = widget.child;
        if (_forPaper) {
            final theme = Theme.of(context);
            child = Theme(
                data: theme.copyWith(
                    brightness: Brightness.light,
                    extensions: [...theme.extensions.values.where((e) => e is! AppColors), AppColors.light],
                ),
                child: child,
            );
        }
        return RepaintBoundary(key: _boundary, child: child);
    }
}

/// Print beside Download. Download saves the printed copy as a PDF named for the reference on
/// it, so the file and the paper say the same thing.
class DocumentActions extends StatefulWidget {
    const DocumentActions({required this.makePdf, required this.filename, this.downloadPdf, super.key});

    /// The on-screen document as a PDF — what Print sends, and Download saves unless
    /// [downloadPdf] says otherwise.
    final Future<Uint8List> Function() makePdf;

    /// Where Download takes its file from when it is not the screen — the invoice's API PDF.
    final Future<Uint8List> Function()? downloadPdf;
    final String filename;

    @override
    State<DocumentActions> createState() => _DocumentActionsState();
}

class _DocumentActionsState extends State<DocumentActions> {
    bool _busy = false;
    bool _failed = false;

    Future<void> _run(Future<void> Function() action) async {
        setState(() {
            _busy = true;
            _failed = false;
        });
        try {
            await action();
        } catch (_) {
            // The other button still works, so this is a note beside them rather than a
            // dialog that takes over the screen.
            if (mounted) setState(() => _failed = true);
        } finally {
            if (mounted) setState(() => _busy = false);
        }
    }

    Future<void> _print() => _run(() async {
        final pdf = await widget.makePdf();
        await printPdf(pdf, name: widget.filename);
    });

    Future<void> _download() => _run(() async {
        final pdf = await (widget.downloadPdf ?? widget.makePdf)();
        await savePdf(pdf, filename: widget.filename);
    });

    @override
    Widget build(BuildContext context) {
        final t = AppLocalizations.of(context)!;
        final dark = Theme.of(context).brightness == Brightness.dark;
        final text = dark ? TwPalette.slate100 : TwPalette.slate700;

        return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                    Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                            _Pill(
                                icon: LucideIcons.printer,
                                label: t.trips_invoice_print,
                                foreground: text,
                                background: dark ? const Color(0x14FFFFFF) : TwPalette.slate100,
                                onTap: _busy ? null : _print,
                            ),
                            _Pill(
                                icon: _busy ? null : LucideIcons.download,
                                busy: _busy,
                                label: _busy ? t.trips_invoice_generating : t.trips_invoice_downloadPdf,
                                foreground: Colors.white,
                                gradient: kBrandGradient,
                                onTap: _busy ? null : _download,
                            ),
                        ],
                    ),
                    if (_failed)
                        Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Semantics(
                                liveRegion: true,
                                child: Text(
                                    t.trips_invoice_pdfError,
                                    textAlign: TextAlign.right,
                                    style: TextStyle(fontSize: 13, color: dark ? TwPalette.red400 : TwPalette.red600),
                                ),
                            ),
                        ),
                ],
            ),
        );
    }
}

/// V2's `ACTION`: the flight card's Select Now measure — 42 high, fully round.
class _Pill extends StatelessWidget {
    const _Pill({
        required this.label,
        required this.foreground,
        required this.onTap,
        this.icon,
        this.background,
        this.gradient,
        this.busy = false,
    });

    final IconData? icon;
    final String label;
    final Color foreground;
    final Color? background;
    final Gradient? gradient;
    final VoidCallback? onTap;
    final bool busy;

    @override
    Widget build(BuildContext context) => Opacity(
        opacity: busy ? 0.6 : 1,
        child: DecoratedBox(
            decoration: BoxDecoration(
                color: background,
                gradient: gradient,
                borderRadius: BorderRadius.circular(999),
            ),
            child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                                if (busy)
                                    SizedBox(
                                        width: 15,
                                        height: 15,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
                                    )
                                else if (icon != null)
                                    Icon(icon, size: 15, color: foreground),
                                const SizedBox(width: 6),
                                Flexible(
                                    child: Text(
                                        label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: foreground),
                                    ),
                                ),
                            ],
                        ),
                    ),
                ),
            ),
        ),
    );
}
