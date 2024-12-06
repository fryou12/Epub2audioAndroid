import 'tts_service.dart';
import 'flutter_tts_service.dart';
import 'edge_tts_service.dart';

class TTSFactory {
  static TTSService createTTSService(TTSEngineType type) {
    switch (type) {
      case TTSEngineType.flutterTTS:
        return FlutterTTSService();
      case TTSEngineType.edgeTTS:
        return EdgeTTSService();
      default:
        throw UnimplementedError('Type de moteur TTS non supporté');
    }
  }
}
