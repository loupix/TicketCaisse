import 'dart:io';
import 'package:tesseract_ocr/tesseract_ocr.dart';
import 'package:image_picker/image_picker.dart';

class TesseractOCRService {
  static final TesseractOCRService _instance = TesseractOCRService._internal();
  factory TesseractOCRService() => _instance;
  TesseractOCRService._internal();

  /// Extrait le texte d'une image avec Tesseract OCR
  Future<String> extractTextFromImage(String imagePath) async {
    try {
      final result = await TesseractOcr.extractText(
        imagePath,
        language: 'fra+eng', // Français + Anglais
        args: {
          'psm': '6', // Uniform block of text
          'oem': '3', // Default OCR Engine Mode
        },
      );
      
      return result ?? '';
    } catch (e) {
      throw Exception('Erreur Tesseract OCR: $e');
    }
  }

  /// Extrait le texte d'un XFile (image picker)
  Future<String> extractTextFromXFile(XFile imageFile) async {
    return await extractTextFromImage(imageFile.path);
  }

  /// Extrait le texte avec configuration personnalisée
  Future<String> extractTextWithConfig(
    String imagePath, {
    String language = 'fra+eng',
    int psm = 6,
    int oem = 3,
  }) async {
    try {
      final result = await TesseractOcr.extractText(
        imagePath,
        language: language,
        args: {
          'psm': psm.toString(),
          'oem': oem.toString(),
        },
      );
      
      return result ?? '';
    } catch (e) {
      throw Exception('Erreur Tesseract OCR: $e');
    }
  }

  /// Vérifie si Tesseract est disponible
  Future<bool> isAvailable() async {
    try {
      await TesseractOcr.extractText('', language: 'fra');
      return true;
    } catch (e) {
      return false;
    }
  }
}