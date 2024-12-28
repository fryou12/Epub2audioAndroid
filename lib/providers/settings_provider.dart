import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConversionSettings {
  final int maxConcurrentConversions;
  final String selectedVoice;
  final String selectedLanguage;

  ConversionSettings({
    this.maxConcurrentConversions = 3,
    this.selectedVoice = '',
    this.selectedLanguage = '',
  });

  ConversionSettings copyWith({
    int? maxConcurrentConversions,
    String? selectedVoice,
    String? selectedLanguage,
  }) {
    return ConversionSettings(
      maxConcurrentConversions: maxConcurrentConversions ?? this.maxConcurrentConversions,
      selectedVoice: selectedVoice ?? this.selectedVoice,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
    );
  }
}

class ConversionSettingsNotifier extends StateNotifier<ConversionSettings> {
  final SharedPreferences prefs;

  ConversionSettingsNotifier(this.prefs) : super(ConversionSettings()) {
    _loadSettings();
  }

  void _loadSettings() {
    state = ConversionSettings(
      maxConcurrentConversions: prefs.getInt('maxConcurrentConversions') ?? 3,
      selectedVoice: prefs.getString('selectedVoice') ?? '',
      selectedLanguage: prefs.getString('selectedLanguage') ?? '',
    );
  }

  Future<void> setMaxConcurrentConversions(int value) async {
    await prefs.setInt('maxConcurrentConversions', value);
    state = state.copyWith(maxConcurrentConversions: value);
  }

  Future<void> setSelectedVoice(String voice) async {
    await prefs.setString('selectedVoice', voice);
    state = state.copyWith(selectedVoice: voice);
  }

  Future<void> setSelectedLanguage(String language) async {
    await prefs.setString('selectedLanguage', language);
    state = state.copyWith(selectedLanguage: language);
  }
}

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

final conversionSettingsProvider = StateNotifierProvider<ConversionSettingsNotifier, ConversionSettings>((ref) {
  return ref.watch(sharedPreferencesProvider).when(
    data: (prefs) => ConversionSettingsNotifier(prefs),
    loading: () => throw UnimplementedError(),
    error: (e, stack) => throw UnimplementedError(),
  );
});
