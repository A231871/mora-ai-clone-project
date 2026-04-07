import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

import 'app_settings_service.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isSttInitialized = false;
  bool _isConfigured = false;
  bool _isEnabled = true;
  double _volume = 0.5;

  Future<void> init() async {
    _volume = await AppSettingsService.instance.getVoiceVolume();
    _isEnabled = await AppSettingsService.instance.getShizukiVoiceEnabled();
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(_volume);
    await _flutterTts.setPitch(1.2);
    _isConfigured = true;
  }

  Future<void> speak(String text, {String languageCode = 'en'}) async {
    if (!_isConfigured) {
      await init();
    }
    if (!_isEnabled) {
      return;
    }
    await _flutterTts.setLanguage(languageCode == 'vi' ? 'vi-VN' : 'en-US');
    String cleanText = text.replaceAll(RegExp(r'[*_`#]'), '');
    await _flutterTts.speak(cleanText);
  }

  Future<void> setVolume(double volume) async {
    _volume = volume;
    await AppSettingsService.instance.setVoiceVolume(volume);
    await _flutterTts.setVolume(volume);
  }

  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    await AppSettingsService.instance.setShizukiVoiceEnabled(enabled);
    if (!enabled) {
      await stop();
    }
  }

  bool get isEnabled => _isEnabled;
  double get volume => _volume;

  Future<void> refreshSettings() async {
    _volume = await AppSettingsService.instance.getVoiceVolume();
    _isEnabled = await AppSettingsService.instance.getShizukiVoiceEnabled();
    await _flutterTts.setVolume(_volume);
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

  Future<void> startListening(Function(String) onResult,
      {String languageCode = 'en'}) async {
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
