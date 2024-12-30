import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../screens/settings_screen.dart';
import '../services/tts_service.dart';
import '../providers/theme_provider.dart';
import '../providers/extractor_provider.dart';
import 'package:provider/provider.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final TTSService _ttsService = TTSService();
  String? _selectedEngine;
  String? _selectedLanguage;
  String? _selectedVoice;
  List<String> _engines = [];
  List<String> _languages = [];
  List<String> _voices = [];

  @override
  void initState() {
    super.initState();
    _initializeTTS();
    _loadSavedSettings();
    ExtractorProvider().loadSavedExtractor();
  }

  Future<void> _initializeTTS() async {
    await _ttsService.initialize();
    _updateEngines();
  }

  Future<void> _loadSavedSettings() async {
    final voice = await _ttsService.getCurrentVoice();
    if (voice != null) {
      setState(() {
        if (voice.contains('Neural')) {
          _selectedEngine = 'Edge TTS';
          final parts = voice.split('-');
          if (parts.length >= 2) {
            _selectedLanguage = '${parts[0]}-${parts[1]}';
          }
          _selectedVoice = voice;
        } else {
          _selectedEngine = 'System TTS';
          _selectedLanguage = 'fr-FR';
          _selectedVoice = voice;
        }
        _updateLanguages();
      });
    }
  }

  void _updateEngines() {
    setState(() {
      _engines = _ttsService.getAvailableEngines();
      _selectedEngine = _engines.isNotEmpty ? _engines.first : null;
      if (_selectedEngine != null) {
        _ttsService.setEngine(_selectedEngine!);
        _updateLanguages();
      }
    });
  }

  void _updateLanguages() {
    if (_selectedEngine != null) {
      setState(() {
        _languages = _ttsService.getAvailableLanguages(_selectedEngine!);
        _selectedLanguage = _languages.isNotEmpty ? 'fr-FR' : null;
        if (_selectedLanguage != null) {
          _updateVoices();
        }
      });
    }
  }

  void _updateVoices() {
    if (_selectedEngine != null && _selectedLanguage != null) {
      setState(() {
        _voices = _ttsService.getAvailableVoices(_selectedEngine!, _selectedLanguage!);
        if (_selectedVoice == null || !_voices.contains(_selectedVoice)) {
          _selectedVoice = _voices.isNotEmpty ? _voices.first : null;
          if (_selectedVoice != null) {
            _ttsService.setVoice(_selectedVoice!);
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeProvider(),
      builder: (context, _) {
        return Drawer(
          backgroundColor: AppColors.current.drawerBackground,
          child: Column(
            children: [
              Container(
                height: kToolbarHeight + MediaQuery.of(context).padding.top,
                padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                decoration: BoxDecoration(
                  color: AppColors.current.headerBackground,
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.current.dividerColor,
                      width: 0.5,
                    ),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  'ePub to Audio',
                  style: TextStyle(
                    fontSize: 20,
                    color: AppColors.current.primaryText,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.home_outlined, color: AppColors.current.iconColor),
                title: Text(
                  'Accueil',
                  style: TextStyle(color: AppColors.current.primaryText),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              _buildDropdownTile(
                title: 'Moteur TTS',
                icon: Icons.engineering,
                value: _selectedEngine,
                items: _engines,
                onChanged: (String? value) {
                  if (value != null && value != _selectedEngine) {
                    setState(() {
                      _selectedEngine = value;
                      _selectedLanguage = null;
                      _selectedVoice = null;
                      _languages.clear();
                      _voices.clear();
                      _updateLanguages();
                    });
                  }
                },
              ),
              _buildDropdownTile(
                title: 'Langue',
                icon: Icons.language,
                value: _selectedLanguage,
                items: _languages,
                onChanged: (String? value) {
                  if (value != null && value != _selectedLanguage) {
                    setState(() {
                      _selectedLanguage = value;
                      _selectedVoice = null;
                      _voices.clear();
                      _updateVoices();
                    });
                  }
                },
              ),
              _buildDropdownTile(
                title: 'Voix',
                icon: Icons.record_voice_over_outlined,
                value: _selectedVoice,
                items: _voices,
                onChanged: (String? value) {
                  if (value != null && value != _selectedVoice) {
                    setState(() {
                      _selectedVoice = value;
                      _ttsService.setVoice(value);
                    });
                  }
                },
              ),
              ExpansionTile(
                leading: Icon(Icons.extension, color: AppColors.current.iconColor),
                title: Text(
                  'Méthode d\'extraction',
                  style: TextStyle(color: AppColors.current.primaryText),
                ),
                children: [
                  SingleChildScrollView(
                    child: Consumer<ExtractorProvider>(
                      builder: (context, extractorProvider, _) {
                        return Column(
                          children: extractorProvider.availableExtractors.map((extractor) {
                            return RadioListTile<String>(
                              title: Text(
                                extractor.replaceAll('_', ' ').split(' ').map((word) => 
                                  word[0].toUpperCase() + word.substring(1)
                                ).join(' '),
                                style: TextStyle(color: AppColors.current.primaryText),
                              ),
                              subtitle: Text(
                                extractorProvider.extractorDescriptions[extractor] ?? '',
                                style: TextStyle(
                                  color: AppColors.current.primaryText.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                              value: extractor,
                              groupValue: extractorProvider.selectedExtractor,
                              onChanged: (String? value) {
                                if (value != null) {
                                  extractorProvider.setExtractor(value);
                                }
                              },
                              activeColor: AppColors.current.primaryAccent,
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                ],
              ),
              ListTile(
                leading: Icon(Icons.settings_outlined, color: AppColors.current.iconColor),
                title: Text(
                  'Paramètres',
                  style: TextStyle(color: AppColors.current.primaryText),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.help_outline, color: AppColors.current.iconColor),
                title: Text(
                  'Aide',
                  style: TextStyle(color: AppColors.current.primaryText),
                ),
                onTap: () {
                  // Action pour l'aide
                },
              ),
              const Spacer(),
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Version: 1.0.0',
                      style: TextStyle(color: AppColors.current.primaryText),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Consumer<ThemeProvider>(
                      builder: (context, themeProvider, _) {
                        return IconButton(
                          icon: Icon(
                            themeProvider.isDarkTheme ? Icons.light_mode : Icons.dark_mode,
                            color: AppColors.current.iconColor,
                          ),
                          onPressed: () {
                            themeProvider.toggleTheme();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required IconData icon,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.current.iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: AppColors.current.primaryText,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.current.drawerBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                items: items.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      style: TextStyle(color: AppColors.current.primaryText),
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
                icon: Icon(Icons.arrow_drop_down, color: AppColors.current.iconColor),
                dropdownColor: AppColors.current.drawerBackground,
                style: TextStyle(color: AppColors.current.primaryText),
                isExpanded: true,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}