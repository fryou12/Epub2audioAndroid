import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TTSSettings {
  int maxParallelChapters;
  double rate;
  double volume;
  double pitch;

  TTSSettings({
    this.maxParallelChapters = 3,
    this.rate = 0,
    this.volume = 0,
    this.pitch = 0,
  });

  Map<String, dynamic> toJson() => {
    'maxParallelChapters': maxParallelChapters,
    'rate': rate,
    'volume': volume,
    'pitch': pitch,
  };

  factory TTSSettings.fromJson(Map<String, dynamic> json) => TTSSettings(
    maxParallelChapters: json['maxParallelChapters'] ?? 3,
    rate: json['rate']?.toDouble() ?? 0,
    volume: json['volume']?.toDouble() ?? 0,
    pitch: json['pitch']?.toDouble() ?? 0,
  );
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TTSSettings settings;
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  @override
  void initState() {
    super.initState();
    settings = TTSSettings();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await _prefs;
    final settingsJson = prefs.getString('tts_settings');
    if (settingsJson != null) {
      setState(() {
        settings = TTSSettings.fromJson(
          Map<String, dynamic>.from(
            Map.from(settingsJson as Map)
          )
        );
      });
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await _prefs;
    await prefs.setString('tts_settings', settings.toJson().toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres TTS'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Traitement parallèle',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Nombre maximum de chapitres traités simultanément'),
                      Slider(
                        value: settings.maxParallelChapters.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: settings.maxParallelChapters.toString(),
                        onChanged: (value) {
                          setState(() {
                            settings.maxParallelChapters = value.round();
                          });
                          _saveSettings();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Paramètres de voix Edge TTS',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Vitesse de parole'),
                      Slider(
                        value: settings.rate,
                        min: -100,
                        max: 100,
                        divisions: 40,
                        label: '${settings.rate.round()}%',
                        onChanged: (value) {
                          setState(() {
                            settings.rate = value;
                          });
                          _saveSettings();
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text('Volume'),
                      Slider(
                        value: settings.volume,
                        min: -100,
                        max: 100,
                        divisions: 40,
                        label: '${settings.volume.round()}%',
                        onChanged: (value) {
                          setState(() {
                            settings.volume = value;
                          });
                          _saveSettings();
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text('Hauteur de la voix'),
                      Slider(
                        value: settings.pitch,
                        min: -100,
                        max: 100,
                        divisions: 40,
                        label: '${settings.pitch.round()}Hz',
                        onChanged: (value) {
                          setState(() {
                            settings.pitch = value;
                          });
                          _saveSettings();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
