import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExtractorProvider with ChangeNotifier {
  static const String _extractorKey = 'selected_extractor';
  String _selectedExtractor = 'semantic';

  final Map<String, String> extractorDescriptions = {
    'semantic': 'Analyse la structure sémantique du document (titres, sections)',
    'toc': 'Utilise la table des matières du document',
    'pattern': 'Recherche des motifs communs de chapitres',
  };

  List<String> get availableExtractors => ['semantic', 'toc', 'pattern'];

  String get selectedExtractor => _selectedExtractor;

  Future<void> loadSavedExtractor() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedExtractor = prefs.getString(_extractorKey) ?? 'semantic';
    notifyListeners();
  }

  Future<void> setExtractor(String extractor) async {
    if (availableExtractors.contains(extractor)) {
      _selectedExtractor = extractor;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_extractorKey, extractor);
      notifyListeners();
    }
  }
}
