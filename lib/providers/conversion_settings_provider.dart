import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ConversionSettings {
  final double rate;
  final double pitch;
  final double volume;
  final bool splitByChapter;
  final int maxConcurrentChapters;
  final int maxRetries;
  final int maxConcurrentConversions;

  const ConversionSettings({
    this.rate = 1.0,
    this.pitch = 1.0,
    this.volume = 1.0,
    this.splitByChapter = true,
    this.maxConcurrentChapters = 1,
    this.maxRetries = 3,
    this.maxConcurrentConversions = 3,
  });

  ConversionSettings copyWith({
    double? rate,
    double? pitch,
    double? volume,
    bool? splitByChapter,
    int? maxConcurrentChapters,
    int? maxRetries,
    int? maxConcurrentConversions,
  }) {
    return ConversionSettings(
      rate: rate ?? this.rate,
      pitch: pitch ?? this.pitch,
      volume: volume ?? this.volume,
      splitByChapter: splitByChapter ?? this.splitByChapter,
      maxConcurrentChapters: maxConcurrentChapters ?? this.maxConcurrentChapters,
      maxRetries: maxRetries ?? this.maxRetries,
      maxConcurrentConversions: maxConcurrentConversions ?? this.maxConcurrentConversions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rate': rate,
      'pitch': pitch,
      'volume': volume,
      'splitByChapter': splitByChapter,
      'maxConcurrentChapters': maxConcurrentChapters,
      'maxRetries': maxRetries,
      'maxConcurrentConversions': maxConcurrentConversions,
    };
  }

  factory ConversionSettings.fromJson(Map<String, dynamic> json) {
    return ConversionSettings(
      rate: (json['rate'] as num?)?.toDouble() ?? 1.0,
      pitch: (json['pitch'] as num?)?.toDouble() ?? 1.0,
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
      splitByChapter: json['splitByChapter'] as bool? ?? true,
      maxConcurrentChapters: json['maxConcurrentChapters'] as int? ?? 1,
      maxRetries: json['maxRetries'] as int? ?? 3,
      maxConcurrentConversions: json['maxConcurrentConversions'] as int? ?? 3,
    );
  }
}

class ConversionSettingsNotifier extends StateNotifier<ConversionSettings> {
  final SharedPreferences _prefs;
  static const String _key = 'conversion_settings';

  ConversionSettingsNotifier(this._prefs)
      : super(const ConversionSettings()) {
    _loadSettings();
  }

  void _loadSettings() {
    final settingsStr = _prefs.getString(_key);
    if (settingsStr != null) {
      try {
        final Map<String, dynamic> settingsMap = jsonDecode(settingsStr);
        state = ConversionSettings.fromJson(settingsMap);
      } catch (e) {
        // En cas d'erreur, on garde les paramètres par défaut
        state = const ConversionSettings();
      }
    }
  }

  void setRate(double value) {
    state = state.copyWith(rate: value);
    _saveSettings();
  }

  void setPitch(double value) {
    state = state.copyWith(pitch: value);
    _saveSettings();
  }

  void setVolume(double value) {
    state = state.copyWith(volume: value);
    _saveSettings();
  }

  void setSplitByChapter(bool value) {
    state = state.copyWith(splitByChapter: value);
    _saveSettings();
  }

  void setMaxConcurrentChapters(int value) {
    state = state.copyWith(maxConcurrentChapters: value);
    _saveSettings();
  }

  void setMaxRetries(int value) {
    state = state.copyWith(maxRetries: value);
    _saveSettings();
  }

  void setMaxConcurrentConversions(int value) {
    state = state.copyWith(maxConcurrentConversions: value);
    _saveSettings();
  }

  void _saveSettings() {
    final jsonString = jsonEncode(state.toJson());
    _prefs.setString(_key, jsonString);
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final conversionSettingsProvider =
    StateNotifierProvider<ConversionSettingsNotifier, ConversionSettings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ConversionSettingsNotifier(prefs);
});
