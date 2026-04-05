// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Shizuki AI';

  @override
  String get appVersion => 'v2.5.0';

  @override
  String get systemOnline => '◆ SYSTEM ONLINE ◆';

  @override
  String get moraTitle => 'SHIZUKI';

  @override
  String get subtitle => 'VIRTUAL ASSISTANT';

  @override
  String get tapToStart => '◆ TAP TO START ◆';

  @override
  String get startCaption => 'Your cute AI companion awaits ✦';

  @override
  String get welcomeBack => 'WELCOME BACK';

  @override
  String get loginSubtitle => 'Sign in to continue your journey ✦';

  @override
  String get joinMora => 'JOIN SHIZUKI';

  @override
  String get signupSubtitle => 'Create your new account ✦';

  @override
  String get logIn => 'LOG IN';

  @override
  String get signUp => 'SIGN UP';

  @override
  String get createAccount => 'CREATE ACCOUNT';

  @override
  String get backToLogin => 'BACK TO LOGIN';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get orDivider => '— OR —';

  @override
  String get usernameLabel => 'USERNAME';

  @override
  String get passwordLabel => 'PASSWORD';

  @override
  String get usernamePlaceholder => 'Enter your username...';

  @override
  String get passwordPlaceholder => 'Enter your password...';

  @override
  String get confirmPasswordLabel => 'CONFIRM PASSWORD';

  @override
  String get confirmPasswordPlaceholder => 'Re-enter your password';

  @override
  String get goodMorning => 'GOOD MORNING';

  @override
  String get commander => 'COMMANDER ✦';

  @override
  String get shizukiOnline => '◆ SHIZUKI ONLINE';

  @override
  String get moodHappy => '♦ HAPPY';

  @override
  String get shizukiGreeting =>
      'Hiii~ I\'m Shizuki! How can I help you today? ✨';

  @override
  String get quickAccess => '— QUICK ACCESS —';

  @override
  String get chat => 'CHAT';

  @override
  String get remind => 'REMIND';

  @override
  String get config => 'CONFIG';

  @override
  String get chatMode => 'CHAT MODE';

  @override
  String get todayLabel => '— TODAY —';

  @override
  String get chatHint => 'Type a message to Shizuki~';

  @override
  String get noChatYet => 'No messages yet. Say hi to Shizuki! 🌸';

  @override
  String get shizukiSender => 'SHIZUKI';

  @override
  String get youSender => 'YOU';

  @override
  String get remindersTitle => 'SHIZUKI\'S REMINDERS';

  @override
  String get noRemindersYet => 'No reminders yet. Add one! ✨';

  @override
  String get addReminderSnack => 'Add reminder — coming soon! 🔔';

  @override
  String get systemControl => '⚙ SYSTEM CONTROL';

  @override
  String get audioSystems => '— AUDIO SYSTEMS —';

  @override
  String get voiceSelection => '— VOICE SELECTION —';

  @override
  String get systemControls => '— SYSTEM CONTROLS —';

  @override
  String get masterVolume => 'MASTER VOLUME';

  @override
  String get effectVolume => 'EFFECT VOLUME';

  @override
  String get shizukisVoice => 'SHIZUKI\'S VOICE';

  @override
  String get darkMode => 'DARK MODE';

  @override
  String get darkModeSub => 'Easier on the eyes';

  @override
  String get notifications => 'NOTIFICATIONS';

  @override
  String get notificationsSub => 'System alerts & reminders';

  @override
  String get shizukiVoice => 'SHIZUKI VOICE';

  @override
  String get shizukiVoiceSub => 'Enable voice responses';

  @override
  String get hapticFeedback => 'HAPTIC FEEDBACK';

  @override
  String get hapticSub => 'Touch vibrations';

  @override
  String get privacyShield => 'PRIVACY SHIELD';

  @override
  String get privacySub => 'Encrypt conversation data';

  @override
  String get sessionWarning => '⚠ CAUTION · SESSION TERMINATE';

  @override
  String get exitToStart => '[→ EXIT TO START]';

  @override
  String get back => '< BACK';

  @override
  String get languageSectionLabel => 'LANGUAGE';

  @override
  String get systemLanguageLabel => 'System language';

  @override
  String get logoutDialogTitle => 'SYSTEM DISCONNECT';

  @override
  String get logoutDialogBody =>
      'Are you sure you want to disconnect?\nActive session will be terminated.';

  @override
  String get actionCancel => 'CANCEL';

  @override
  String get actionDisconnect => 'DISCONNECT';

  @override
  String get loggingIn => 'Logging in...';

  @override
  String get creatingAccount => 'Creating...';

  @override
  String get welcomeShizukiLogin => 'Welcome to Shizuki!';

  @override
  String get fillBothFields => 'Please fill in both fields';

  @override
  String get fillAllFields => 'Please fill in all fields';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get passwordRulesHint =>
      'Password must include upper and lower case, a number, and a special character (min 8 characters)';

  @override
  String get registrationSuccess => 'Registration successful! Please log in.';

  @override
  String get clearMemoryTitle => 'CLEAR MEMORY CORE?';

  @override
  String get clearMemoryBody =>
      'Are you sure you want to permanently delete all chat history? This action cannot be undone.';

  @override
  String get actionDelete => 'DELETE';

  @override
  String get notificationTaskTitle => 'Shizuki task alarm';

  @override
  String get voiceOptionA => 'Voice A';

  @override
  String get voiceOptionB => 'Voice B';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get googleNotConfigured =>
      'Google sign-in is not configured. Build with --dart-define=GOOGLE_SERVER_CLIENT_ID=your_web_client_id.';

  @override
  String get googleSignInFailed => 'Google sign-in failed';

  @override
  String get googleSignInCancelled => 'Sign-in cancelled';
}
