import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class MLKitOCRService {
  static final MLKitOCRService _instance = MLKitOCRService._internal();
  factory MLKitOCRService() => _instance;
  MLKitOCRService._internal();

  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  /// Extrait le texte d'une image avec ML Kit Text Recognition v2
  Future<String> extractTextFromImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      return recognizedText.text;
    } catch (e) {
      throw Exception('Erreur ML Kit OCR: $e');
    }
  }

  /// Extrait le texte d'un XFile (image picker)
  Future<String> extractTextFromXFile(XFile imageFile) async {
    try {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      return recognizedText.text;
    } catch (e) {
      throw Exception('Erreur ML Kit OCR: $e');
    }
  }

  /// Extrait le texte avec détails des blocs de texte
  Future<List<TextBlock>> extractTextBlocks(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      return recognizedText.blocks;
    } catch (e) {
      throw Exception('Erreur ML Kit OCR: $e');
    }
  }

  /// Libère les ressources
  void dispose() {
    _textRecognizer.close();
  }
}