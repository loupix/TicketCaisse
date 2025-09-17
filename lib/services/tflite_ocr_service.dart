// Service TensorFlow Lite désactivé
// import 'dart:io';
// import 'dart:typed_data';
// import 'package:tflite_flutter/tflite_flutter.dart';
// import 'package:image/image.dart' as img;

class TensorFlowLiteOCRService {
  static final TensorFlowLiteOCRService _instance = TensorFlowLiteOCRService._internal();
  factory TensorFlowLiteOCRService() => _instance;
  TensorFlowLiteOCRService._internal();

  // Interpreter? _interpreter;
  bool _isInitialized = false;

  /// Initialise le modèle TensorFlow Lite
  Future<void> initialize() async {
    try {
      // Service désactivé
      _isInitialized = false;
      throw Exception('TensorFlow Lite désactivé');
    } catch (e) {
      throw Exception('Erreur initialisation TensorFlow Lite: $e');
    }
  }

  /// Prétraite une image pour le modèle
  // Uint8List _preprocessImage(String imagePath) {
  //   final image = img.decodeImage(File(imagePath).readAsBytesSync());
  //   if (image == null) throw Exception('Impossible de charger l\'image');
  //   // Service désactivé
  //   return Uint8List(0);
  // }

  /// Extrait le texte avec TensorFlow Lite
  Future<String> extractTextFromImage(String imagePath) async {
    throw Exception('TensorFlow Lite OCR désactivé');
  }

  /// Décode la sortie du modèle en texte
  // String _decodeOutput(List<double> output) {
  //   return '';
  // }

  /// Libère les ressources
  void dispose() {
    // _interpreter?.close();
    _isInitialized = false;
  }
}