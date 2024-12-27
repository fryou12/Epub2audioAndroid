import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:epub_to_audio/providers/tts_provider.dart';
import 'package:epub_to_audio/providers/theme_provider.dart';
import 'package:epub_to_audio/screens/settings_screen.dart';
import '../constants/colors.dart';

String getLanguageDisplayName(String languageCode) {
  final Map<String, String> languageNames = {
    'en': 'English',
    'fr': 'French',
    'es': 'Spanish',
    'de': 'German',
    'it': 'Italian',
    'pt': 'Portuguese',
    'ru': 'Russian',
    'ja': 'Japanese',
    'ko': 'Korean',
    'zh': 'Chinese',
  };
  return languageNames[languageCode] ?? languageCode;
}

class AppDrawer extends ConsumerWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;
    // final currentEngine = ref.watch(ttsEngineProvider);
    // final availableVoices = ref.watch(availableVoicesProvider);
    // final selectedVoice = ref.watch(selectedVoiceProvider);
    // final filter = ref.watch(voiceFilterProvider);
    
    final textColor = isDark ? Colors.grey[50] : Colors.grey[900];
    final backgroundColor = isDark ? Colors.grey[900] : Colors.grey[50];

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
                  'Moteur TTS',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 32),
            title: const Text(
              'Edge TTS',
              style: TextStyle(color: Colors.white),
            ),
            trailing: const Icon(Icons.arrow_drop_down, color: Colors.white),
            onTap: () {},
          ),
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 16),
            child: Row(
              children: [
                Icon(Icons.language, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Langue',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 32),
            title: const Text(
              'Français',
              style: TextStyle(color: Colors.white),
            ),
            trailing: const Icon(Icons.arrow_drop_down, color: Colors.white),
            onTap: () {},
          ),
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 16),
            child: Row(
              children: [
                Icon(Icons.record_voice_over_outlined, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Voix',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 32),
            title: const Text(
              'Sélectionner une voix',
              style: TextStyle(color: Colors.white),
            ),
            trailing: const Icon(Icons.arrow_drop_down, color: Colors.white),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined, color: Colors.white),
            title: const Text(
              'Paramètres',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const SettingsScreen(),
              ));
            },
          ),
          ListTile(
            leading: const Icon(Icons.help_outline, color: Colors.white),
            title: const Text(
              'Aide',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {},
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isDark ? Icons.light_mode : Icons.dark_mode,
                    color: Colors.white70,
                    size: 20,
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
}
