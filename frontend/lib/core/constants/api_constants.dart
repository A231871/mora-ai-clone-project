import 'dart:io';

class ApiConstants {
  static String get socketUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000';
    } else {
      return 'http://localhost:5000';
    }
  }

  // Automatically switch between localhost (iOS) and 10.0.2.2 (Android Emulator)
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/api';
    } else {
      return 'http://localhost:5000/api';
    }
  }

  static String get loginEndpoint => '$baseUrl/auth/login';
  static String get registerEndpoint => '$baseUrl/auth/register';
  static String get googleAuthEndpoint => '$baseUrl/auth/google';
}