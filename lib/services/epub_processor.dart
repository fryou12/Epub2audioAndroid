import 'dart:io';
import 'package:epubx/epubx.dart';
import 'package:html/parser.dart' as html;
import 'package:flutter/foundation.dart';
import '../models/chapter.dart';

class EpubProcessor {
  Future<List<Chapter>> processEpubFile(String filePath) async {
    try {
      // Lire le fichier ePub
      final File file = File(filePath);
      final List<int> bytes = await file.readAsBytes();
      
      // Parser le fichier ePub
      final EpubBook epubBook = await EpubReader.readBook(bytes);
      
      final List<Chapter> chapters = [];
      int chapterIndex = 0;

      // Traiter chaque chapitre
      if (epubBook.Chapters != null) {
        for (var chapter in epubBook.Chapters!) {
          if (chapter.HtmlContent != null) {
            // Parser le contenu HTML
            final document = html.parse(chapter.HtmlContent!);
            
            // Extraire le texte en supprimant les balises HTML
            String content = document.body?.text ?? '';
            
            // Nettoyer le texte
            content = _cleanText(content);
            
            chapters.add(Chapter(
              title: chapter.Title ?? 'Chapitre ${chapterIndex + 1}',
              content: content,
              index: chapterIndex,
              chapterNumber: chapterIndex + 1,
            ));
            
            chapterIndex++;
          }
        }
      }

      // Si aucun chapitre n'a été trouvé, essayer d'extraire le contenu des spine items
      if (chapters.isEmpty && epubBook.Schema?.Package?.Spine != null) {
        for (var spineItem in epubBook.Schema!.Package!.Spine!.Items!) {
          var idRef = spineItem.IdRef;
          var manifestItem = epubBook.Schema!.Package!.Manifest!.Items!
              .firstWhere((item) => item.Id == idRef, orElse: () => EpubManifestItem());
          
          if (manifestItem.Href != null && manifestItem.MediaType?.contains('html') == true) {
            var content = await _readManifestItem(epubBook, manifestItem.Href!);
            if (content.isNotEmpty) {
              final document = html.parse(content);
              String textContent = document.body?.text ?? '';
              textContent = _cleanText(textContent);
              
              chapters.add(Chapter(
                title: 'Chapitre ${chapterIndex + 1}',
                content: textContent,
                index: chapterIndex,
                chapterNumber: chapterIndex + 1,
              ));
              
              chapterIndex++;
            }
          }
        }
      }

      return chapters;
    } catch (e) {
      throw Exception('Erreur lors du traitement du fichier ePub: $e');
    }
  }

  Future<String> _readManifestItem(EpubBook epubBook, String href) async {
    try {
      var content = epubBook.Content?.Html?[href];
      return content?.toString() ?? '';
    } catch (e) {
      debugPrint('Erreur lors de la lecture du manifest item: $e');
      return '';
    }
  }

  String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ') // Remplacer les espaces multiples par un seul
        .trim() // Supprimer les espaces au début et à la fin
        .replaceAll(RegExp(r'[^\S\r\n]+'), ' ') // Normaliser les espaces
        .replaceAll(RegExp(r'\n\s*\n'), '\n\n') // Normaliser les sauts de ligne
        .replaceAll(RegExp(r'\t'), ' '); // Remplacer les tabulations par des espaces
  }
}
