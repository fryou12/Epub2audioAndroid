import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'edge_tts_service.dart';
import 'dart:convert';

class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  final EdgeTTSService _edgeTTS = EdgeTTSService();
  bool _isInitialized = false;
  String _currentEngine = 'Edge TTS';
  String? _selectedVoice;
  Map<String, dynamic> _settings = {
    'maxParallelChapters': 3,
    'voice_settings': {
      'rate': 1.0,
      'volume': 1.0,
      'pitch': 1.0,
    },
  };

  Future<void> initialize() async {
    if (!_isInitialized) {
      await _loadSettings();
      final savedVoice = await getCurrentVoice();
      if (savedVoice == null) {
        // Si aucune voix n'est sauvegardée, on met Remy par défaut
        await setVoice('fr-FR-RemyNeural');
      }
      await _flutterTts.setLanguage("fr-FR");
      await _flutterTts.setSpeechRate(_settings['voice_settings']['rate']);
      await _flutterTts.setVolume(_settings['voice_settings']['volume']);
      await _flutterTts.setPitch(_settings['voice_settings']['pitch']);
      _isInitialized = true;
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('tts_settings');
      if (settingsJson != null) {
        _settings = Map<String, dynamic>.from(json.decode(settingsJson));
      }
      _currentEngine = prefs.getString('current_engine') ?? 'Edge TTS';
      _selectedVoice = prefs.getString('selected_voice');
      _edgeTTS.updateSettings(_settings['voice_settings']);
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  List<String> getAvailableEngines() {
    return ['Edge TTS', 'System TTS'];
  }

  List<String> getAvailableLanguages(String engine) {
    if (engine == 'Edge TTS') {
      return ['fr-FR', 'en-US', 'en-GB', 'de-DE', 'es-ES', 'it-IT'];
    }
    return ['fr-FR', 'en-US'];
  }

  List<String> getAvailableVoices(String engine, String language) {
    if (engine == 'Edge TTS') {
      switch (language) {
        case 'fr-FR':
          return ['fr-FR-DeniseNeural', 'fr-FR-HenriNeural', 'fr-FR-AlainNeural', 'fr-FR-RemyNeural', 'fr-FR-VivienneNeural'];
        case 'en-US':
          return ['en-US-JennyNeural', 'en-US-GuyNeural', 'en-US-AriaNeural'];
        case 'en-GB':
          return ['en-GB-SoniaNeural', 'en-GB-RyanNeural', 'en-GB-LibbyNeural'];
        default:
          return [];
      }
    } else if (engine == 'System TTS') {
      // Ajout de plusieurs voix pour le moteur System TTS
      return ['Voice 1', 'Voice 2', 'Voice 3'];
    }
    return ['Default Voice'];
  }

  Future<void> setEngine(String engine) async {
    _currentEngine = engine;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_engine', engine);
    // Réinitialiser la voix sélectionnée lors du changement de moteur
    _selectedVoice = null;
  }

  Future<void> setVoice(String voice) async {
    if (voice.contains('Neural')) {
      _edgeTTS.setVoice(voice);
    } else {
      await _flutterTts.setVoice({"name": voice});
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_voice', voice);
    _selectedVoice = voice;
  }

  Future<void> setVoice2(String voice) async {
    await _flutterTts.setVoice({"name": voice});
  }

  Future<String?> getCurrentVoice() async {
    if (_selectedVoice != null) {
      return _selectedVoice;
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selected_voice');
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_currentEngine == 'Edge TTS') {
      final voice = _edgeTTS.getCurrentVoice();
      if (voice != null) {
        await _edgeTTS.synthesize(text, voice);
      }
    } else {
      await _flutterTts.speak(text);
    }
  }

  Future<void> stop() async {
    if (_currentEngine == 'Edge TTS') {
      // Implement stop for Edge TTS if needed
    } else {
      await _flutterTts.stop();
    }
  }

  Future<void> pause() async {
    if (_currentEngine == 'Edge TTS') {
      // Implement pause for Edge TTS if needed
    } else {
      await _flutterTts.pause();
    }
  }

  Future<void> setRate(double rate) async {
    _settings['voice_settings']['rate'] = rate;
    if (_currentEngine == 'Edge TTS') {
      _edgeTTS.updateSettings(_settings['voice_settings']);
    } else {
      await _flutterTts.setSpeechRate(rate);
    }
    await _saveSettings();
  }

  Future<void> setVolume(double volume) async {
    _settings['voice_settings']['volume'] = volume;
    if (_currentEngine == 'Edge TTS') {
      _edgeTTS.updateSettings(_settings['voice_settings']);
    } else {
      await _flutterTts.setVolume(volume);
    }
    await _saveSettings();
  }

  Future<void> setPitch(double pitch) async {
    _settings['voice_settings']['pitch'] = pitch;
    if (_currentEngine == 'Edge TTS') {
      _edgeTTS.updateSettings(_settings['voice_settings']);
    } else {
      await _flutterTts.setPitch(pitch);
    }
    await _saveSettings();
  }

  Future<void> updateSettings(Map<String, dynamic> newSettings) async {
    _settings = newSettings;
    _edgeTTS.updateSettings(_settings['voice_settings']);
    await _saveSettings();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tts_settings', json.encode(_settings));
  }

  Map<String, dynamic> getSettings() {
    return Map<String, dynamic>.from(_settings);
  }

  void dispose() {
    _flutterTts.stop();
  }
}
