import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ticket_data.dart';
import '../models/category.dart';

class ValidationScreen extends ConsumerStatefulWidget {
  final TicketData ticket;
  const ValidationScreen({super.key, required this.ticket});

  @override
  ConsumerState<ValidationScreen> createState() => _ValidationScreenState();
}

class _ValidationScreenState extends ConsumerState<ValidationScreen> {
  late List<TicketItem> _items;
  late TextEditingController _storeCtrl;

  @override
  void initState() {
    super.initState();
    _items = widget.ticket.items.map((e) => TicketItem(name: e.name, price: e.price, quantity: e.quantity, category: e.category)).toList();
    _storeCtrl = TextEditingController(text: widget.ticket.storeName ?? '');
  }

  @override
  void dispose() {
    _storeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Valider le ticket'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _storeCtrl,
              decoration: const InputDecoration(labelText: 'Magasin'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final it = _items[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(it.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: it.category ?? CategoryDefinitions.categories.last,
                                items: CategoryDefinitions.categories
                                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                    .toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _items[index] = TicketItem(
                                      name: it.name,
                                      price: it.price,
                                      quantity: it.quantity,
                                      category: val,
                                    );
                                  });
                                },
                                decoration: const InputDecoration(labelText: 'Catégorie'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 90,
                              child: TextFormField(
                                initialValue: it.quantity.toString(),
                                decoration: const InputDecoration(labelText: 'Qté'),
                                keyboardType: TextInputType.number,
                                onChanged: (v) {
                                  final q = int.tryParse(v) ?? 1;
                                  setState(() {
                                    _items[index] = TicketItem(
                                      name: it.name,
                                      price: it.price,
                                      quantity: q,
                                      category: it.category,
                                    );
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 110,
                              child: TextFormField(
                                initialValue: it.price.toStringAsFixed(2),
                                decoration: const InputDecoration(labelText: 'Prix'),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (v) {
                                  final p = double.tryParse(v.replaceAll(',', '.')) ?? it.price;
                                  setState(() {
                                    _items[index] = TicketItem(
                                      name: it.name,
                                      price: p,
                                      quantity: it.quantity,
                                      category: it.category,
                                    );
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final updated = TicketData(
                    rawText: widget.ticket.rawText,
                    storeName: _storeCtrl.text.trim().isEmpty ? widget.ticket.storeName : _storeCtrl.text.trim(),
                    date: widget.ticket.date,
                    items: _items,
                    subtotal: widget.ticket.subtotal,
                    tax: widget.ticket.tax,
                    total: widget.ticket.total,
                    currency: widget.ticket.currency,
                    discount: widget.ticket.discount,
                    id: widget.ticket.id,
                    createdAt: widget.ticket.createdAt,
                  );
                  Navigator.pop(context, updated);
                },
                icon: const Icon(Icons.check),
                label: const Text('Valider'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

