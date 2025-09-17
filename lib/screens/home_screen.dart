import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ocr_provider.dart';
import '../services/ocr_manager.dart';
import 'ticket_detail_screen.dart';
import '../providers/saved_tickets_provider.dart';
import 'tickets_list_screen.dart';
import 'validation_screen.dart';
import '../services/category_suggestion_service.dart';
import '../models/ticket_data.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ocrState = ref.watch(ocrProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket Caisse OCR'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            tooltip: 'Tickets sauvegardés',
            onPressed: () {
              // Charger avant d'ouvrir
              ref.read(savedTicketsProvider.notifier).load();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TicketsListScreen()),
              );
            },
            icon: const Icon(Icons.folder_open),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sélecteur d'engine OCR
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Moteur OCR',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<OCREngine>(
                      value: ocrState.selectedEngine,
                      isExpanded: true,
                      items: OCREngine.values.map((engine) {
                        return DropdownMenuItem(
                          value: engine,
                          child: Text(_getEngineDisplayName(engine)),
                        );
                      }).toList(),
                      onChanged: (engine) {
                        if (engine != null) {
                          ref.read(ocrProvider.notifier).setOCREngine(engine);
                        }
                      },
                    ),
                    
                    // Actions sous le sélecteur
                    if (ocrState.ticketData != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final ticket = ocrState.ticketData!;
                                await ref.read(savedTicketsProvider.notifier).add(ticket);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Ticket enregistré')),
                                );
                              },
                              icon: const Icon(Icons.save_alt),
                              label: const Text('Enregistrer'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: ocrState.isLoading ? null : () {
                      ref.read(ocrProvider.notifier).pickImageFromGallery();
                    },
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galerie'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: ocrState.isLoading ? null : () {
                      ref.read(ocrProvider.notifier).takePicture();
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Caméra'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Indicateur de chargement
            if (ocrState.isLoading)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Traitement en cours...'),
                    ],
                  ),
                ),
              ),
            
            // Affichage des erreurs
            if (ocrState.error != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ocrState.error!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Résultats
            if (ocrState.ticketData != null)
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Résultats',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Row(children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const TicketDetailScreen(),
                                    ),
                                  );
                                },
                                child: const Text('Voir détails'),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () async {
                                  final sugg = CategorySuggestionService();
                                  final suggested = sugg.applySuggestions(ocrState.ticketData!);
                                  final result = await Navigator.push<TicketData>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ValidationScreen(ticket: suggested),
                                    ),
                                  );
                                  if (result != null) {
                                    // Remplacer les données OCR courantes par la version validée
                                    // (on conserve extractedText et processingTime)
                                    ref.read(ocrProvider.notifier).clear();
                                    // Temporisation: afficher résultat validé dans détails
                                    if (context.mounted) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const TicketDetailScreen(),
                                          settings: RouteSettings(arguments: result),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: const Text('Valider'),
                              ),
                            ]),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (ocrState.processingTime != null)
                          Text(
                            'Temps de traitement: ${ocrState.processingTime!.inMilliseconds}ms',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (ocrState.ticketData!.storeName != null) ...[
                                  Text(
                                    'Magasin: ${ocrState.ticketData!.storeName}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                if (ocrState.ticketData!.date != null) ...[
                                  Text(
                                    'Date: ${ocrState.ticketData!.date!.day}/${ocrState.ticketData!.date!.month}/${ocrState.ticketData!.date!.year}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                if (ocrState.ticketData!.items.isNotEmpty) ...[
                                  const Text(
                                    'Articles:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  ...ocrState.ticketData!.items.map((item) => Padding(
                                    padding: const EdgeInsets.only(left: 8.0, bottom: 2.0),
                                    child: Text('• ${item.name} - ${item.price.toStringAsFixed(2)}€'),
                                  )),
                                  const SizedBox(height: 8),
                                ],
                                if (ocrState.ticketData!.total != null) ...[
                                  Text(
                                    'Total: ${ocrState.ticketData!.total!.toStringAsFixed(2)}€',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            
            // Texte brut
            if (ocrState.extractedText != null && ocrState.ticketData == null)
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Texte extrait:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(
                              ocrState.extractedText!,
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: ocrState.extractedText != null
          ? FloatingActionButton(
              onPressed: () {
                ref.read(ocrProvider.notifier).clear();
              },
              child: const Icon(Icons.clear),
            )
          : null,
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
}