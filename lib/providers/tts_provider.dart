import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epub_to_audio/services/tts/tts_service.dart';
import 'package:epub_to_audio/services/tts/flutter_tts_service.dart';
import 'package:epub_to_audio/services/tts/edge_tts_service.dart';
import 'package:epub_to_audio/models/voice_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

// ID unique pour forcer le rechargement des voix
final _voicesLoadingKey = StateProvider<int>((ref) => 0);

enum TTSEngineType {
  flutterTts,
  edgeTts,
}

final ttsEngineProvider = StateNotifierProvider<TTSEngineNotifier, TTSEngineType>((ref) {
  return TTSEngineNotifier(ref);
});

class TTSEngineNotifier extends StateNotifier<TTSEngineType> {
  final Ref _ref;
  
  TTSEngineNotifier(this._ref) : super(TTSEngineType.flutterTts) {
    _loadSavedEngine();
  }

  Future<void> _loadSavedEngine() async {
    final prefs = await SharedPreferences.getInstance();
    final engineIndex = prefs.getInt('tts_engine') ?? 0;
    state = TTSEngineType.values[engineIndex];
  }

  Future<void> setEngine(TTSEngineType engine) async {
    debugPrint('TTSEngineNotifier: Changement de moteur vers ${engine.toString()}');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tts_engine', engine.index);
    state = engine;
    
    // Forcer le rechargement des voix
    _ref.read(_voicesLoadingKey.notifier).state++;
    
    // Réinitialiser la voix sélectionnée
    _ref.read(selectedVoiceProvider.notifier).reset();
  }
}

final ttsServiceProvider = Provider<TTSService>((ref) {
  final engine = ref.watch(ttsEngineProvider);
  switch (engine) {
    case TTSEngineType.flutterTts:
      return FlutterTTSService();
    case TTSEngineType.edgeTts:
      return EdgeTTSService();
  }
});

final availableVoicesProvider = FutureProvider.autoDispose<List<VoiceModel>>((ref) async {
  debugPrint('availableVoicesProvider: Début de la récupération des voix');
  
  // Observer le compteur de rechargement
  ref.watch(_voicesLoadingKey);
  
  final ttsService = ref.watch(ttsServiceProvider);
  try {
    debugPrint('availableVoicesProvider: Appel de getAvailableVoices()');
    final voices = await ttsService.getAvailableVoices();
    debugPrint('availableVoicesProvider: ${voices.length} voix récupérées');
    
    if (voices.isEmpty) {
      debugPrint('availableVoicesProvider: Aucune voix disponible');
      throw Exception('Aucune voix disponible pour ce moteur TTS');
    }
    
    return voices;
  } catch (e) {
    debugPrint('availableVoicesProvider: Erreur: $e');
    throw Exception('Erreur lors du chargement des voix: $e');
  }
});

final selectedVoiceProvider = StateNotifierProvider<SelectedVoiceNotifier, String?>((ref) {
  return SelectedVoiceNotifier(ref);
});

class SelectedVoiceNotifier extends StateNotifier<String?> {
  final Ref _ref;
  bool _mounted = true;
  bool _isLoading = false;
  
  SelectedVoiceNotifier(this._ref) : super(null) {
    if (_mounted) {
      _loadSavedVoice();
    }
  }

  Future<void> _loadSavedVoice() async {
    if (!_mounted || _isLoading) return;
    
    _isLoading = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedVoice = prefs.getString('selected_voice');
      if (savedVoice != null && _mounted) {
        debugPrint('SelectedVoiceNotifier: Chargement de la voix sauvegardée: $savedVoice');
        await _setVoiceInService(savedVoice);
        if (_mounted) {
          state = savedVoice;
        }
      }
    } catch (e) {
      debugPrint('SelectedVoiceNotifier: Erreur lors du chargement de la voix: $e');
      if (_mounted) {
        state = null;
      }
    } finally {
      _isLoading = false;
    }
  }

  Future<void> setVoice(String voiceId) async {
    if (!_mounted || _isLoading) return;
    
    _isLoading = true;
    try {
      debugPrint('SelectedVoiceNotifier: Sélection de la voix $voiceId');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_voice', voiceId);
      await _setVoiceInService(voiceId);
      if (_mounted) {
        state = voiceId;
      }
    } finally {
      _isLoading = false;
    }
  }
  
  Future<void> _setVoiceInService(String voiceId) async {
    if (!_mounted) return;
    
    final ttsService = _ref.read(ttsServiceProvider);
    debugPrint('SelectedVoiceNotifier: Mise à jour de la voix dans le service: $voiceId');
    await ttsService.setVoice(voiceId);
  }
  
  void reset() {
    if (!_mounted) return;
    
    debugPrint('SelectedVoiceNotifier: Réinitialisation de la voix sélectionnée');
    state = null;
  }
  
  @override
  void dispose() {
    debugPrint('SelectedVoiceNotifier: Disposing...');
    _mounted = false;
    super.dispose();
  }
}
