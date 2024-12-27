import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class VoiceInfo {
  final String name;
  final String shortName;
  final String locale;
  final String gender;

  VoiceInfo({
    required this.name,
    required this.shortName,
    required this.locale,
    required this.gender,
  });

  factory VoiceInfo.fromJson(Map<String, dynamic> json) {
    return VoiceInfo(
      name: json['Name'] ?? '',
      shortName: json['ShortName'] ?? '',
      locale: json['Locale'] ?? '',
      gender: json['Gender'] ?? '',
    );
  }
}

class EdgeTTSService {
  static final EdgeTTSService _instance = EdgeTTSService._internal();
  factory EdgeTTSService() => _instance;
  EdgeTTSService._internal();

  String? _currentVoice;
  final String _apiUrl = 'https://speech.platform.bing.com/consumer/speech/synthesize/readaloud/voices/list';
  
  Map<String, dynamic> _settings = {
    'rate': '+0%',
    'volume': '+0%',
    'pitch': '+0Hz'
  };

  String? getCurrentVoice() => _currentVoice;

  void setVoice(String voice) {
    _currentVoice = voice;
  }

  void updateSettings(Map<String, dynamic> settings) {
    _settings = {
      'rate': '${settings['rate']}%',
      'volume': '${settings['volume']}%',
      'pitch': '${settings['pitch']}Hz'
    };
  }

  Future<List<VoiceInfo>> getVoices() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl));
      
      if (response.statusCode == 200) {
        final List<dynamic> voicesJson = json.decode(response.body);
        return voicesJson.map((voice) => VoiceInfo.fromJson(voice)).toList();
      } else {
        throw Exception('Failed to load voices');
      }
    } catch (e) {
      print('Error fetching voices: $e');
      return [];
    }
  }

  Future<String> synthesize(String text, String voice) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final outputPath = '${tempDir.path}/output.mp3';

      final args = <String>[
        'edge-tts',
        '--voice', voice,
        '--text', text,
        '--write-media', outputPath,
      ];

      final result = await Process.run('edge-tts', args);

      if (result.exitCode != 0) {
        throw Exception('Error during synthesis: ${result.stderr}');
      }

      return outputPath;
    } catch (e) {
      print('Error during synthesis: $e');
      rethrow;
    }
  }
}
