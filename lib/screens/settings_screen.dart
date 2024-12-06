import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epub_to_audio/providers/conversion_settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(conversionSettingsProvider);
    final brightness = Theme.of(context).brightness;
    final statusBarColor = brightness == Brightness.light
        ? Colors.grey[300]
        : Colors.grey[800];
    final backgroundColor = brightness == Brightness.light
        ? Colors.grey[100]
        : Colors.grey[900];
    final headerColor = brightness == Brightness.light
        ? Colors.grey[200]
        : Colors.grey[850];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // Barre de statut
          Container(
            color: statusBarColor,
            child: SafeArea(
              bottom: false,
              child: Container(
                height: 0,
              ),
            ),
          ),
          // Header
          Container(
            color: headerColor,
            child: Column(
              children: [
                AppBar(
                  title: const Text('Paramètres'),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
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
          // Contenu
          Expanded(
            child: ListView(
              children: [
                // Section Paramètres vocaux
                ExpansionTile(
                  title: const Text('Paramètres vocaux'),
                  initiallyExpanded: true,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Vitesse de lecture'),
                          Slider(
                            value: settings.rate,
                            min: 0.5,
                            max: 2.0,
                            divisions: 30,
                            label: settings.rate.toStringAsFixed(2),
                            onChanged: (value) {
                              ref.read(conversionSettingsProvider.notifier).setRate(value);
                            },
                          ),
                          const Text('Hauteur de la voix'),
                          Slider(
                            value: settings.pitch,
                            min: 0.5,
                            max: 2.0,
                            divisions: 30,
                            label: settings.pitch.toStringAsFixed(2),
                            onChanged: (value) {
                              ref.read(conversionSettingsProvider.notifier).setPitch(value);
                            },
                          ),
                          const Text('Volume'),
                          Slider(
                            value: settings.volume,
                            min: 0.0,
                            max: 1.0,
                            divisions: 20,
                            label: '${(settings.volume * 100).toInt()}%',
                            onChanged: (value) {
                              ref.read(conversionSettingsProvider.notifier).setVolume(value);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Section Paramètres des chapitres
                ExpansionTile(
                  title: const Text('Paramètres des chapitres'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SwitchListTile(
                            title: const Text('Découper en chapitres'),
                            value: settings.splitByChapter,
                            onChanged: (value) {
                              ref.read(conversionSettingsProvider.notifier).setSplitByChapter(value);
                            },
                          ),
                          const Divider(),
                          const Text(
                            'Performance de conversion',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Nombre de conversions simultanées',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Slider(
                                  value: settings.maxConcurrentConversions.toDouble(),
                                  min: 1,
                                  max: 5,
                                  divisions: 4,
                                  label: settings.maxConcurrentConversions.toString(),
                                  onChanged: (value) {
                                    ref.read(conversionSettingsProvider.notifier)
                                        .setMaxConcurrentConversions(value.round());
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                settings.maxConcurrentConversions.toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Plus le nombre est élevé, plus la conversion sera rapide, mais utilisera plus de ressources.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                          const Divider(),
                          ListTile(
                            title: const Text('Chapitres simultanés'),
                            subtitle: Text('${settings.maxConcurrentChapters}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: settings.maxConcurrentChapters > 1
                                      ? () => ref
                                          .read(conversionSettingsProvider.notifier)
                                          .setMaxConcurrentChapters(settings.maxConcurrentChapters - 1)
                                      : null,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: settings.maxConcurrentChapters < 5
                                      ? () => ref
                                          .read(conversionSettingsProvider.notifier)
                                          .setMaxConcurrentChapters(settings.maxConcurrentChapters + 1)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                          ListTile(
                            title: const Text('Nombre d\'essais en cas d\'erreur'),
                            subtitle: Text('${settings.maxRetries}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: settings.maxRetries > 1
                                      ? () => ref
                                          .read(conversionSettingsProvider.notifier)
                                          .setMaxRetries(settings.maxRetries - 1)
                                      : null,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: settings.maxRetries < 10
                                      ? () => ref
                                          .read(conversionSettingsProvider.notifier)
                                          .setMaxRetries(settings.maxRetries + 1)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Section Customisation
                ExpansionTile(
                  title: const Text('Customisation'),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'À venir',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
