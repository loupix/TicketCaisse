// import 'dart:math';
import 'package:intl/intl.dart';
import '../models/ticket_data.dart';

class TicketParser {
  static final TicketParser _instance = TicketParser._internal();
  factory TicketParser() => _instance;
  TicketParser._internal();

  // Patterns pour détecter les prix (gère devises avant/après et séparateurs)
  static final RegExp _pricePattern = RegExp(
    r'(?:(?:[€$£¥]\s*)?(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?)\s*(?:€|\$|£|¥)?)',
    caseSensitive: false,
  );

  // Patterns pour détecter les totaux
  static final RegExp _totalPattern = RegExp(
    r'(?:\btotal\b|\bttc\b|\bmontant total\b|\bmontant\b|\bsomme\b|\bsum\b|\bamount\b)\s*[:=]?\s*(?:€|\$|£|¥)?\s*(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?)',
    caseSensitive: false,
  );

  // Sous-total
  static final RegExp _subtotalPattern = RegExp(
    r'(?:\bsous[- ]?total\b|\bsubtotal\b|\bht\b)\s*[:=]?\s*(?:€|\$|£|¥)?\s*(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?)',
    caseSensitive: false,
  );

  // Patterns pour détecter les remises
  static final RegExp _discountPattern = RegExp(
    r'(?:\bremise\b|\bréduction\b|\breduction\b|\brabais\b|\bdiscount\b)\s*[:=]?\s*(?:€|\$|£|¥)?\s*(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?)',
    caseSensitive: false,
  );

  // Patterns pour détecter la TVA
  static final RegExp _taxPattern = RegExp(
    r'(?:\btva\b|\btax\b|\bvat\b)\s*[:=]?\s*(?:€|\$|£|¥)?\s*(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?)',
    caseSensitive: false,
  );

  // Patterns pour détecter les dates (avec heure optionnelle)
  static final RegExp _datePattern = RegExp(
    r'(\d{1,2}[/.\-]\d{1,2}[/.\-]\d{2,4})(?:\s+(\d{1,2}:\d{2})(?::\d{2})?)?',
  );

  // Patterns pour détecter les noms de magasins
  static final RegExp _storePattern = RegExp(
    r'^[A-ZÉÈÀÂÎÙÔÇ][A-Za-zÉÈÀÂÎÙÔÇ\s&\-]+(?:\n|$)',
    multiLine: true,
  );

  /// Parse le texte extrait en données de ticket
  TicketData parseTicket(String rawText) {
    final lines = rawText.split('\n').where((line) => line.trim().isNotEmpty).toList();
    
    final items = <TicketItem>[];
    double? subtotal;
    double? tax;
    double? total;
    double? discount;
    String? currency;
    String? storeName;
    DateTime? date;

    // Détecter le nom du magasin (première ligne significative)
    for (final line in lines.take(3)) {
      if (_isStoreName(line)) {
        storeName = line.trim();
        break;
      }
    }

    // Détecter la date
    for (final line in lines) {
      final dateMatch = _datePattern.firstMatch(line);
      if (dateMatch != null) {
        date = _parseDate(dateMatch.group(1)!);
        break;
      }
    }

    // Détecter la devise
    currency = _detectCurrency(rawText);

    // Parser les lignes pour extraire les articles
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      // Détecter les totaux
      final totalMatch = _totalPattern.firstMatch(line);
      if (totalMatch != null) {
        total = _parsePrice(totalMatch.group(1)!, currency);
        continue;
      }

      // Détecter le sous-total
      final subtotalMatch = _subtotalPattern.firstMatch(line);
      if (subtotalMatch != null) {
        subtotal = _parsePrice(subtotalMatch.group(1)!, currency);
        continue;
      }

      // Détecter les remises
      final discountMatch = _discountPattern.firstMatch(line);
      if (discountMatch != null) {
        discount = _parsePrice(discountMatch.group(1)!, currency);
        continue;
      }

      // Détecter la TVA
      final taxMatch = _taxPattern.firstMatch(line);
      if (taxMatch != null) {
        tax = _parsePrice(taxMatch.group(1)!, currency);
        continue;
      }

      // Parser les articles
      final item = _parseItemLine(line, currency);
      if (item != null) {
        items.add(item);
      }
    }

    // Calculer le sous-total si non trouvé
    if (subtotal == null && items.isNotEmpty) {
      subtotal = items.fold(0.0, (sum, item) => (sum ?? 0.0) + (item.price * item.quantity));
    }

    return TicketData(
      rawText: rawText,
      storeName: storeName,
      date: date,
      items: items,
      subtotal: subtotal,
      tax: tax,
      total: total,
      currency: currency,
      discount: discount,
    );
  }

  /// Parse une ligne pour extraire un article
  TicketItem? _parseItemLine(String line, String? currency) {
    final normalizedLine = line.replaceAll(RegExp(r'[·•]+'), ' ').replaceAll(RegExp(r'\.{2,}'), ' ');
    final priceMatch = _pricePattern.firstMatch(normalizedLine);
    if (priceMatch == null) return null;

    final price = _parsePrice(priceMatch.group(1)!, currency);
    if (price <= 0) return null;

    // Extraire le nom de l'article (tout avant le prix)
    final name = normalizedLine.substring(0, priceMatch.start).trim();
    if (name.isEmpty) return null;

    // Détecter la quantité (nombre au début de la ligne)
    final quantityMatch = RegExp(r'^(\d+)\s*(?:x|×|\*)?\s*').firstMatch(name);
    int quantity = 1;
    String itemName = name;
    
    if (quantityMatch != null) {
      quantity = int.tryParse(quantityMatch.group(1)!) ?? 1;
      itemName = name.substring(quantityMatch.end).trim();
    }

    return TicketItem(
      name: itemName,
      price: price,
      quantity: quantity,
    );
  }

  /// Parse un prix en double
  double _parsePrice(String priceStr, String? currency) {
    String s = priceStr.trim();
    s = s.replaceAll(RegExp(r'[€$£¥]'), '');
    s = s.replaceAll(' ', '');
    final hasComma = s.contains(',');
    final hasDot = s.contains('.');
    if (hasComma && hasDot) {
      final lastComma = s.lastIndexOf(',');
      final lastDot = s.lastIndexOf('.');
      if (lastComma > lastDot) {
        s = s.replaceAll('.', '');
        s = s.replaceFirst(',', '.');
      } else {
        s = s.replaceAll(',', '');
      }
    } else if (hasComma && !hasDot) {
      s = s.replaceAll('.', '');
      s = s.replaceAll(',', '.');
    } else {
      s = s.replaceAll(',', '');
    }
    return double.tryParse(s) ?? 0.0;
  }

  /// Détecte la devise utilisée
  String? _detectCurrency(String text) {
    if (text.contains('€') || RegExp(r'\bEUR\b|\beuros?\b', caseSensitive: false).hasMatch(text)) return '€';
    if (text.contains('\$') || RegExp(r'\bUSD\b|\bdollars?\b', caseSensitive: false).hasMatch(text)) return '\$';
    if (text.contains('£') || RegExp(r'\bGBP\b|\bpounds?\b', caseSensitive: false).hasMatch(text)) return '£';
    if (text.contains('¥') || RegExp(r'\bJPY\b|\byen\b', caseSensitive: false).hasMatch(text)) return '¥';
    return null;
  }

  /// Vérifie si une ligne ressemble à un nom de magasin
  bool _isStoreName(String line) {
    if (line.length < 3) return false;
    if (_pricePattern.hasMatch(line)) return false;
    if (_datePattern.hasMatch(line)) return false;
    
    // Vérifier si la ligne commence par une majuscule et contient des lettres
    return RegExp(r'^[A-Z][A-Za-z\s&]+$').hasMatch(line.trim());
  }

  /// Parse une date
  DateTime? _parseDate(String dateStr) {
    try {
      // Essayer différents formats
      final formats = [
        'dd/MM/yyyy',
        'dd-MM-yyyy',
        'dd.MM.yyyy',
        'dd/MM/yy',
        'dd-MM-yy',
        'dd.MM.yy',
        'dd/MM/yyyy HH:mm',
        'dd-MM-yyyy HH:mm',
        'dd.MM.yyyy HH:mm',
        'dd/MM/yy HH:mm',
        'dd-MM-yy HH:mm',
        'dd.MM.yy HH:mm',
      ];

      for (final format in formats) {
        try {
          return DateFormat(format).parse(dateStr);
        } catch (e) {
          continue;
        }
      }
    } catch (e) {
      // Ignorer les erreurs de parsing de date
    }
    return null;
  }
}