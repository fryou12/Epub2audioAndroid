import 'package:shared_preferences/shared_preferences.dart';
import 'edge_tts_service.dart';

class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  final EdgeTTSService _edgeTTS = EdgeTTSService();
  Map<String, dynamic> _settings = {
    'maxParallelChapters': 3,
    'voice_settings': {
      'rate': '+0%',
      'volume': '+0%',
      'pitch': '+0Hz',
    }
  };

  Future<void> initialize() async {
    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('tts_settings');
    if (settingsJson != null) {
      _settings = Map<String, dynamic>.from(
        Map.from(settingsJson as Map)
      );
      _edgeTTS.updateSettings(_settings['voice_settings']);
    }
  }

  Future<List<VoiceInfo>> getAvailableVoices() async {
    return await _edgeTTS.getVoices();
  }

  Future<void> setVoice(String voiceName) async {
    _edgeTTS.setVoice(voiceName);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_voice', voiceName);
  }

  Future<String?> getCurrentVoice() async {
    return _edgeTTS.getCurrentVoice();
  }

  Future<String> speak(String text) async {
    final voice = _edgeTTS.getCurrentVoice();
    if (voice == null) throw Exception('No voice selected');
    return await _edgeTTS.synthesize(text, voice);
  }

  Future<List<String>> generateAudioForChapters(List<Map<String, String>> chapters) async {
    final voice = _edgeTTS.getCurrentVoice();
    if (voice == null) throw Exception('No voice selected');

    final maxParallel = _settings['maxParallelChapters'] as int;
    List<String> outputFiles = [];

    for (var i = 0; i < chapters.length; i += maxParallel) {
      final batch = chapters.skip(i).take(maxParallel);
      final futures = batch.map((chapter) async {
        return await _edgeTTS.synthesize(chapter['content']!, voice);
      });
      outputFiles.addAll(await Future.wait(futures));
    }

    return outputFiles;
  }

  Future<void> updateSettings(Map<String, dynamic> newSettings) async {
    _settings = newSettings;
    _edgeTTS.updateSettings(newSettings['voice_settings']);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tts_settings', newSettings.toString());
  }

  void dispose() {
    // Nettoyage des ressources si nécessaire
  }
}
