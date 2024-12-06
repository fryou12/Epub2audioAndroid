import 'package:flutter/services.dart';

class EdgeTTSPlatform {
  static const MethodChannel _channel = MethodChannel('com.example.epub_to_audio/edge_tts');

  static Future<void> synthesizeToFile({
    required String text,
    required String outputPath,
    String? voice,
  }) async {
    try {
      await _channel.invokeMethod('synthesizeToFile', {
        'text': text,
        'outputPath': outputPath,
        'voice': voice,
      });
    } on PlatformException catch (e) {
      throw Exception('Failed to synthesize text: ${e.message}');
    }
  }
}
