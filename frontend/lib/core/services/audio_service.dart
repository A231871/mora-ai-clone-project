import 'package:audioplayers/audioplayers.dart';

import 'app_settings_service.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _uiPlayer = AudioPlayer();
  double _masterVolume = 0.75;
  bool _initialized = false;

  Future<void> init() async {
    _masterVolume = await AppSettingsService.instance.getMasterVolume();
    await _uiPlayer.setVolume(_masterVolume);
    await _uiPlayer.setSource(AssetSource('sounds/beep.wav'));
    _initialized = true;
  }

  double get masterVolume => _masterVolume;

  Future<void> setMasterVolume(double volume) async {
    _masterVolume = volume;
    await AppSettingsService.instance.setMasterVolume(volume);
    await _uiPlayer.setVolume(_masterVolume);
  }

  Future<void> playBeep() async {
    if (!_initialized) {
      await init();
    }
    await _uiPlayer.stop();
    await _uiPlayer.play(AssetSource('sounds/beep.wav'), volume: _masterVolume);
  }
}
