import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import '../models/chapter.dart';
import 'tts/tts_service.dart';

extension FutureStateExtension on Future {
  bool get isDone {
    var done = false;
    var error = false;
    this.then((_) => done = true).catchError((_) => error = true);
    return done || error;
  }
}

class ChapterConversionService {
  final TTSService ttsService;
  final String outputDirectory;
  final List<Chapter> chapters;
  final Function(double) onProgressUpdate;
  final Function(String) onError;
  final int maxConcurrentConversions;
  bool _isConverting = false;
  int _completedChapters = 0;
  final List<Future> _activeFutures = [];

  static const _platform = MethodChannel('com.example.epub_to_audio/service');

  ChapterConversionService({
    required this.ttsService,
    required this.outputDirectory,
    required this.chapters,
    required this.onProgressUpdate,
    required this.onError,
    required this.maxConcurrentConversions,
  });

  bool get isConverting => _isConverting;

  Future<void> startConversion() async {
    if (_isConverting) return;
    _isConverting = true;
    _completedChapters = 0;
    _activeFutures.clear();

    try {
      await _platform.invokeMethod('startConversionService');
      await _updateProgress(); // Initialiser la progression à 0
      
      for (var chapter in chapters) {
        if (!_isConverting) break;
        
        // Attendre si nous avons atteint le maximum de conversions parallèles
        while (_activeFutures.length >= maxConcurrentConversions) {
          await Future.any(_activeFutures);
          _activeFutures.removeWhere((future) => future.isDone);
        }
        
        // Créer et suivre la nouvelle conversion
        final completer = Completer<void>();
        final future = _convertChapter(chapter).then((_) {
          _completedChapters++;
          _updateProgress();
          completer.complete();
        }).catchError((error) {
          completer.completeError(error);
        });
        
        _activeFutures.add(completer.future);
      }
      
      // Attendre que toutes les conversions restantes se terminent
      if (_activeFutures.isNotEmpty) {
        await Future.wait(_activeFutures);
      }
      
    } catch (e) {
      print('Erreur lors de la conversion: $e');
      onError(e.toString());
    } finally {
      _isConverting = false;
      _activeFutures.clear();
      try {
        await _platform.invokeMethod('stopConversionService');
      } catch (e) {
        print('Erreur lors de l\'arrêt du service: $e');
      }
    }
  }

  Future<void> stopConversion() async {
    _isConverting = false;
    try {
      await _platform.invokeMethod('stopConversionService');
    } catch (e) {
      print('Erreur lors de l\'arrêt du service: $e');
      onError('Erreur lors de l\'arrêt de la conversion: $e');
    }
  }

  Future<void> _convertChapter(Chapter chapter) async {
    try {
      final outputPath = path.join(
        outputDirectory,
        'chapitre_${_formatChapterNumber(chapter.chapterNumber)}_${chapter.title.replaceAll(' ', '_')}.mp3'
      );
      
      print('Début de la conversion du chapitre ${chapter.chapterNumber}');
      await ttsService.synthesizeToFile(chapter.content, outputFile: outputPath);
      print('Fin de la conversion du chapitre ${chapter.chapterNumber}');
      
    } catch (e) {
      print('Erreur lors de la conversion du chapitre ${chapter.chapterNumber}: $e');
      onError('Erreur lors de la conversion du chapitre ${chapter.chapterNumber}: $e');
      rethrow;
    }
  }

  Future<void> _updateProgress() async {
    final progress = _completedChapters / chapters.length;
    onProgressUpdate(progress);
    
    try {
      print('Mise à jour de la progression: $_completedChapters/${chapters.length}');
      await _platform.invokeMethod('updateProgress', {
        'progress': _completedChapters,
        'total': chapters.length,
      });
    } catch (e) {
      print('Erreur lors de la mise à jour de la progression: $e');
    }
  }

  static String _formatChapterNumber(int number) {
    return number.toString().padLeft(3, '0');
  }
}
