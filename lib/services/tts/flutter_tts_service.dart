import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';
import 'package:epub_to_audio/services/tts/tts_service.dart';
import 'package:epub_to_audio/models/voice_model.dart';

class FlutterTTSService implements TTSService {
  final FlutterTts _flutterTts = FlutterTts();
  final StreamController<TTSEvent> _progressController = StreamController<TTSEvent>.broadcast();
  final StreamController<void> _completeController = StreamController<void>.broadcast();
  final StreamController<String> _errorController = StreamController<String>.broadcast();
  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    await _flutterTts.setSharedInstance(true);
    _isInitialized = true;
    
    _flutterTts.setProgressHandler(_progressHandler);
    _flutterTts.setCompletionHandler(_completionHandler);
    _flutterTts.setErrorHandler(_errorHandler);
  }

  void _progressHandler(String text, int startOffset, int endOffset, String word) {
    _progressController.add(TTSEvent(
      text: text,
      startOffset: startOffset,
      endOffset: endOffset,
      word: word,
    ));
  }

  void _completionHandler() {
    _completeController.add(null);
  }

  void _errorHandler(dynamic message) {
    _errorController.add(message.toString());
  }

  @override
  Future<void> speak(String text) async {
    if (!_isInitialized) {
      throw Exception('Le service TTS n\'est pas initialisé');
    }

    try {
      debugPrint('FlutterTTSService: Synthèse vocale du texte: ${text.substring(0, 50)}...');
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('FlutterTTSService: Erreur lors de la synthèse vocale: $e');
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    await _flutterTts.stop();
  }

  @override
  Future<void> pause() async {
    await _flutterTts.pause();
  }

  @override
  Future<void> resume() async {
    await _flutterTts.speak('');
  }

  @override
  Future<void> setVoice(String voice) async {
    final voices = await getAvailableVoices();
    final selectedVoice = voices.firstWhere(
      (v) => v.id == voice,
      orElse: () => voices.first,
    );
    
    await _flutterTts.setVoice({
      "name": selectedVoice.name,
      "locale": selectedVoice.language,
    });
  }

  @override
  Future<void> setLanguage(String language) async {
    await _flutterTts.setLanguage(language);
  }

  @override
  Future<void> setRate(double rate) async {
    await _flutterTts.setSpeechRate(rate);
  }

  @override
  Future<void> setPitch(double pitch) async {
    await _flutterTts.setPitch(pitch);
  }

  @override
  Future<void> setVolume(double volume) async {
    await _flutterTts.setVolume(volume);
  }

  @override
  Future<void> synthesizeToFile(String text, {required String outputFile}) async {
    await _flutterTts.synthesizeToFile(text, outputFile);
  }

  @override
  Future<List<VoiceModel>> getAvailableVoices() async {
    try {
      final List<dynamic> voices = await _flutterTts.getVoices;
      return voices.map((voice) {
        final voiceMap = voice as Map<String, dynamic>;
        return VoiceModel(
          id: voiceMap['name'] ?? '',
          name: voiceMap['name'] ?? '',
          language: voiceMap['locale'] ?? '',
          gender: null,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting voices: $e');
      // Retourner une voix par défaut en cas d'erreur
      return [
        VoiceModel(
          id: 'default',
          name: 'Default Voice',
          language: 'fr-FR',
          gender: null,
        ),
      ];
    }
  }

  @override
  Future<bool> isSpeaking() async {
    try {
      return (await _flutterTts.getLanguages).isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _flutterTts.awaitSpeakCompletion(true);
    _progressController.close();
    _completeController.close();
    _errorController.close();
  }

  @override
  Stream<TTSEvent> get onProgress => _progressController.stream;

  @override
  Stream<void> get onComplete => _completeController.stream;

  @override
  Stream<String> get onError => _errorController.stream;
}
