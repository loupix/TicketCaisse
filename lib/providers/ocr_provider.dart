import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ocr_manager.dart';
import '../services/ticket_parser.dart';
import '../models/ticket_data.dart';

class OCRState {
  final bool isLoading;
  final String? extractedText;
  final TicketData? ticketData;
  final String? error;
  final OCREngine selectedEngine;
  final Duration? processingTime;
  final String? lastImagePath;

  OCRState({
    this.isLoading = false,
    this.extractedText,
    this.ticketData,
    this.error,
    this.selectedEngine = OCREngine.mlkit,
    this.processingTime,
    this.lastImagePath,
  });

  OCRState copyWith({
    bool? isLoading,
    String? extractedText,
    TicketData? ticketData,
    String? error,
    OCREngine? selectedEngine,
    Duration? processingTime,
    String? lastImagePath,
  }) {
    return OCRState(
      isLoading: isLoading ?? this.isLoading,
      extractedText: extractedText ?? this.extractedText,
      ticketData: ticketData ?? this.ticketData,
      error: error ?? this.error,
      selectedEngine: selectedEngine ?? this.selectedEngine,
      processingTime: processingTime ?? this.processingTime,
      lastImagePath: lastImagePath ?? this.lastImagePath,
    );
  }
}

class OCRNotifier extends StateNotifier<OCRState> {
  OCRNotifier() : super(OCRState());

  final OCRManager _ocrManager = OCRManager();
  final TicketParser _parser = TicketParser();
  final ImagePicker _imagePicker = ImagePicker();

  /// Sélectionne une image depuis la galerie
  Future<void> pickImageFromGallery() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        state = state.copyWith(lastImagePath: image.path);
        await _processImage(image.path);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la sélection d\'image: $e',
      );
    }
  }

  /// Prend une photo avec la caméra
  Future<void> takePicture() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        state = state.copyWith(lastImagePath: image.path);
        await _processImage(image.path);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la prise de photo: $e',
      );
    }
  }

  /// Traite l'image avec OCR
  Future<void> _processImage(String imagePath) async {
    try {
      final result = await _ocrManager.extractText(
        imagePath,
        engine: state.selectedEngine,
      );

      final ticketData = _parser.parseTicket(result.text);

      state = state.copyWith(
        isLoading: false,
        extractedText: result.text,
        ticketData: ticketData,
        processingTime: result.processingTime,
        lastImagePath: imagePath,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur OCR: $e',
      );
    }
  }

  /// Change l'engine OCR
  void setOCREngine(OCREngine engine) {
    state = state.copyWith(selectedEngine: engine);
    final String? imagePath = state.lastImagePath;
    if (imagePath != null) {
      // Retraiter automatiquement avec le nouveau moteur
      reprocessWithEngine(engine);
    }
  }

  /// Efface les données
  void clear() {
    state = OCRState(selectedEngine: state.selectedEngine);
  }

  /// Retraite l'image avec un autre engine
  Future<void> reprocessWithEngine(OCREngine engine) async {
    final String? imagePath = state.lastImagePath;
    if (imagePath == null) return;

    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final result = await _ocrManager.extractText(
        imagePath,
        engine: engine,
      );

      final ticketData = _parser.parseTicket(result.text);

      state = state.copyWith(
        isLoading: false,
        extractedText: result.text,
        ticketData: ticketData,
        processingTime: result.processingTime,
        selectedEngine: engine,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur retraitement: $e',
      );
    }
  }
}

final ocrProvider = StateNotifierProvider<OCRNotifier, OCRState>((ref) {
  return OCRNotifier();
});