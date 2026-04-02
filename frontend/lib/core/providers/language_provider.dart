import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _languagePrefsKey = 'language_code';

final languageProvider = NotifierProvider<LanguageNotifier, Locale>(() {
  return LanguageNotifier();
});

class LanguageNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    _loadLanguage();
    return const Locale('en');
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? languageCode = prefs.getString(_languagePrefsKey);
    if (languageCode != null && languageCode.isNotEmpty) {
      state = Locale(languageCode);
    }
  }

  Future<void> setLanguage(String languageCode) async {
    state = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languagePrefsKey, languageCode);
  }
}
