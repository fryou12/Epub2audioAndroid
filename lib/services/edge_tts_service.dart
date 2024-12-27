import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class VoiceInfo {
  final String name;
  final String locale;
  final String gender;
  final String shortName;

  VoiceInfo({
    required this.name,
    required this.locale,
    required this.gender,
    required this.shortName,
  });

  factory VoiceInfo.fromJson(Map<String, dynamic> json) {
    return VoiceInfo(
      name: json['Name'],
      locale: json['Locale'],
      gender: json['Gender'],
      shortName: json['ShortName'],
    );
  }
}

class EdgeTTSService {
  static const String _baseUrl = 'https://speech.platform.bing.com/consumer/speech';
  static const String _voicesUrl = '$_baseUrl/synthesize/readaloud/voices/list?trustedclienttoken=6A5AA1D4EAFF4E9FB37E23D68491D6F4';
  
  String? _currentVoice;
  Map<String, dynamic> _settings = {
    'rate': '+0%',
    'volume': '+0%',
    'pitch': '+0Hz'
  };

  Future<List<VoiceInfo>> getVoices() async {
    try {
      final response = await http.get(Uri.parse(_voicesUrl));
      if (response.statusCode == 200) {
        final List<dynamic> voicesJson = json.decode(response.body);
        return voicesJson.map((voice) => VoiceInfo.fromJson(voice)).toList();
      }
      throw Exception('Failed to load voices');
    } catch (e) {
      print('Error fetching voices: $e');
      return [];
    }
  }

  Future<String> synthesize(String text, String voice) async {
    try {
      final ssml = _generateSSML(text, voice);
      final response = await http.post(
        Uri.parse('$_baseUrl/synthesize/readaloud/voices'),
        headers: {
          'Content-Type': 'application/ssml+xml',
          'X-Microsoft-OutputFormat': 'audio-16khz-32kbitrate-mono-mp3',
          'User-Agent': 'Edge',
        },
        body: ssml,
      );

      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/output.mp3');
        await file.writeAsBytes(response.bodyBytes);
        return file.path;
      }
      throw Exception('Failed to synthesize speech');
    } catch (e) {
      print('Error synthesizing speech: $e');
      rethrow;
    }
  }

  String _generateSSML(String text, String voice) {
    return '''
<?xml version="1.0" encoding="UTF-8"?>
<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis"
       xmlns:mstts="https://www.w3.org/2001/mstts" xml:lang="en-US">
    <voice name="$voice">
        <prosody rate="${_settings['rate']}" 
                 volume="${_settings['volume']}" 
                 pitch="${_settings['pitch']}">
            $text
        </prosody>
    </voice>
</speak>
''';
  }

  void updateSettings(Map<String, dynamic> newSettings) {
    _settings = newSettings;
  }

  void setVoice(String voice) {
    _currentVoice = voice;
  }

  String? getCurrentVoice() => _currentVoice;
}
