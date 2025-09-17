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
  final String? id;
  final DateTime? createdAt;

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
    this.id,
    this.createdAt,
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
      'id': id,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory TicketData.fromJson(Map<String, dynamic> json) {
    return TicketData(
      rawText: json['rawText'] as String? ?? '',
      storeName: json['storeName'] as String?,
      date: json['date'] != null ? DateTime.tryParse(json['date'] as String) : null,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => TicketItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num?)?.toDouble(),
      tax: (json['tax'] as num?)?.toDouble(),
      total: (json['total'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      discount: (json['discount'] as num?)?.toDouble(),
      id: json['id'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
    );
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

  factory TicketItem.fromJson(Map<String, dynamic> json) {
    return TicketItem(
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      category: json['category'] as String?,
    );
  }
}