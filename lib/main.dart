import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epub_to_audio/providers/theme_provider.dart';
import 'package:epub_to_audio/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:epub_to_audio/providers/conversion_settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        conversionSettingsProvider.overrideWith((ref) => ConversionSettingsNotifier(prefs)),
      ],
      child: const EpubToAudioApp(),
    ),
  );
}

class EpubToAudioApp extends ConsumerWidget {
  const EpubToAudioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'ePub vers Audio',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.grey,
          primary: Colors.grey,
          secondary: Colors.grey,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          elevation: 1,
          scrolledUnderElevation: 1,
          backgroundColor: Colors.transparent,
          iconTheme: IconThemeData(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        dividerTheme: const DividerThemeData(
          color: Colors.black12,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.grey,
          brightness: Brightness.dark,
          primary: Colors.grey,
          secondary: Colors.grey,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          elevation: 1,
          scrolledUnderElevation: 1,
          backgroundColor: Colors.transparent,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        dividerTheme: const DividerThemeData(
          color: Colors.white24,
        ),
      ),
      themeMode: themeMode,
      home: const HomeScreen(),
    );
  }
}

class MethodChannelService {
  static const platform = MethodChannel('com.example.epub_to_audio/service');
}
