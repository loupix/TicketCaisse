import '../models/category.dart';
import '../models/ticket_data.dart';

class CategorySuggestionService {
  static final CategorySuggestionService _instance = CategorySuggestionService._internal();
  factory CategorySuggestionService() => _instance;
  CategorySuggestionService._internal();

  final Map<String, String> _keywordToCategory = {
    // Alimentation
    'lait': 'Alimentation',
    'pain': 'Alimentation',
    'pomme': 'Alimentation',
    'banane': 'Alimentation',
    'poulet': 'Alimentation',
    'riz': 'Alimentation',
    'pâtes': 'Alimentation',
    // Hygiène
    'shampoo': 'Hygiène',
    'dentifrice': 'Hygiène',
    'savon': 'Hygiène',
    // Maison
    'lessive': 'Maison',
    'éponge': 'Maison',
    'ampoule': 'Maison',
    // Électronique
    'câble': 'Électronique',
    'usb': 'Électronique',
    'chargeur': 'Électronique',
    // Restaurants
    'menu': 'Restaurants',
    'pizza': 'Restaurants',
    'burger': 'Restaurants',
  };

  String suggestCategory(String itemName) {
    final lower = itemName.toLowerCase();
    for (final entry in _keywordToCategory.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return 'Autre';
  }

  TicketData applySuggestions(TicketData ticket) {
    final items = ticket.items
        .map((i) => TicketItem(name: i.name, price: i.price, quantity: i.quantity, category: i.category ?? suggestCategory(i.name)))
        .toList();
    return TicketData(
      rawText: ticket.rawText,
      storeName: ticket.storeName,
      date: ticket.date,
      items: items,
      subtotal: ticket.subtotal,
      tax: ticket.tax,
      total: ticket.total,
      currency: ticket.currency,
      discount: ticket.discount,
      id: ticket.id,
      createdAt: ticket.createdAt,
    );
  }
}

