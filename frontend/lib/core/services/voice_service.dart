import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isSttInitialized = false;

  Future<void> init() async {
    // Setup TTS specific to 'Mora' personality
    await _flutterTts.setLanguage("vi-VN");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.2);
  }

  Future<void> speak(String text) async {
    // Strip markdown chars so Mora doesn't speak asterisks
    String cleanText = text.replaceAll(RegExp(r'[*_`#]'), '');
    await _flutterTts.speak(cleanText);
  }

  Future<void> setVolume(double volume) async {
    await _flutterTts.setVolume(volume);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  Future<bool> _requestMicrophonePermissions() async {
    // EXPLICITLY check and request permissions at time of listening!
    var status = await Permission.microphone.request();
    if (status.isGranted) {
      if (!_isSttInitialized) {
        _isSttInitialized = await _speech.initialize(
          onError: (val) => print('STT Error: $val'),
          onStatus: (val) => print('STT Status: $val'),
        );
      }
      return _isSttInitialized;
    }
    print("Microphone permission denied explicitly by OS.");
    return false;
  }

  Future<void> startListening(Function(String) onResult) async {
    bool hasPermission = await _requestMicrophonePermissions();
    if (hasPermission) {
      await _speech.listen(
        onResult: (val) => onResult(val.recognizedWords),
        localeId: "vi-VN"
      );
    }
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }
}
