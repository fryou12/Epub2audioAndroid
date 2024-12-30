import 'dart:io';
import 'package:epub3/epub3.dart';
import 'package:html/parser.dart' as html;
import '../models/chapter.dart' as app_chapter;
import 'package:path/path.dart' as path;
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:permission_handler/permission_handler.dart';

class EpubService {
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      if (status.isDenied) {
        final result = await Permission.storage.request();
        if (result.isDenied) {
          return false;
        }
      }
      
      // Pour Android 11 (API level 30) et plus
      if (await Permission.manageExternalStorage.isRestricted) {
        final result = await Permission.manageExternalStorage.request();
        return result.isGranted;
      }
    }
    return true;
  }

  static Future<List<app_chapter.Chapter>> extractChapters(String filePath) async {
    final List<app_chapter.Chapter> chapters = [];
    final File file = File(filePath);
    
    try {
      // Vérifier les permissions avant de lire le fichier
      if (!await requestStoragePermission()) {
        throw Exception('Permission de stockage refusée');
      }
      
      // Lecture du fichier EPUB
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final reader = Reader.open(archive);
      final book = reader.read();
      
      if (book == null) {
        throw Exception('Impossible de lire le livre EPUB');
      }
      
      // Extraction des chapitres depuis la navigation
      if (book.navigation.chapters.isNotEmpty) {
        int index = 0;
        for (var chapter in book.navigation.chapters) {
          try {
            // Récupération du contenu via href
            if (chapter.href != null) {
              final content = reader.readFile(chapter.href!);
              if (content != null) {
                // Parse le contenu HTML pour extraire le texte brut
                final document = html.parse(utf8.decode(content.content));
                final text = document.body?.text ?? '';
                
                chapters.add(app_chapter.Chapter(
                  title: chapter.title,
                  content: text,
                  index: index,
                  isProcessing: false,
                  audioPath: '',
                ));
                index++;
              }
            }
          } catch (e) {
            print('Erreur lors de la lecture du chapitre ${index + 1}: $e');
            continue;
          }
        }
      }
      
      // Si aucun chapitre n'a été trouvé, on essaie d'extraire directement depuis les ressources
      if (chapters.isEmpty) {
        final htmlItems = book.manifest.items.where((item) {
          final mediaType = item.mediaType.toLowerCase();
          return mediaType.contains('html') || mediaType.contains('xhtml');
        }).toList();
        
        int index = 0;
        for (var item in htmlItems) {
          try {
            // Vérification que href n'est pas null
            if (item.href != null) {
              final content = reader.readFile(item.href!);
              if (content != null) {
                final document = html.parse(utf8.decode(content.content));
                final text = document.body?.text ?? '';
                
                // Tente d'extraire un titre du document HTML
                final titleElement = document.querySelector('h1, h2, h3, h4, h5, h6');
                final title = titleElement?.text ?? 'Chapitre ${index + 1}';
                
                chapters.add(app_chapter.Chapter(
                  title: title,
                  content: text,
                  index: index,
                  isProcessing: false,
                  audioPath: '',
                ));
                index++;
              }
            }
          } catch (e) {
            print('Erreur lors de la lecture de la ressource ${item.href}: $e');
            continue;
          }
        }
      }
      
      return chapters;
    } catch (e) {
      print('Erreur lors de l\'extraction des chapitres: $e');
      return [];
    }
  }

  static Future<void> saveChapters(List<app_chapter.Chapter> chapters, String outputDir) async {
    try {
      // Vérifier les permissions avant d'écrire
      if (!await requestStoragePermission()) {
        throw Exception('Permission de stockage refusée');
      }
      
      final directory = Directory(outputDir);
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }

      // Sauvegarde des fichiers individuels des chapitres
      for (var chapter in chapters) {
        final chapterFile = File(path.join(outputDir, 'chapter_${chapter.index + 1}.txt'));
        await chapterFile.writeAsString(chapter.content);
      }

      // Sauvegarde des métadonnées
      final metadata = {
        'num_chapters': chapters.length,
        'chapters': chapters.map((c) => {
          'title': c.title,
          'content': c.content,
          'index': c.index,
          'isProcessing': c.isProcessing,
          'audioPath': c.audioPath,
          'wordCount': c.wordCount,
          'preview': c.previewText,
        }).toList(),
      };
      
      final metadataFile = File(path.join(outputDir, 'metadata.json'));
      await metadataFile.writeAsString(jsonEncode(metadata));
    } catch (e) {
      print('Erreur lors de la sauvegarde des chapitres: $e');
      print('Path: $outputDir');
      print('Stack trace: ${e is FileSystemException ? e.osError : ''}');
      rethrow;
    }
  }

  static String getFileName(String filePath) {
    return path.basename(filePath);
  }
}
