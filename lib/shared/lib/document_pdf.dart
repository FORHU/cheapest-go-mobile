/// The on-screen document, as a PDF. V2's `receipt-pdf.ts`.
///
/// V2 photographs the rendered page and lays the picture onto A4 pages, so the file and the
/// screen say the same thing; this does the same with the widget's own paint. Nothing is
/// re-typeset for paper — a second layout would be a second document to keep in step.
library;

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// V2's margins: A4, 10 mm all round.
const double _marginMm = 10;

/// Paints [boundary] at [pixelRatio] and slices it into as many A4 pages as it needs.
Future<Uint8List> renderBoundaryAsPdf(RenderRepaintBoundary boundary, {double pixelRatio = 2.5}) async {
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    try {
        return await imageAsPdf(image);
    } finally {
        image.dispose();
    }
}

/// [image] laid top-to-bottom across A4 pages at the page's content width.
Future<Uint8List> imageAsPdf(ui.Image image) async {
    const format = PdfPageFormat.a4;
    const margin = _marginMm * PdfPageFormat.mm;
    const contentWidth = 210 * PdfPageFormat.mm - 2 * margin;
    const contentHeight = 297 * PdfPageFormat.mm - 2 * margin;

    // Points per source pixel, and so how many source pixels fill one page's height.
    final scale = contentWidth / image.width;
    final sliceHeight = math.max(1, (contentHeight / scale).floor());

    final doc = pw.Document();
    for (var top = 0; top < image.height; top += sliceHeight) {
        final height = math.min(sliceHeight, image.height - top);
        final png = await _slicePng(image, top, height);
        doc.addPage(
            pw.Page(
                pageFormat: format,
                margin: const pw.EdgeInsets.all(margin),
                build: (_) => pw.Align(
                    alignment: pw.Alignment.topLeft,
                    child: pw.Image(
                        pw.MemoryImage(png),
                        width: contentWidth,
                        height: height * scale,
                        fit: pw.BoxFit.fill,
                    ),
                ),
            ),
        );
    }
    return doc.save();
}

Future<Uint8List> _slicePng(ui.Image image, int top, int height) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final width = image.width.toDouble();
    canvas.drawImageRect(
        image,
        ui.Rect.fromLTWH(0, top.toDouble(), width, height.toDouble()),
        ui.Rect.fromLTWH(0, 0, width, height.toDouble()),
        ui.Paint()..filterQuality = ui.FilterQuality.high,
    );
    final slice = await recorder.endRecording().toImage(image.width, height);
    try {
        final data = await slice.toByteData(format: ui.ImageByteFormat.png);
        return data!.buffer.asUint8List();
    } finally {
        slice.dispose();
    }
}

/// The system print dialog, with [pdf] as the document.
Future<void> printPdf(Uint8List pdf, {required String name}) =>
    Printing.layoutPdf(name: name, onLayout: (_) async => pdf);

/// Hands [pdf] to the system, named [filename], to be saved or sent on.
Future<void> savePdf(Uint8List pdf, {required String filename}) =>
    Printing.sharePdf(bytes: pdf, filename: filename);
