import 'package:flutter/material.dart';
import '../services/edge_tts_service.dart';

class TTSDrawer extends StatefulWidget {
  final Function(String) onVoiceSelected;
  final Function() onSettingsPressed;

  const TTSDrawer({
    Key? key,
    required this.onVoiceSelected,
    required this.onSettingsPressed,
  }) : super(key: key);

  @override
  State<TTSDrawer> createState() => _TTSDrawerState();
}

class _TTSDrawerState extends State<TTSDrawer> {
  final EdgeTTSService _ttsService = EdgeTTSService();
  String? selectedEngine = 'Edge TTS';
  String? selectedLanguage;
  String? selectedVoice;
  Map<String, List<VoiceInfo>> voicesByLanguage = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVoices();
  }

  Future<void> _loadVoices() async {
    setState(() {
      isLoading = true;
    });

    try {
      final voices = await _ttsService.getVoices();
      final Map<String, List<VoiceInfo>> tempVoices = {};

      for (var voice in voices) {
        if (!tempVoices.containsKey(voice.locale)) {
          tempVoices[voice.locale] = [];
        }
        tempVoices[voice.locale]!.add(voice);
      }

      setState(() {
        voicesByLanguage = tempVoices;
        isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des voix: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.8),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.record_voice_over,
                      size: 48,
                      color: Colors.white,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Paramètres TTS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(
                          color: Theme.of(context).primaryColor.withOpacity(0.2),
                          width: 1,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.settings_voice),
                                const SizedBox(width: 10),
                                const Text(
                                  'Moteur TTS',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              value: selectedEngine,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Edge TTS',
                                  child: Text('Edge TTS'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  selectedEngine = value;
                                  selectedLanguage = null;
                                  selectedVoice = null;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (selectedEngine == 'Edge TTS') ...[
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(
                            color: Theme.of(context).primaryColor.withOpacity(0.2),
                            width: 1,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.language),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Langue',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (isLoading)
                                const LinearProgressIndicator()
                              else
                                DropdownButtonFormField<String>(
                                  value: selectedLanguage,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                  ),
                                  hint: const Text('Sélectionner une langue'),
                                  items: voicesByLanguage.keys.map((locale) {
                                    return DropdownMenuItem(
                                      value: locale,
                                      child: Text(_getLanguageName(locale)),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedLanguage = value;
                                      selectedVoice = null;
                                    });
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (selectedLanguage != null) ...[
                        const SizedBox(height: 16),
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: BorderSide(
                              color: Theme.of(context).primaryColor.withOpacity(0.2),
                              width: 1,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.record_voice_over),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Voix',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                DropdownButtonFormField<String>(
                                  value: selectedVoice,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                  ),
                                  hint: const Text('Sélectionner une voix'),
                                  items: voicesByLanguage[selectedLanguage]!.map((voice) {
                                    return DropdownMenuItem(
                                      value: voice.shortName,
                                      child: Text('${voice.name} (${voice.gender})'),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedVoice = value;
                                    });
                                    if (value != null) {
                                      widget.onVoiceSelected(value);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 16),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(
                          color: Theme.of(context).primaryColor.withOpacity(0.2),
                          width: 1,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.settings),
                        title: const Text('Paramètres'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: widget.onSettingsPressed,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLanguageName(String locale) {
    final Map<String, String> languageNames = {
      'fr-FR': 'Français',
      'en-US': 'Anglais (US)',
      'en-GB': 'Anglais (UK)',
      'de-DE': 'Allemand',
      'es-ES': 'Espagnol',
      'it-IT': 'Italien',
    };
    return languageNames[locale] ?? locale;
  }
}
