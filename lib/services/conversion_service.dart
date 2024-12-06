import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class ConversionService {
  static const platform = MethodChannel('com.example.epub_to_audio/conversion');
  static StreamController<int> _progressController = StreamController<int>.broadcast();
  static bool _isConverting = false;
  
  static Stream<int> get progressStream => _progressController.stream;
  static bool get isConverting => _isConverting;
  
  static Future<void> startConversion() async {
    if (_isConverting) return;
    
    try {
      debugPrint('Démarrage du service de conversion...');
      _isConverting = true;
      
      // Réinitialiser le contrôleur de progression
      if (_progressController.isClosed) {
        _progressController = StreamController<int>.broadcast();
      }
      
      // Démarrer le service en arrière-plan avec l'action START_CONVERSION
      await platform.invokeMethod('startConversionService', {
        'action': 'START_CONVERSION'
      });
      
      debugPrint('Service de conversion démarré');
    } catch (e) {
      debugPrint('Erreur lors du démarrage du service de conversion: $e');
      _isConverting = false;
      rethrow;
    }
  }
  
  static Future<void> updateProgress(int progress) async {
    try {
      debugPrint('Mise à jour de la progression: $progress%');
      // Envoyer l'action UPDATE_PROGRESS avec la progression
      await platform.invokeMethod('updateConversionProgress', {
        'action': 'UPDATE_PROGRESS',
        'progress': progress
      });
      _progressController.add(progress);
      
      // Si la conversion est terminée, arrêter le service
      if (progress >= 100) {
        await stopConversion();
      }
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour de la progression: $e');
    }
  }
  
  static Future<void> stopConversion() async {
    if (!_isConverting) return;
    
    try {
      debugPrint('Arrêt du service de conversion...');
      // Envoyer l'action STOP_CONVERSION
      await platform.invokeMethod('stopConversionService', {
        'action': 'STOP_CONVERSION'
      });
      _isConverting = false;
      await _progressController.close();
      debugPrint('Service de conversion arrêté');
    } catch (e) {
      debugPrint('Erreur lors de l\'arrêt du service de conversion: $e');
      rethrow;
    }
  }
  
  static void dispose() {
    if (!_progressController.isClosed) {
      _progressController.close();
    }
  }
}
