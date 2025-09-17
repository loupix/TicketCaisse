import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../models/ticket_data.dart';

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  Future<Directory> _getExportDirectory() async {
    // Sur mobile, Documents n'est pas toujours dispo; utiliser app documents
    final dir = await getApplicationDocumentsDirectory();
    final exportDir = Directory(p.join(dir.path, 'exports'));
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return exportDir;
  }

  Future<File> exportTicketToCsv(TicketData ticket) async {
    final dir = await _getExportDirectory();
    final filename = _buildFileName(ticket, 'csv');
    final file = File(p.join(dir.path, filename));
    final csv = _buildCsv(ticket);
    await file.writeAsString(csv);
    return file;
  }

  Future<File> exportTicketToPdf(TicketData ticket) async {
    final dir = await _getExportDirectory();
    final filename = _buildFileName(ticket, 'pdf');
    final file = File(p.join(dir.path, filename));

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Ticket', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              if (ticket.storeName != null)
                pw.Text('Magasin: ${ticket.storeName}'),
              if (ticket.date != null)
                pw.Text('Date: ${ticket.date!.day}/${ticket.date!.month}/${ticket.date!.year}'),
              if (ticket.currency != null)
                pw.Text('Devise: ${ticket.currency}'),
              pw.SizedBox(height: 12),
              pw.Text('Articles', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(5),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Article', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Prix', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Qté', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  ]),
                  ...ticket.items.map((i) => pw.TableRow(children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(i.name)),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${i.price.toStringAsFixed(2)}${ticket.currency ?? '€'}')),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${i.quantity}')),
                      ])),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Divider(),
              _buildTotalRow('Sous-total', ticket.subtotal, ticket.currency),
              _buildTotalRow('Remise', ticket.discount != null ? -ticket.discount! : null, ticket.currency),
              _buildTotalRow('TVA', ticket.tax, ticket.currency),
              pw.Divider(),
              _buildTotalRow('TOTAL', ticket.total, ticket.currency, isBold: true),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    await file.writeAsBytes(bytes);
    return file;
  }

  pw.Widget _buildTotalRow(String label, double? value, String? currency, {bool isBold = false}) {
    if (value == null) return pw.SizedBox();
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text('${value.toStringAsFixed(2)}${currency ?? '€'}', style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  String _buildFileName(TicketData ticket, String ext) {
    final store = (ticket.storeName ?? 'ticket').replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    final when = (ticket.createdAt ?? ticket.date ?? DateTime.now()).toIso8601String().replaceAll(':', '').replaceAll('.', '');
    return '${store}_$when.$ext';
  }

  String _buildCsv(TicketData ticket) {
    final buffer = StringBuffer();
    buffer.writeln('Magasin;Date;Devise');
    final when = ticket.date != null ? '${ticket.date!.day}/${ticket.date!.month}/${ticket.date!.year}' : '';
    buffer.writeln('${ticket.storeName ?? ''};$when;${ticket.currency ?? ''}');
    buffer.writeln();
    buffer.writeln('Article;Prix;Quantite');
    for (final i in ticket.items) {
      buffer.writeln('${_escape(i.name)};${i.price.toStringAsFixed(2)};${i.quantity}');
    }
    buffer.writeln();
    buffer.writeln('Sous-total;${ticket.subtotal?.toStringAsFixed(2) ?? ''}');
    buffer.writeln('Remise;${ticket.discount?.toStringAsFixed(2) ?? ''}');
    buffer.writeln('TVA;${ticket.tax?.toStringAsFixed(2) ?? ''}');
    buffer.writeln('TOTAL;${ticket.total?.toStringAsFixed(2) ?? ''}');
    return buffer.toString();
  }

  String _escape(String v) {
    var s = v.replaceAll(';', ',');
    if (s.contains('"')) s = s.replaceAll('"', "''");
    return s;
  }
}

