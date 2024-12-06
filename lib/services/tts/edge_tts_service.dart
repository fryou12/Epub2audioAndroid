import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:epub_to_audio/services/tts/tts_service.dart';
import 'package:epub_to_audio/models/voice_model.dart';

class EdgeTTSService implements TTSService {
  static const platform = MethodChannel('com.example.epub_to_audio/python');
  
  final _progressController = StreamController<TTSEvent>.broadcast();
  final _completeController = StreamController<void>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  
  String? _selectedVoice;
  bool _isInitialized = false;
  bool _isSpeaking = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('EdgeTTSService: Initialisation...');
      final result = await platform.invokeMethod('checkPythonAvailable');
      debugPrint('EdgeTTSService: Python disponible: $result');
      _isInitialized = true;
    } catch (e) {
      debugPrint('EdgeTTSService: Erreur d\'initialisation: $e');
      _errorController.add('Erreur d\'initialisation du service TTS: $e');
      rethrow;
    }
  }

  @override
  Future<List<VoiceModel>> getAvailableVoices() async {
    try {
      debugPrint('EdgeTTSService: Vérification de l\'initialisation...');
      if (!_isInitialized) {
        await initialize();
      }

      final voicesJson = await _getVoicesJson();
      debugPrint('EdgeTTSService: Voix reçues: $voicesJson');
      
      // Utiliser compute pour le parsing JSON et la conversion des voix
      final voices = await compute(_parseVoices, voicesJson);
      
      if (voices.isEmpty) {
        throw Exception('Aucune voix disponible. Vérifiez votre connexion Internet.');
      }
      
      return voices;
    } catch (e) {
      debugPrint('EdgeTTSService: Erreur lors de la récupération des voix: $e');
      _errorController.add(e.toString());
      rethrow;
    }
  }

  // Fonction statique pour le parsing des voix dans un isolate
  static List<VoiceModel> _parseVoices(String voicesJson) {
    final List<dynamic> voices = jsonDecode(voicesJson) as List<dynamic>;
    return voices.map((voice) {
      try {
        return VoiceModel(
          id: voice['ShortName'] as String,
          name: voice['FriendlyName'] as String,
          language: voice['Locale'] as String,
          gender: voice['Gender'] as String,
        );
      } catch (e) {
        debugPrint('EdgeTTSService: Erreur lors du parsing de la voix: $voice');
        rethrow;
      }
    }).toList();
  }

  @override
  Future<void> setVoice(String voice) async {
    debugPrint('EdgeTTSService: Sélection de la voix: $voice');
    
    if (!_isInitialized) {
      throw Exception('Le service TTS n\'est pas initialisé');
    }

    final voices = await getAvailableVoices();
    if (!voices.any((v) => v.id == voice)) {
      debugPrint('EdgeTTSService: Voix non trouvée, utilisation d\'une voix par défaut');
      
      // Essayer de trouver une voix française féminine
      final defaultVoice = voices.firstWhere(
        (v) => v.language.startsWith('fr-FR') && v.gender == 'Female',
        orElse: () => voices.firstWhere(
          (v) => v.language.startsWith('fr-'),
          orElse: () => voices.first,
        ),
      );
      
      _selectedVoice = defaultVoice.id;
      debugPrint('EdgeTTSService: Voix par défaut sélectionnée: ${defaultVoice.id}');
    } else {
      _selectedVoice = voice;
    }
  }

  @override
  Future<void> speak(String text) async {
    if (!_isInitialized) {
      throw Exception('Le service TTS n\'est pas initialisé');
    }

    if (_isSpeaking) {
      await stop();
    }

    _isSpeaking = true;

    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = path.join(tempDir.path, 'temp_audio.mp3');

      await synthesizeToFile(text, outputFile: tempFile);

      _audioPlayer.positionStream.listen((duration) {
        final words = text.split(' ');
        final wordIndex = (duration.inMilliseconds / 200).floor(); // Estimation grossière
        if (wordIndex < words.length) {
          _progressController.add(TTSEvent(
            text: text,
            startOffset: wordIndex,
            endOffset: words.length,
            word: words[wordIndex],
          ));
        }
      });

      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _isSpeaking = false;
          final words = text.split(' ');
          _progressController.add(TTSEvent(
            text: text,
            startOffset: words.length - 1,
            endOffset: words.length,
            word: words.last,
          ));
          _completeController.add(null);
        }
      });

      await _audioPlayer.setFilePath(tempFile);
      await _audioPlayer.play();
    } catch (e) {
      _isSpeaking = false;
      debugPrint('EdgeTTSService: Erreur lors de la synthèse: $e');
      _errorController.add(e.toString());
      rethrow;
    }
  }

  @override
  Future<void> synthesize(String text) async {
    if (!_isInitialized) {
      throw Exception('Le service TTS n\'est pas initialisé');
    }

    if (_selectedVoice == null) {
      throw Exception('Aucune voix sélectionnée');
    }

    try {
      debugPrint('EdgeTTSService: Synthèse du texte...');
      _isSpeaking = true;
      
      final directory = await getTemporaryDirectory();
      final outputFile = '${directory.path}/tts_output.mp3';
      
      await synthesizeToFile(text, outputFile: outputFile);
      
      // TODO: Implémenter la lecture audio avec just_audio
      
      _isSpeaking = false;
      _completeController.add(null);
    } catch (e) {
      _isSpeaking = false;
      debugPrint('EdgeTTSService: Erreur lors de la synthèse: $e');
      _errorController.add('Erreur lors de la synthèse: $e');
      rethrow;
    }
  }

  @override
  Future<void> synthesizeToFile(String text, {required String outputFile}) async {
    if (!_isInitialized) {
      debugPrint('EdgeTTSService: Service non initialisé');
      throw Exception('Le service TTS n\'est pas initialisé');
    }

    debugPrint('EdgeTTSService: Vérification de la voix sélectionnée: $_selectedVoice');
    if (_selectedVoice == null) {
      debugPrint('EdgeTTSService: Aucune voix sélectionnée');
      throw Exception('Aucune voix sélectionnée');
    }

    try {
      debugPrint('EdgeTTSService: Début de la synthèse vers le fichier: $outputFile');
      debugPrint('EdgeTTSService: Utilisation de la voix: $_selectedVoice');
      
      final result = await platform.invokeMethod('synthesize', {
        'text': text,
        'voiceId': _selectedVoice,
        'outputFile': outputFile,
      });
      
      debugPrint('EdgeTTSService: Résultat de la synthèse reçu');
      final response = json.decode(result);
      if (response['error'] != null) {
        debugPrint('EdgeTTSService: Erreur dans la réponse: ${response['error']}');
        throw Exception(response['error']);
      }
      
      if (!await File(outputFile).exists()) {
        debugPrint('EdgeTTSService: Le fichier de sortie n\'existe pas: $outputFile');
        throw Exception('Le fichier audio n\'a pas été créé');
      }
      
      debugPrint('EdgeTTSService: Synthèse terminée avec succès');
    } catch (e) {
      debugPrint('EdgeTTSService: Erreur lors de la synthèse vers le fichier: $e');
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    await _audioPlayer.stop();
    _isSpeaking = false;
  }

  @override
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  @override
  Future<void> resume() async {
    await _audioPlayer.play();
  }

  @override
  Future<bool> isSpeaking() async {
    return _isSpeaking;
  }

  @override
  Stream<TTSEvent> get onProgress => _progressController.stream;

  @override
  Stream<void> get onComplete => _completeController.stream;

  @override
  Stream<String> get onError => _errorController.stream;

  @override
  Future<void> setLanguage(String language) async {
    // La langue est gérée par la sélection de la voix
  }

  @override
  Future<void> setPitch(double pitch) async {
    // Non supporté par Edge TTS
  }

  @override
  Future<void> setRate(double rate) async {
    // Non supporté par Edge TTS
  }

  @override
  Future<void> setVolume(double volume) async {
    // Non supporté par Edge TTS
  }

  @override
  Future<void> dispose() async {
    await _audioPlayer.dispose();
    await _progressController.close();
    await _completeController.close();
    await _errorController.close();
  }

  Future<String> _getVoicesJson() async {
    try {
      final result = await platform.invokeMethod('getVoices');
      if (result == null) {
        throw Exception('Aucune réponse du service TTS');
      }
      
      // Vérifier si le résultat est une erreur
      try {
        final dynamic decoded = jsonDecode(result);
        if (decoded is Map<String, dynamic> && decoded.containsKey('error')) {
          throw Exception(decoded['error']);
        }
      } catch (e) {
        // Si le décodage échoue, c'est probablement une liste de voix valide
      }
      
      return result;
    } catch (e) {
      debugPrint('EdgeTTSService: Erreur lors de la récupération des voix: $e');
      rethrow;
    }
  }

  Future<void> _emitProgress(String text, int wordIndex, int totalWords) {
    final words = text.split(' ');
    _progressController.add(TTSEvent(
      text: text,
      startOffset: wordIndex,
      endOffset: totalWords,
      word: words[wordIndex],
    ));
    return Future.value();
  }

  Future<void> _emitComplete(String text) {
    final words = text.split(' ');
    _progressController.add(TTSEvent(
      text: text,
      startOffset: words.length - 1,
      endOffset: words.length,
      word: words.last,
    ));
    _completeController.add(null);
    return Future.value();
  }
}
