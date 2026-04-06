# Android Google Sign-In Setup

This app signs in on Android as package `com.nguyenhuutho.shizukiai`.

## Required OAuth configuration

1. Create or identify a Web OAuth client in Google Cloud Console.
2. Build the Flutter app with that Web client ID:

```bash
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
```

3. Create or update an Android OAuth client for:
   - Package name: `com.nguyenhuutho.shizukiai`
   - Signing certificate SHA-1
   - Signing certificate SHA-256

Use the SHA fingerprints for the exact keystore used by the build you are testing. Debug and release builds often use different keys.

## Common failure: `ApiException: 10`

`ApiException: 10` is a developer configuration error. It usually means one of these does not match the current build:

- Android package name
- SHA-1 / SHA-256 fingerprints
- Web client ID passed as `GOOGLE_SERVER_CLIENT_ID`

## After changing Google config

1. Uninstall the app from the device or emulator.
2. Rebuild and reinstall the app.
3. Try Google sign-in again.

If you choose native resource-based fallback instead of `--dart-define`, make sure Android provides `default_web_client_id` from `google-services.json`.
