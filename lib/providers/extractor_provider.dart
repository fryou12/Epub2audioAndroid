import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExtractorProvider extends ChangeNotifier {
  static final ExtractorProvider _instance = ExtractorProvider._internal();
  factory ExtractorProvider() => _instance;
  ExtractorProvider._internal();

  String _selectedExtractor = 'semantic';  // Default extractor
  List<String> _availableExtractors = [
    'semantic',
    'toc_based',
    'dom_based',
    'pattern_based',
  ];

  String get selectedExtractor => _selectedExtractor;
  List<String> get availableExtractors => _availableExtractors;

  Map<String, String> get extractorDescriptions => {
    'semantic': 'Utilise l\'analyse sémantique pour identifier les chapitres',
    'toc_based': 'Extrait les chapitres basés sur la table des matières',
    'dom_based': 'Analyse la structure DOM du document',
    'pattern_based': 'Recherche des motifs spécifiques de chapitres',
  };

  Future<void> loadSavedExtractor() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedExtractor = prefs.getString('selected_extractor') ?? 'semantic';
    notifyListeners();
  }

  Future<void> setExtractor(String extractor) async {
    if (_availableExtractors.contains(extractor)) {
      _selectedExtractor = extractor;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_extractor', extractor);
      notifyListeners();
    }
  }
}
