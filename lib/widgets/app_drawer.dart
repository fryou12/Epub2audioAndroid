import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epub_to_audio/providers/theme_provider.dart';
import 'package:epub_to_audio/providers/tts_provider.dart';
import 'package:epub_to_audio/providers/voice_filter_provider.dart';
import 'package:epub_to_audio/models/voice_model.dart';
import 'package:epub_to_audio/screens/history_screen.dart';
import 'package:epub_to_audio/screens/library_screen.dart';
import 'package:epub_to_audio/screens/settings_screen.dart';
import 'package:epub_to_audio/screens/help_screen.dart';

class AppDrawer extends ConsumerStatefulWidget {
  const AppDrawer({super.key});

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  final TextEditingController _filterController = TextEditingController();
  List<String> _availableLanguages = [];

  @override
  void initState() {
    super.initState();
    _loadFilter();
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  Future<void> _loadFilter() async {
    final filter = ref.read(voiceFilterProvider);
    if (filter != null) {
      _filterController.text = filter;
    }
  }

  void _updateAvailableLanguages(List<VoiceModel> voices) {
    _availableLanguages = voices
        .map((voice) => _getLanguageName(voice.language))
        .toSet()
        .toList()
      ..sort();
  }

  String _getLanguageName(String languageCode) {
    // Conversion des codes de langue en noms complets
    final Map<String, String> languageNames = {
      'fr': 'Français',
      'en': 'Anglais',
      'es': 'Espagnol',
      'de': 'Allemand',
      'it': 'Italien',
      'pt': 'Portugais',
      'ru': 'Russe',
      'ja': 'Japonais',
      'ko': 'Coréen',
      'zh': 'Chinois',
    };

    final code = languageCode.split('-')[0].toLowerCase();
    return languageNames[code] ?? languageCode;
  }

  bool _voiceMatchesFilter(VoiceModel voice, String? filter) {
    if (filter == null || filter.isEmpty) return true;
    
    final languageName = _getLanguageName(voice.language);
    return languageName.toLowerCase().contains(filter.toLowerCase()) ||
           voice.language.toLowerCase().contains(filter.toLowerCase()) ||
           voice.name.toLowerCase().contains(filter.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final currentEngine = ref.watch(ttsEngineProvider);
    final selectedVoice = ref.watch(selectedVoiceProvider);
    final voices = ref.watch(availableVoicesProvider);
    final filter = ref.watch(voiceFilterProvider);
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeProvider);
    final brightness = theme.brightness;
    final statusBarColor = brightness == Brightness.light
        ? Colors.grey[300]
        : Colors.grey[800];
    final backgroundColor = brightness == Brightness.light
        ? Colors.grey[100]
        : Colors.grey[900];
    final headerColor = brightness == Brightness.light
        ? Colors.grey[200]
        : Colors.grey[850];
    final textColor = brightness == Brightness.light
        ? Colors.black
        : Colors.white;

    // Mettre à jour la liste des langues disponibles
    if (voices.hasValue) {
      _updateAvailableLanguages(voices.value!);
    }

    return Drawer(
      backgroundColor: backgroundColor,
      child: Column(
        children: [
          Column(
            children: [
              Container(
                color: statusBarColor,
                child: SafeArea(
                  bottom: false,
                  child: Container(
                    height: 0,
                  ),
                ),
              ),
              Container(
                color: headerColor,
                child: Column(
                  children: [
                    AppBar(
                      toolbarHeight: 39,
                      title: Transform.translate(
                        offset: const Offset(0, -8.5),
                        child: Row(
                          children: [
                            Icon(
                              Icons.menu_book_outlined,
                              size: 24,
                              color: textColor,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'ePub vers Audio',
                              style: TextStyle(
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      automaticallyImplyLeading: false,
                      iconTheme: IconThemeData(color: textColor),
                    ),
                    Container(
                      height: 1,
                      color: brightness == Brightness.light
                          ? Colors.black12
                          : Colors.white24,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: Icon(
                    Icons.home_outlined,
                    color: textColor,
                  ),
                  title: Text(
                    'Accueil',
                    style: TextStyle(color: textColor),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.record_voice_over,
                    color: textColor,
                  ),
                  title: Text(
                    'Service TTS',
                    style: TextStyle(color: textColor),
                  ),
                  subtitle: Text(_getEngineName(currentEngine)),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Sélectionner le service TTS'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: TTSEngineType.values.map((engine) {
                            return RadioListTile<TTSEngineType>(
                              title: Text(_getEngineName(engine)),
                              value: engine,
                              groupValue: currentEngine,
                              onChanged: (value) {
                                if (value != null) {
                                  ref.read(ttsEngineProvider.notifier).setEngine(value);
                                }
                                Navigator.pop(context);
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.language,
                    color: textColor,
                  ),
                  title: Text(
                    'Langue',
                    style: TextStyle(color: textColor),
                  ),
                  subtitle: DropdownButton<String>(
                    value: filter,
                    isExpanded: true,
                    hint: const Text('Toutes les langues'),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Toutes les langues'),
                      ),
                      ..._availableLanguages.map((String language) {
                        return DropdownMenuItem<String>(
                          value: language,
                          child: Text(language),
                        );
                      }).toList(),
                    ],
                    onChanged: (String? newValue) {
                      ref.read(voiceFilterProvider.notifier).setFilter(newValue);
                    },
                  ),
                ),
                ListTile(
                  leading: Icon(
                    Icons.record_voice_over_outlined,
                    color: textColor,
                  ),
                  title: Text(
                    'Voix',
                    style: TextStyle(color: textColor),
                  ),
                  subtitle: voices.when(
                    data: (allVoices) {
                      final filteredVoices = allVoices
                          .where((voice) => _voiceMatchesFilter(voice, filter))
                          .toList();

                      if (filteredVoices.isEmpty) {
                        return const Text('Aucune voix disponible');
                      }

                      if (selectedVoice == null) {
                        // Trouver la voix Rémi si disponible
                        final remiVoice = filteredVoices.firstWhere(
                          (v) => v.language.startsWith('fr') && v.name.contains('Rémi'),
                          orElse: () => filteredVoices.first,
                        );
                        
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          ref.read(selectedVoiceProvider.notifier).setVoice(remiVoice.id);
                        });
                        return Text(remiVoice.name);
                      }

                      final currentVoice = filteredVoices.firstWhere(
                        (v) => v.id == selectedVoice,
                        orElse: () => filteredVoices.first,
                      );

                      return DropdownButton<String>(
                        value: selectedVoice,
                        isExpanded: true,
                        items: filteredVoices.map((voice) {
                          return DropdownMenuItem<String>(
                            value: voice.id,
                            child: Text(voice.name),
                          );
                        }).toList(),
                        onChanged: (String? value) {
                          if (value != null) {
                            ref.read(selectedVoiceProvider.notifier).setVoice(value);
                          }
                        },
                      );
                    },
                    loading: () => const Text('Chargement des voix...'),
                    error: (error, _) => Text('Erreur: ${error.toString()}'),
                  ),
                ),
                ListTile(
                  leading: Icon(
                    Icons.settings_outlined,
                    color: textColor,
                  ),
                  title: Text(
                    'Paramètres',
                    style: TextStyle(color: textColor),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.history_outlined,
                    color: textColor,
                  ),
                  title: Text(
                    'Historique',
                    style: TextStyle(color: textColor),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HistoryScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.library_books_outlined,
                    color: textColor,
                  ),
                  title: Text(
                    'Bibliothèque',
                    style: TextStyle(color: textColor),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LibraryScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.help_outline,
                    color: textColor,
                  ),
                  title: Text(
                    'Aide',
                    style: TextStyle(color: textColor),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HelpScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Version 1.0.0',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    themeMode == ThemeMode.light
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                    size: 20,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  onPressed: () {
                    ref.read(themeProvider.notifier).toggleTheme();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getEngineName(TTSEngineType engine) {
    switch (engine) {
      case TTSEngineType.flutterTts:
        return 'Flutter TTS';
      case TTSEngineType.edgeTts:
        return 'Edge TTS';
    }
  }
}
