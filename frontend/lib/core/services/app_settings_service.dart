import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsService {
  AppSettingsService._();

  static final AppSettingsService instance = AppSettingsService._();

  static const String _masterVolumeKey = 'settings_master_volume';
  static const String _voiceVolumeKey = 'settings_voice_volume';
  static const String _notificationsEnabledKey =
      'settings_notifications_enabled';
  static const String _shizukiVoiceEnabledKey =
      'settings_shizuki_voice_enabled';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> ensureInitialized() async {
    await _getPrefs();
  }

  Future<double> getMasterVolume() async {
    final prefs = await _getPrefs();
    return prefs.getDouble(_masterVolumeKey) ?? 0.75;
  }

  Future<void> setMasterVolume(double value) async {
    final prefs = await _getPrefs();
    await prefs.setDouble(_masterVolumeKey, value.clamp(0, 1).toDouble());
  }

  Future<double> getVoiceVolume() async {
    final prefs = await _getPrefs();
    return prefs.getDouble(_voiceVolumeKey) ?? 0.5;
  }

  Future<void> setVoiceVolume(double value) async {
    final prefs = await _getPrefs();
    await prefs.setDouble(_voiceVolumeKey, value.clamp(0, 1).toDouble());
  }

  Future<bool> getNotificationsEnabled() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  Future<void> setNotificationsEnabled(bool value) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_notificationsEnabledKey, value);
  }

  Future<bool> getShizukiVoiceEnabled() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_shizukiVoiceEnabledKey) ?? true;
  }

  Future<void> setShizukiVoiceEnabled(bool value) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_shizukiVoiceEnabledKey, value);
  }
}
