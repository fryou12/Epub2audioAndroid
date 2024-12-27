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
  late Map<String, dynamic> _settings;

  @override
  void initState() {
    super.initState();
    _settings = _ttsService.getSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.drawerBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.headerBackground,
            border: Border(
              bottom: BorderSide(
                color: Colors.white,
                width: 1,
              ),
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              'Paramètres',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSection(
            title: 'Paramètres TTS',
            children: [
              _buildSliderTile(
                title: 'Vitesse',
                value: _settings['voice_settings']['rate'],
                min: 0.5,
                max: 2.0,
                onChanged: (value) {
                  setState(() {
                    _settings['voice_settings']['rate'] = value;
                  });
                  _ttsService.setRate(value);
                },
              ),
              _buildSliderTile(
                title: 'Volume',
                value: _settings['voice_settings']['volume'],
                min: 0.0,
                max: 1.0,
                onChanged: (value) {
                  setState(() {
                    _settings['voice_settings']['volume'] = value;
                  });
                  _ttsService.setVolume(value);
                },
              ),
              _buildSliderTile(
                title: 'Hauteur',
                value: _settings['voice_settings']['pitch'],
                min: 0.5,
                max: 2.0,
                onChanged: (value) {
                  setState(() {
                    _settings['voice_settings']['pitch'] = value;
                  });
                  _ttsService.setPitch(value);
                },
              ),
            ],
          ),
          _buildSection(
            title: 'Paramètres de conversion',
            children: [
              _buildSliderTile(
                title: 'Chapitres simultanés',
                value: _settings['maxParallelChapters'].toDouble(),
                min: 1,
                max: 5,
                onChanged: (value) {
                  setState(() {
                    _settings['maxParallelChapters'] = value.toInt();
                  });
                  _ttsService.updateSettings(_settings);
                },
                displayValue: (value) => value.toInt().toString(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSliderTile({
    required String title,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    String Function(double)? displayValue,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white.withOpacity(0.3),
                    thumbColor: Colors.white,
                    overlayColor: Colors.white.withOpacity(0.1),
                  ),
                  child: Slider(
                    value: value,
                    min: min,
                    max: max,
                    onChanged: onChanged,
                  ),
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  displayValue?.call(value) ?? value.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
