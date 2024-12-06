import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final voiceFilterProvider = StateNotifierProvider<VoiceFilterNotifier, String?>((ref) {
  return VoiceFilterNotifier();
});

class VoiceFilterNotifier extends StateNotifier<String?> {
  VoiceFilterNotifier() : super(null) {
    _loadSavedFilter();
  }

  Future<void> _loadSavedFilter() async {
    final prefs = await SharedPreferences.getInstance();
    final savedFilter = prefs.getString('voice_filter');
    if (savedFilter != null) {
      state = savedFilter;
    }
  }

  Future<void> setFilter(String? filter) async {
    final prefs = await SharedPreferences.getInstance();
    if (filter != null) {
      await prefs.setString('voice_filter', filter);
    } else {
      await prefs.remove('voice_filter');
    }
    state = filter;
  }
}
