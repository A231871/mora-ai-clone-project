/// Web OAuth 2.0 client ID (ends in `.apps.googleusercontent.com`).
/// Required on Android/iOS to obtain an ID token for the backend.
/// Pass at build time: `--dart-define=GOOGLE_SERVER_CLIENT_ID=...`
class GoogleSignInConfig {
  GoogleSignInConfig._();

  static const String serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );

  static bool get isConfigured => serverClientId.isNotEmpty;
}
