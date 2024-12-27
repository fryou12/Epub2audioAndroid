import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../screens/settings_screen.dart';
import '../services/tts_service.dart';

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
        // Vérifiez si la voix sélectionnée est valide
        if (_selectedVoice == null || !_voices.contains(_selectedVoice)) {
          // Si la voix n'est pas valide, réinitialisez-la à la première voix disponible
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
    return Drawer(
      backgroundColor: AppColors.drawerBackground,
      child: Column(
        children: [
          Container(
            height: kToolbarHeight + MediaQuery.of(context).padding.top,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            decoration: BoxDecoration(
              color: AppColors.headerBackground,
              border: Border(
                bottom: BorderSide(
                  color: Colors.white,
                  width: 1,
                ),
              ),
            ),
            alignment: Alignment.center,
            child: const Text(
              'ePub to Audio',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined, color: Colors.white),
            title: const Text(
              'Accueil',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 16),
            child: Row(
              children: [
                Icon(Icons.record_voice_over, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Configuration TTS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
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
          ListTile(
            leading: const Icon(Icons.settings_outlined, color: Colors.white),
            title: const Text(
              'Paramètres',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.help_outline, color: Colors.white),
            title: const Text(
              'Aide',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              // Fonctionnalité d'aide à implémenter plus tard
            },
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Version: 1.0.0',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.wb_sunny, color: Colors.white),
                onPressed: () {
                  // Fonctionnalité de changement de thème à implémenter plus tard
                },
              ),
            ],
          ),
        ],
      ),
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
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
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
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                dropdownColor: AppColors.drawerBackground,
                style: const TextStyle(color: Colors.white),
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
