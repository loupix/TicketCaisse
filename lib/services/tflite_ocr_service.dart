import 'dart:io';
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class TensorFlowLiteOCRService {
  static final TensorFlowLiteOCRService _instance = TensorFlowLiteOCRService._internal();
  factory TensorFlowLiteOCRService() => _instance;
  TensorFlowLiteOCRService._internal();

  Interpreter? _interpreter;
  bool _isInitialized = false;

  /// Initialise le modèle TensorFlow Lite
  Future<void> initialize() async {
    try {
      // Charger le modèle depuis les assets
      _interpreter = await Interpreter.fromAsset('assets/models/ocr_model.tflite');
      _isInitialized = true;
    } catch (e) {
      throw Exception('Erreur initialisation TensorFlow Lite: $e');
    }
  }

  /// Prétraite une image pour le modèle
  Uint8List _preprocessImage(String imagePath) {
    final image = img.decodeImage(File(imagePath).readAsBytesSync());
    if (image == null) throw Exception('Impossible de charger l\'image');

    // Redimensionner à 32x128 (format typique pour OCR)
    final resized = img.copyResize(image, width: 32, height: 128);
    
    // Convertir en niveaux de gris
    final grayscale = img.grayscale(resized);
    
    // Normaliser les pixels (0-1)
    final pixels = grayscale.getBytes();
    final normalized = pixels.map((p) => p / 255.0).toList();
    
    return Uint8List.fromList(normalized);
  }

  /// Extrait le texte avec TensorFlow Lite
  Future<String> extractTextFromImage(String imagePath) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final input = _preprocessImage(imagePath);
      final output = List.filled(1, List.filled(100, 0.0)); // Ajuster selon le modèle
      
      _interpreter!.run(input, output);
      
      // Convertir les prédictions en texte
      return _decodeOutput(output[0]);
    } catch (e) {
      throw Exception('Erreur TensorFlow Lite OCR: $e');
    }
  }

  /// Décode la sortie du modèle en texte
  String _decodeOutput(List<double> output) {
    // Implémentation basique - à adapter selon le modèle
    final chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    final result = StringBuffer();
    
    for (int i = 0; i < output.length; i += 2) {
      final charIndex = output[i].round();
      if (charIndex >= 0 && charIndex < chars.length) {
        result.write(chars[charIndex]);
      }
    }
    
    return result.toString();
  }

  /// Libère les ressources
  void dispose() {
    _interpreter?.close();
    _isInitialized = false;
  }
}