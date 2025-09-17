import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ocr_provider.dart';
import '../services/ocr_manager.dart';
import '../services/export_service.dart';

class TicketDetailScreen extends ConsumerWidget {
  const TicketDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ocrState = ref.watch(ocrProvider);
    final arg = ModalRoute.of(context)?.settings.arguments;
    final ticketData = (arg is Map && arg['ticket'] != null)
        ? arg['ticket'] as dynamic
        : (arg is Object ? arg : null) as dynamic ?? ocrState.ticketData;

    if (ticketData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détails du ticket')),
        body: const Center(
          child: Text('Aucune donnée de ticket disponible'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du ticket'),
        actions: [
          IconButton(
            onPressed: () {
              _showRawTextDialog(context, ocrState.extractedText ?? '');
            },
            icon: const Icon(Icons.text_fields),
            tooltip: 'Voir le texte brut',
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              final exporter = ExportService();
              try {
                if (value == 'csv') {
                  final file = await exporter.exportTicketToCsv(ticketData);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Export CSV: ${file.path}')),
                    );
                  }
                } else if (value == 'pdf') {
                  final file = await exporter.exportTicketToPdf(ticketData);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Export PDF: ${file.path}')),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur export: $e')),
                  );
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'csv', child: Text('Exporter en CSV')),
              PopupMenuItem(value: 'pdf', child: Text('Exporter en PDF')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informations générales
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informations générales',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    if (ticketData.storeName != null) ...[
                      _buildInfoRow('Magasin', ticketData.storeName!),
                      const SizedBox(height: 8),
                    ],
                    if (ticketData.date != null) ...[
                      _buildInfoRow(
                        'Date',
                        '${ticketData.date!.day}/${ticketData.date!.month}/${ticketData.date!.year}',
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (ticketData.currency != null) ...[
                      _buildInfoRow('Devise', ticketData.currency!),
                      const SizedBox(height: 8),
                    ],
                    _buildInfoRow('Moteur OCR', _getEngineDisplayName(ocrState.selectedEngine)),
                    if (ocrState.processingTime != null) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        'Temps de traitement',
                        '${ocrState.processingTime!.inMilliseconds}ms',
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Articles
            if (ticketData.items.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Articles',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      ...ticketData.items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8.0),
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    if (item.category != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        item.category!,
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${item.price.toStringAsFixed(2)}€',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  if (item.quantity > 1) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'x${item.quantity}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Totaux
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Totaux',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    if (ticketData.subtotal != null)
                      _buildTotalRow('Sous-total', ticketData.subtotal!),
                    if (ticketData.discount != null)
                      _buildTotalRow('Remise', -ticketData.discount!, isDiscount: true),
                    if (ticketData.tax != null)
                      _buildTotalRow('TVA', ticketData.tax!),
                    const Divider(),
                    if (ticketData.total != null)
                      _buildTotalRow(
                        'TOTAL',
                        ticketData.total!,
                        isTotal: true,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isDiscount = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            '${isDiscount ? '-' : ''}${amount.toStringAsFixed(2)}€',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              fontSize: isTotal ? 16 : 14,
              color: isDiscount ? Colors.red : null,
            ),
          ),
        ],
      ),
    );
  }

  String _getEngineDisplayName(OCREngine engine) {
    switch (engine) {
      case OCREngine.mlkit:
        return 'Google ML Kit';
      case OCREngine.tesseract:
        return 'Tesseract OCR';
      case OCREngine.tflite:
        return 'TensorFlow Lite';
    }
  }

  void _showRawTextDialog(BuildContext context, String text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Texte brut extrait'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              text,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}