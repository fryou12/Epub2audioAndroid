import 'package:flutter/material.dart';
import '../services/tts_service.dart';

class TTSDrawer extends StatefulWidget {
  final Function(String) onVoiceSelected;
  final VoidCallback onSettingsPressed;

  const TTSDrawer({
    super.key,
    required this.onVoiceSelected,
    required this.onSettingsPressed,
  });

  @override
  State<TTSDrawer> createState() => _TTSDrawerState();
}

class _TTSDrawerState extends State<TTSDrawer> {
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
  }

  Future<void> _initializeTTS() async {
    await _ttsService.initialize();
    _updateEngines();
  }

  void _updateEngines() {
    setState(() {
      _engines = _ttsService.getAvailableEngines();
      _selectedEngine = _engines.isNotEmpty ? _engines.first : null;
      if (_selectedEngine != null) {
        _updateLanguages();
      }
    });
  }

  void _updateLanguages() {
    setState(() {
      _languages = _ttsService.getAvailableLanguages(_selectedEngine!);
      _selectedLanguage = _languages.isNotEmpty ? _languages.first : null;
      if (_selectedLanguage != null) {
        _updateVoices();
      }
    });
  }

  void _updateVoices() {
    setState(() {
      _voices = _ttsService.getAvailableVoices(_selectedEngine!, _selectedLanguage!);
      _selectedVoice = _voices.isNotEmpty ? _voices.first : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Drawer(
      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
      child: Column(
        children: [
          Container(
            height: kToolbarHeight + MediaQuery.of(context).padding.top,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              border: Border(
                bottom: BorderSide(
                  color: Colors.white,
                  width: 1,
                ),
              ),
            ),
            alignment: Alignment.center,
            child: const Text(
              'Configuration TTS',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                const SizedBox(height: 16),
                _buildDropdownSection(
                  icon: Icons.engineering,
                  title: 'Moteur TTS',
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
                const SizedBox(height: 24),
                _buildDropdownSection(
                  icon: Icons.language,
                  title: 'Langue',
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
                const SizedBox(height: 24),
                _buildDropdownSection(
                  icon: Icons.record_voice_over,
                  title: 'Voix',
                  value: _selectedVoice,
                  items: _voices,
                  onChanged: (String? value) {
                    if (value != null && value != _selectedVoice) {
                      setState(() {
                        _selectedVoice = value;
                        widget.onVoiceSelected(value);
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: widget.onSettingsPressed,
              icon: const Icon(Icons.settings),
              label: const Text('Paramètres'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSection({
    required IconData icon,
    required String title,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.transparent,
            ),
            dropdownColor: theme.colorScheme.primary,
            icon: Icon(
              Icons.arrow_drop_down,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
