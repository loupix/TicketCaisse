import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'mlkit_ocr_service.dart';
import 'tesseract_ocr_service.dart';
import 'tflite_ocr_service.dart';

enum OCREngine {
  mlkit,
  tesseract,
  tflite,
}

class OCRResult {
  final String text;
  final OCREngine engine;
  final double confidence;
  final Duration processingTime;

  OCRResult({
    required this.text,
    required this.engine,
    required this.confidence,
    required this.processingTime,
  });
}

class OCRManager {
  static final OCRManager _instance = OCRManager._internal();
  factory OCRManager() => _instance;
  OCRManager._internal();

  final MLKitOCRService _mlkitService = MLKitOCRService();
  final TesseractOCRService _tesseractService = TesseractOCRService();
  final TensorFlowLiteOCRService _tfliteService = TensorFlowLiteOCRService();

  /// Extrait le texte avec l'engine spécifié
  Future<OCRResult> extractText(
    String imagePath, {
    OCREngine engine = OCREngine.mlkit,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      String text;
      double confidence = 0.0;

      switch (engine) {
        case OCREngine.mlkit:
          text = await _mlkitService.extractTextFromImage(imagePath);
          confidence = 0.9; // ML Kit a généralement une bonne confiance
          break;
        case OCREngine.tesseract:
          text = await _tesseractService.extractTextFromImage(imagePath);
          confidence = 0.8; // Tesseract peut varier selon l'image
          break;
        case OCREngine.tflite:
          text = await _tfliteService.extractTextFromImage(imagePath);
          confidence = 0.7; // Dépend du modèle entraîné
          break;
      }

      stopwatch.stop();
      
      return OCRResult(
        text: text,
        engine: engine,
        confidence: confidence,
        processingTime: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      throw Exception('Erreur OCR avec ${engine.name}: $e');
    }
  }

  /// Extrait le texte d'un XFile
  Future<OCRResult> extractTextFromXFile(
    XFile imageFile, {
    OCREngine engine = OCREngine.mlkit,
  }) async {
    return await extractText(imageFile.path, engine: engine);
  }

  /// Essaie tous les engines et retourne le meilleur résultat
  Future<OCRResult> extractTextWithAllEngines(String imagePath) async {
    final results = <OCRResult>[];
    
    // Essayer ML Kit
    try {
      final mlkitResult = await extractText(imagePath, engine: OCREngine.mlkit);
      results.add(mlkitResult);
    } catch (e) {
      print('ML Kit échoué: $e');
    }

    // Essayer Tesseract
    try {
      final tesseractResult = await extractText(imagePath, engine: OCREngine.tesseract);
      results.add(tesseractResult);
    } catch (e) {
      print('Tesseract échoué: $e');
    }

    // Essayer TensorFlow Lite
    try {
      final tfliteResult = await extractText(imagePath, engine: OCREngine.tflite);
      results.add(tfliteResult);
    } catch (e) {
      print('TensorFlow Lite échoué: $e');
    }

    if (results.isEmpty) {
      throw Exception('Tous les engines OCR ont échoué');
    }

    // Retourner le résultat avec la meilleure confiance
    results.sort((a, b) => b.confidence.compareTo(a.confidence));
    return results.first;
  }

  /// Vérifie la disponibilité des engines
  Future<Map<OCREngine, bool>> checkEnginesAvailability() async {
    return {
      OCREngine.mlkit: true, // ML Kit est toujours disponible
      OCREngine.tesseract: await _tesseractService.isAvailable(),
      OCREngine.tflite: false, // Nécessite un modèle
    };
  }

  /// Libère les ressources
  void dispose() {
    _mlkitService.dispose();
    _tfliteService.dispose();
  }
}