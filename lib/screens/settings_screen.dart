import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/tts_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TTSService _ttsService = TTSService();
  String? _selectedEngine;
  String? _selectedLanguage;
  String? _selectedVoice;
  List<String> _engines = [];
  List<String> _languages = [];
  List<String> _voices = [];
  bool _isVoiceExpanded = false;

  @override
  void initState() {
    super.initState();
    _initializeTTS();
    _loadSavedSettings();
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

  Widget _buildDropdownTile({
    required String title,
    required IconData icon,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.current.iconColor),
      title: Text(title, style: TextStyle(color: AppColors.current.primaryText)),
      subtitle: DropdownButton<String>(
        value: value,
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item, style: TextStyle(color: AppColors.current.primaryText)),
          );
        }).toList(),
        onChanged: onChanged,
        dropdownColor: AppColors.current.drawerBackground,
        isExpanded: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.current.drawerBackground,
      appBar: AppBar(
        backgroundColor: AppColors.current.headerBackground,
        title: Text(
          'Paramètres',
          style: TextStyle(color: AppColors.current.primaryText),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.current.iconColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ExpansionTile(
            leading: Icon(Icons.record_voice_over_outlined, color: AppColors.current.iconColor),
            title: Text(
              'Voix',
              style: TextStyle(color: AppColors.current.primaryText),
            ),
            children: [
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
                icon: Icons.voice_over_off,
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
            ],
          ),
          ExpansionTile(
            leading: Icon(Icons.settings_applications, color: AppColors.current.iconColor),
            title: Text(
              'Paramètres avancés',
              style: TextStyle(color: AppColors.current.primaryText),
            ),
            children: [
              ListTile(
                title: Text(
                  'Vitesse',
                  style: TextStyle(color: AppColors.current.primaryText),
                ),
                subtitle: Slider(
                  value: _ttsService.getRate(),
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  label: _ttsService.getRate().toStringAsFixed(2),
                  onChanged: (double value) {
                    setState(() {
                      _ttsService.setRate(value);
                    });
                  },
                  activeColor: AppColors.current.sliderActiveColor,
                  inactiveColor: AppColors.current.sliderInactiveColor,
                ),
              ),
              ListTile(
                title: Text(
                  'Hauteur',
                  style: TextStyle(color: AppColors.current.primaryText),
                ),
                subtitle: Slider(
                  value: _ttsService.getPitch(),
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  label: _ttsService.getPitch().toStringAsFixed(2),
                  onChanged: (double value) {
                    setState(() {
                      _ttsService.setPitch(value);
                    });
                  },
                  activeColor: AppColors.current.sliderActiveColor,
                  inactiveColor: AppColors.current.sliderInactiveColor,
                ),
              ),
              ListTile(
                title: Text(
                  'Volume',
                  style: TextStyle(color: AppColors.current.primaryText),
                ),
                subtitle: Slider(
                  value: _ttsService.getVolume(),
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  label: _ttsService.getVolume().toStringAsFixed(2),
                  onChanged: (double value) {
                    setState(() {
                      _ttsService.setVolume(value);
                    });
                  },
                  activeColor: AppColors.current.sliderActiveColor,
                  inactiveColor: AppColors.current.sliderInactiveColor,
                ),
              ),
              ListTile(
                title: Text(
                  'Chapitres parallèles',
                  style: TextStyle(color: AppColors.current.primaryText),
                ),
                subtitle: Slider(
                  value: _ttsService.getMaxParallelChapters().toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: _ttsService.getMaxParallelChapters().toString(),
                  onChanged: (double value) {
                    setState(() {
                      _ttsService.setMaxParallelChapters(value.toInt());
                    });
                  },
                  activeColor: AppColors.current.sliderActiveColor,
                  inactiveColor: AppColors.current.sliderInactiveColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
