import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/ticket_data.dart';

class TicketRepository {
  static final TicketRepository _instance = TicketRepository._internal();
  factory TicketRepository() => _instance;
  TicketRepository._internal();

  Future<File> _getStorageFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/tickets.json');
    if (!await file.exists()) {
      await file.create(recursive: true);
      await file.writeAsString(jsonEncode(<dynamic>[]));
    }
    return file;
  }

  Future<List<TicketData>> loadTickets() async {
    final file = await _getStorageFile();
    final content = await file.readAsString();
    final List<dynamic> list = (content.isNotEmpty) ? jsonDecode(content) as List<dynamic> : <dynamic>[];
    return list.map((e) => TicketData.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveTickets(List<TicketData> tickets) async {
    final file = await _getStorageFile();
    final data = tickets.map((t) => t.toJson()).toList();
    await file.writeAsString(jsonEncode(data));
  }

  Future<TicketData> addTicket(TicketData ticket) async {
    final tickets = await loadTickets();
    final String id = _generateId();
    final TicketData withMeta = TicketData(
      rawText: ticket.rawText,
      storeName: ticket.storeName,
      date: ticket.date,
      items: ticket.items,
      subtotal: ticket.subtotal,
      tax: ticket.tax,
      total: ticket.total,
      currency: ticket.currency,
      discount: ticket.discount,
      id: id,
      createdAt: DateTime.now(),
    );
    tickets.add(withMeta);
    await saveTickets(tickets);
    return withMeta;
  }

  Future<void> deleteTicket(String id) async {
    final tickets = await loadTickets();
    tickets.removeWhere((t) => t.id == id);
    await saveTickets(tickets);
  }

  String _generateId() {
    final millis = DateTime.now().millisecondsSinceEpoch;
    return 't_$millis';
  }
}

