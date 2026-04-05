import 'package:flutter/foundation.dart';
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
    // Setup TTS defaults for Shizuki
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.2);
  }

  Future<void> speak(String text, {String languageCode = 'en'}) async {
    // Dynamically switch TTS voice engine to match current locale
    await _flutterTts.setLanguage(languageCode == 'vi' ? 'vi-VN' : 'en-US');
    // Strip markdown chars so Shizuki doesn't speak asterisks
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
          onError: (val) => debugPrint('STT Error: $val'),
          onStatus: (val) => debugPrint('STT Status: $val'),
        );
      }
      return _isSttInitialized;
    }
    debugPrint("Microphone permission denied explicitly by OS.");
    return false;
  }

  Future<void> startListening(Function(String) onResult, {String languageCode = 'en'}) async {
    bool hasPermission = await _requestMicrophonePermissions();
    if (hasPermission) {
      await _speech.listen(
        onResult: (val) => onResult(val.recognizedWords),
        localeId: languageCode == 'vi' ? 'vi-VN' : 'en-US',
      );
    }
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }
}