import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ocr_provider.dart';
import '../services/ocr_manager.dart';
import 'ticket_detail_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ocrState = ref.watch(ocrProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket Caisse OCR'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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