import 'dart:async';
import 'package:epub_to_audio/models/voice_model.dart';

/// Interface abstraite pour les services TTS
abstract class TTSService {
  /// Initialise le service TTS
  Future<void> initialize();

  /// Récupère la liste des voix disponibles
  Future<List<VoiceModel>> getAvailableVoices();

  /// Définit la voix à utiliser
  Future<void> setVoice(String voice);

  /// Synthétise le texte en audio
  Future<void> speak(String text);

  /// Synthétise le texte en fichier audio
  Future<void> synthesizeToFile(String text, {required String outputFile});

  /// Arrête la synthèse en cours
  Future<void> stop();

  /// Pause la synthèse
  Future<void> pause();

  /// Reprend la synthèse
  Future<void> resume();

  /// Vérifie si le service est en train de parler
  Future<bool> isSpeaking();

  /// Définit la langue à utiliser
  Future<void> setLanguage(String language);

  /// Définit le pitch de la voix (0.0 à 2.0)
  Future<void> setPitch(double pitch);

  /// Définit la vitesse de parole (0.0 à 2.0)
  Future<void> setRate(double rate);

  /// Définit le volume (0.0 à 1.0)
  Future<void> setVolume(double volume);

  /// Libère les ressources
  Future<void> dispose();

  /// Stream d'événements de progression
  Stream<TTSEvent> get onProgress;

  /// Stream d'événements de fin de synthèse
  Stream<void> get onComplete;

  /// Stream d'erreurs
  Stream<String> get onError;
}

/// Événement de progression de la synthèse
class TTSEvent {
  final String text;
  final int startOffset;
  final int endOffset;
  final String word;

  TTSEvent({
    required this.text,
    required this.startOffset,
    required this.endOffset,
    required this.word,
  });
}

/// Type de moteur TTS
enum TTSEngineType {
  flutterTTS,
  edgeTTS,
}
