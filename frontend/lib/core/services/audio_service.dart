import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _uiPlayer = AudioPlayer();
  double _masterVolume = 0.75;

  Future<void> init() async {
    await _uiPlayer.setVolume(_masterVolume);
    // Pre-load the beep sound if desired, or just set audio context
    await _uiPlayer.setSource(AssetSource('sounds/beep.wav'));
  }

  void setMasterVolume(double volume) {
    _masterVolume = volume;
    _uiPlayer.setVolume(_masterVolume);
  }

  Future<void> playBeep() async {
    // Stop any currently playing UI sound (if overlapping rapidly)
    await _uiPlayer.stop();
    await _uiPlayer.play(AssetSource('sounds/beep.wav'), volume: _masterVolume);
  }
}
