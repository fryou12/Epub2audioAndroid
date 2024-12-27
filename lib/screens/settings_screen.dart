import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/tts_service.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TTSService _ttsService = TTSService();
  late Map<String, dynamic> _settings;

  @override
  void initState() {
    super.initState();
    _settings = _ttsService.getSettings();
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
          SwitchListTile(
            title: Text(
              'Mode Sombre',
              style: TextStyle(color: AppColors.current.primaryText),
            ),
            value: AppColors.current == AppColors.darkTheme,
            onChanged: (bool value) {
              ThemeProvider().toggleTheme();
              setState(() {});
            },
            activeColor: AppColors.current.primaryAccent,
          ),
          ListTile(
            title: Text(
              'Voix',
              style: TextStyle(color: AppColors.current.primaryText),
            ),
            trailing: DropdownButton<String>(
              value: _settings['voice_settings']['voice'],
              items: _settings['available_voices']?.map<DropdownMenuItem<String>>((String voice) {
                return DropdownMenuItem<String>(
                  value: voice,
                  child: Text(
                    voice,
                    style: TextStyle(color: AppColors.current.primaryText),
                  ),
                );
              })?.toList() ?? [],
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _settings['voice_settings']['voice'] = newValue;
                  });
                  _ttsService.setVoice(newValue);
                }
              },
              dropdownColor: AppColors.current.drawerBackground,
              icon: Icon(Icons.arrow_drop_down, color: AppColors.current.iconColor),
            ),
          ),
          ListTile(
            title: Text(
              'Vitesse de lecture',
              style: TextStyle(color: AppColors.current.primaryText),
            ),
            subtitle: Slider(
              value: _settings['voice_settings']['rate'],
              min: 0.5,
              max: 2.0,
              divisions: 15,
              label: _settings['voice_settings']['rate'].toString(),
              onChanged: (double value) {
                setState(() {
                  _settings['voice_settings']['rate'] = value;
                });
                _ttsService.setRate(value);
              },
              activeColor: AppColors.current.sliderActiveColor,
              inactiveColor: AppColors.current.sliderInactiveColor,
            ),
          ),
          ListTile(
            title: Text(
              'Hauteur de la voix',
              style: TextStyle(color: AppColors.current.primaryText),
            ),
            subtitle: Slider(
              value: _settings['voice_settings']['pitch'],
              min: 0.5,
              max: 2.0,
              divisions: 15,
              label: _settings['voice_settings']['pitch'].toString(),
              onChanged: (double value) {
                setState(() {
                  _settings['voice_settings']['pitch'] = value;
                });
                _ttsService.setPitch(value);
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
              value: _settings['voice_settings']['volume'],
              min: 0.0,
              max: 1.0,
              divisions: 10,
              label: _settings['voice_settings']['volume'].toString(),
              onChanged: (double value) {
                setState(() {
                  _settings['voice_settings']['volume'] = value;
                });
                _ttsService.setVolume(value);
              },
              activeColor: AppColors.current.sliderActiveColor,
              inactiveColor: AppColors.current.sliderInactiveColor,
            ),
          ),
          ListTile(
            title: Text(
              'Chapitres simultanés',
              style: TextStyle(color: AppColors.current.primaryText),
            ),
            subtitle: Slider(
              value: _settings['maxParallelChapters'].toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: _settings['maxParallelChapters'].toString(),
              onChanged: (double value) {
                setState(() {
                  _settings['maxParallelChapters'] = value.toInt();
                });
                _ttsService.updateSettings(_settings);
              },
              activeColor: AppColors.current.sliderActiveColor,
              inactiveColor: AppColors.current.sliderInactiveColor,
            ),
          ),
        ],
      ),
    );
  }
}
