/// Web OAuth 2.0 client ID (ends in `.apps.googleusercontent.com`).
/// Pass at build time: `--dart-define=GOOGLE_SERVER_CLIENT_ID=...`
///
/// On Android, the native plugin can also fall back to `default_web_client_id`
/// from `google-services.json` when present. We keep the explicit define
/// available because the backend requires an ID token bound to a web client.
class GoogleSignInConfig {
  GoogleSignInConfig._();

  static const String androidPackageName = 'com.nguyenhuutho.shizukiai';

  static const String serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );

  static bool get hasExplicitServerClientId => serverClientId.isNotEmpty;

  static String? get serverClientIdOrNull =>
      serverClientId.isEmpty ? null : serverClientId;

  static String get serverClientIdDisplay {
    if (serverClientId.isEmpty) {
      return '(not set)';
    }

    final atIndex = serverClientId.indexOf('.apps.googleusercontent.com');
    final visiblePrefix = serverClientId.length > 16
        ? '${serverClientId.substring(0, 12)}...'
        : serverClientId;

    if (atIndex == -1) {
      return visiblePrefix;
    }

    return '$visiblePrefix.apps.googleusercontent.com';
  }
}

class GoogleSignInConfigSnapshot {
  const GoogleSignInConfigSnapshot({
    required this.androidPackageName,
    required this.hasExplicitServerClientId,
    required this.serverClientIdDisplay,
  });

  factory GoogleSignInConfigSnapshot.current() {
    return GoogleSignInConfigSnapshot(
      androidPackageName: GoogleSignInConfig.androidPackageName,
      hasExplicitServerClientId: GoogleSignInConfig.hasExplicitServerClientId,
      serverClientIdDisplay: GoogleSignInConfig.serverClientIdDisplay,
    );
  }

  final String androidPackageName;
  final bool hasExplicitServerClientId;
  final String serverClientIdDisplay;
}
