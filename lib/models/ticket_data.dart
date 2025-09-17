class TicketData {
  final String rawText;
  final String? storeName;
  final DateTime? date;
  final List<TicketItem> items;
  final double? subtotal;
  final double? tax;
  final double? total;
  final String? currency;
  final double? discount;

  TicketData({
    required this.rawText,
    this.storeName,
    this.date,
    required this.items,
    this.subtotal,
    this.tax,
    this.total,
    this.currency,
    this.discount,
  });

  factory TicketData.fromRawText(String text) {
    return TicketData(
      rawText: text,
      items: [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rawText': rawText,
      'storeName': storeName,
      'date': date?.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'currency': currency,
      'discount': discount,
    };
  }
}

class TicketItem {
  final String name;
  final double price;
  final int quantity;
  final String? category;

  TicketItem({
    required this.name,
    required this.price,
    this.quantity = 1,
    this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'quantity': quantity,
      'category': category,
    };
  }
}