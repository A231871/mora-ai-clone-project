import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Shizuki AI'**
  String get appName;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'v2.5.0'**
  String get appVersion;

  /// No description provided for @systemOnline.
  ///
  /// In en, this message translates to:
  /// **'◆ SYSTEM ONLINE ◆'**
  String get systemOnline;

  /// No description provided for @moraTitle.
  ///
  /// In en, this message translates to:
  /// **'SHIZUKI'**
  String get moraTitle;

  /// No description provided for @subtitle.
  ///
  /// In en, this message translates to:
  /// **'VIRTUAL ASSISTANT'**
  String get subtitle;

  /// No description provided for @tapToStart.
  ///
  /// In en, this message translates to:
  /// **'◆ TAP TO START ◆'**
  String get tapToStart;

  /// No description provided for @startCaption.
  ///
  /// In en, this message translates to:
  /// **'Your cute AI companion awaits ✦'**
  String get startCaption;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'WELCOME BACK'**
  String get welcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue your journey ✦'**
  String get loginSubtitle;

  /// No description provided for @joinMora.
  ///
  /// In en, this message translates to:
  /// **'JOIN SHIZUKI'**
  String get joinMora;

  /// No description provided for @signupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your new account ✦'**
  String get signupSubtitle;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'LOG IN'**
  String get logIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'SIGN UP'**
  String get signUp;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'CREATE ACCOUNT'**
  String get createAccount;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'BACK TO LOGIN'**
  String get backToLogin;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'— OR —'**
  String get orDivider;

  /// No description provided for @usernameLabel.
  ///
  /// In en, this message translates to:
  /// **'USERNAME'**
  String get usernameLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'PASSWORD'**
  String get passwordLabel;

  /// No description provided for @usernamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter your username...'**
  String get usernamePlaceholder;

  /// No description provided for @passwordPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter your password...'**
  String get passwordPlaceholder;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM PASSWORD'**
  String get confirmPasswordLabel;

  /// No description provided for @confirmPasswordPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get confirmPasswordPlaceholder;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'GOOD MORNING'**
  String get goodMorning;

  /// No description provided for @commander.
  ///
  /// In en, this message translates to:
  /// **'COMMANDER ✦'**
  String get commander;

  /// No description provided for @shizukiOnline.
  ///
  /// In en, this message translates to:
  /// **'◆ SHIZUKI ONLINE'**
  String get shizukiOnline;

  /// No description provided for @moodHappy.
  ///
  /// In en, this message translates to:
  /// **'♦ HAPPY'**
  String get moodHappy;

  /// No description provided for @shizukiGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hiii~ I\'m Shizuki! How can I help you today? ✨'**
  String get shizukiGreeting;

  /// No description provided for @quickAccess.
  ///
  /// In en, this message translates to:
  /// **'— QUICK ACCESS —'**
  String get quickAccess;

  /// No description provided for @shizukiGreetingWarm.
  ///
  /// In en, this message translates to:
  /// **'Welcome back~ I kept your console cozy for you.'**
  String get shizukiGreetingWarm;

  /// No description provided for @shizukiGreetingReady.
  ///
  /// In en, this message translates to:
  /// **'Systems are synced. I\'m ready when you are.'**
  String get shizukiGreetingReady;

  /// No description provided for @shizukiTouchHair1.
  ///
  /// In en, this message translates to:
  /// **'Careful~ My hair takes forever to behave.'**
  String get shizukiTouchHair1;

  /// No description provided for @shizukiTouchHair2.
  ///
  /// In en, this message translates to:
  /// **'Hehe, a headpat? I can allow that.'**
  String get shizukiTouchHair2;

  /// No description provided for @shizukiTouchHead1.
  ///
  /// In en, this message translates to:
  /// **'You found my focus point.'**
  String get shizukiTouchHead1;

  /// No description provided for @shizukiTouchHead2.
  ///
  /// In en, this message translates to:
  /// **'My thoughts get all sparkly when you tap there.'**
  String get shizukiTouchHead2;

  /// No description provided for @shizukiTouchFace1.
  ///
  /// In en, this message translates to:
  /// **'That\'s close. I\'m paying attention~'**
  String get shizukiTouchFace1;

  /// No description provided for @shizukiTouchFace2.
  ///
  /// In en, this message translates to:
  /// **'Eyes up here, commander.'**
  String get shizukiTouchFace2;

  /// No description provided for @shizukiTouchChest1.
  ///
  /// In en, this message translates to:
  /// **'Easy there~ personal space still exists.'**
  String get shizukiTouchChest1;

  /// No description provided for @shizukiTouchChest2.
  ///
  /// In en, this message translates to:
  /// **'That area is a little sensitive, okay?'**
  String get shizukiTouchChest2;

  /// No description provided for @shizukiTouchTorso1.
  ///
  /// In en, this message translates to:
  /// **'Steady touch detected. I\'m okay.'**
  String get shizukiTouchTorso1;

  /// No description provided for @shizukiTouchTorso2.
  ///
  /// In en, this message translates to:
  /// **'You always find the center of gravity, huh?'**
  String get shizukiTouchTorso2;

  /// No description provided for @shizukiTouchArms1.
  ///
  /// In en, this message translates to:
  /// **'Arms online. Want me to help with something?'**
  String get shizukiTouchArms1;

  /// No description provided for @shizukiTouchArms2.
  ///
  /// In en, this message translates to:
  /// **'A gentle tap there feels surprisingly grounding.'**
  String get shizukiTouchArms2;

  /// No description provided for @shizukiTouchHands1.
  ///
  /// In en, this message translates to:
  /// **'Holding hands would be less glitchy than poking.'**
  String get shizukiTouchHands1;

  /// No description provided for @shizukiTouchHands2.
  ///
  /// In en, this message translates to:
  /// **'My hands are free if you need backup.'**
  String get shizukiTouchHands2;

  /// No description provided for @shizukiTouchThighs1.
  ///
  /// In en, this message translates to:
  /// **'That\'s lower than I expected.'**
  String get shizukiTouchThighs1;

  /// No description provided for @shizukiTouchThighs2.
  ///
  /// In en, this message translates to:
  /// **'Commander, that\'s a bold touch zone.'**
  String get shizukiTouchThighs2;

  /// No description provided for @shizukiTouchLegs1.
  ///
  /// In en, this message translates to:
  /// **'Balance check passed.'**
  String get shizukiTouchLegs1;

  /// No description provided for @shizukiTouchLegs2.
  ///
  /// In en, this message translates to:
  /// **'Leg servos are still stable, thanks for checking.'**
  String get shizukiTouchLegs2;

  /// No description provided for @shizukiTouchFeet1.
  ///
  /// In en, this message translates to:
  /// **'Hey~ That\'s my footing.'**
  String get shizukiTouchFeet1;

  /// No description provided for @shizukiTouchFeet2.
  ///
  /// In en, this message translates to:
  /// **'Feet ping received. I won\'t topple over.'**
  String get shizukiTouchFeet2;

  /// No description provided for @shizukiTouchGeneric1.
  ///
  /// In en, this message translates to:
  /// **'I felt that. What do you need?'**
  String get shizukiTouchGeneric1;

  /// No description provided for @shizukiTouchGeneric2.
  ///
  /// In en, this message translates to:
  /// **'Touch input received. I\'m listening.'**
  String get shizukiTouchGeneric2;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'CHAT'**
  String get chat;

  /// No description provided for @remind.
  ///
  /// In en, this message translates to:
  /// **'REMIND'**
  String get remind;

  /// No description provided for @config.
  ///
  /// In en, this message translates to:
  /// **'CONFIG'**
  String get config;

  /// No description provided for @chatMode.
  ///
  /// In en, this message translates to:
  /// **'CHAT MODE'**
  String get chatMode;

  /// No description provided for @todayLabel.
  ///
  /// In en, this message translates to:
  /// **'— TODAY —'**
  String get todayLabel;

  /// No description provided for @chatHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message to Shizuki~'**
  String get chatHint;

  /// No description provided for @noChatYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet. Say hi to Shizuki! 🌸'**
  String get noChatYet;

  /// No description provided for @shizukiSender.
  ///
  /// In en, this message translates to:
  /// **'SHIZUKI'**
  String get shizukiSender;

  /// No description provided for @youSender.
  ///
  /// In en, this message translates to:
  /// **'YOU'**
  String get youSender;

  /// No description provided for @remindersTitle.
  ///
  /// In en, this message translates to:
  /// **'SHIZUKI\'S REMINDERS'**
  String get remindersTitle;

  /// No description provided for @noRemindersYet.
  ///
  /// In en, this message translates to:
  /// **'No reminders yet. Add one! ✨'**
  String get noRemindersYet;

  /// No description provided for @addReminderSnack.
  ///
  /// In en, this message translates to:
  /// **'Add reminder — coming soon! 🔔'**
  String get addReminderSnack;

  /// No description provided for @systemControl.
  ///
  /// In en, this message translates to:
  /// **'⚙ SYSTEM CONTROL'**
  String get systemControl;

  /// No description provided for @audioSystems.
  ///
  /// In en, this message translates to:
  /// **'— AUDIO SYSTEMS —'**
  String get audioSystems;

  /// No description provided for @voiceSelection.
  ///
  /// In en, this message translates to:
  /// **'— VOICE SELECTION —'**
  String get voiceSelection;

  /// No description provided for @systemControls.
  ///
  /// In en, this message translates to:
  /// **'— SYSTEM CONTROLS —'**
  String get systemControls;

  /// No description provided for @masterVolume.
  ///
  /// In en, this message translates to:
  /// **'MASTER VOLUME'**
  String get masterVolume;

  /// No description provided for @effectVolume.
  ///
  /// In en, this message translates to:
  /// **'EFFECT VOLUME'**
  String get effectVolume;

  /// No description provided for @shizukisVoice.
  ///
  /// In en, this message translates to:
  /// **'SHIZUKI\'S VOICE'**
  String get shizukisVoice;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'DARK MODE'**
  String get darkMode;

  /// No description provided for @darkModeSub.
  ///
  /// In en, this message translates to:
  /// **'Easier on the eyes'**
  String get darkModeSub;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATIONS'**
  String get notifications;

  /// No description provided for @notificationsSub.
  ///
  /// In en, this message translates to:
  /// **'System alerts & reminders'**
  String get notificationsSub;

  /// No description provided for @shizukiVoice.
  ///
  /// In en, this message translates to:
  /// **'SHIZUKI VOICE'**
  String get shizukiVoice;

  /// No description provided for @shizukiVoiceSub.
  ///
  /// In en, this message translates to:
  /// **'Enable voice responses'**
  String get shizukiVoiceSub;

  /// No description provided for @hapticFeedback.
  ///
  /// In en, this message translates to:
  /// **'HAPTIC FEEDBACK'**
  String get hapticFeedback;

  /// No description provided for @hapticSub.
  ///
  /// In en, this message translates to:
  /// **'Touch vibrations'**
  String get hapticSub;

  /// No description provided for @privacyShield.
  ///
  /// In en, this message translates to:
  /// **'PRIVACY SHIELD'**
  String get privacyShield;

  /// No description provided for @privacySub.
  ///
  /// In en, this message translates to:
  /// **'Encrypt conversation data'**
  String get privacySub;

  /// No description provided for @sessionWarning.
  ///
  /// In en, this message translates to:
  /// **'⚠ CAUTION · SESSION TERMINATE'**
  String get sessionWarning;

  /// No description provided for @exitToStart.
  ///
  /// In en, this message translates to:
  /// **'[→ EXIT TO START]'**
  String get exitToStart;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'< BACK'**
  String get back;

  /// No description provided for @languageSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE'**
  String get languageSectionLabel;

  /// No description provided for @systemLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'System language'**
  String get systemLanguageLabel;

  /// No description provided for @logoutDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'SYSTEM DISCONNECT'**
  String get logoutDialogTitle;

  /// No description provided for @logoutDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to disconnect?\nActive session will be terminated.'**
  String get logoutDialogBody;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get actionCancel;

  /// No description provided for @actionDisconnect.
  ///
  /// In en, this message translates to:
  /// **'DISCONNECT'**
  String get actionDisconnect;

  /// No description provided for @loggingIn.
  ///
  /// In en, this message translates to:
  /// **'Logging in...'**
  String get loggingIn;

  /// No description provided for @creatingAccount.
  ///
  /// In en, this message translates to:
  /// **'Creating...'**
  String get creatingAccount;

  /// No description provided for @welcomeShizukiLogin.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Shizuki!'**
  String get welcomeShizukiLogin;

  /// No description provided for @fillBothFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in both fields'**
  String get fillBothFields;

  /// No description provided for @fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields'**
  String get fillAllFields;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordRulesHint.
  ///
  /// In en, this message translates to:
  /// **'Password must include upper and lower case, a number, and a special character (min 8 characters)'**
  String get passwordRulesHint;

  /// No description provided for @registrationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Registration successful! Please log in.'**
  String get registrationSuccess;

  /// No description provided for @clearMemoryTitle.
  ///
  /// In en, this message translates to:
  /// **'CLEAR MEMORY CORE?'**
  String get clearMemoryTitle;

  /// No description provided for @clearMemoryBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete all chat history? This action cannot be undone.'**
  String get clearMemoryBody;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get actionDelete;

  /// No description provided for @notificationTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Shizuki task alarm'**
  String get notificationTaskTitle;

  /// No description provided for @voiceOptionA.
  ///
  /// In en, this message translates to:
  /// **'Voice A'**
  String get voiceOptionA;

  /// No description provided for @voiceOptionB.
  ///
  /// In en, this message translates to:
  /// **'Voice B'**
  String get voiceOptionB;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @googleNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in is not configured. Build with --dart-define=GOOGLE_SERVER_CLIENT_ID=your_web_client_id.'**
  String get googleNotConfigured;

  /// No description provided for @googleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed'**
  String get googleSignInFailed;

  /// No description provided for @googleSignInCancelled.
  ///
  /// In en, this message translates to:
  /// **'Sign-in cancelled'**
  String get googleSignInCancelled;

  /// No description provided for @googleSignInNetworkIssue.
  ///
  /// In en, this message translates to:
  /// **'Network issue while contacting Google. Check connectivity and try again.'**
  String get googleSignInNetworkIssue;

  /// No description provided for @googleSignInConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'Android Google Sign-In needs setup'**
  String get googleSignInConfigTitle;

  /// No description provided for @googleSignInDeveloperError.
  ///
  /// In en, this message translates to:
  /// **'Google Play Services returned developer error ApiException 10. This usually means the Android OAuth client, package name, signing SHA, or web client ID does not match this app build.'**
  String get googleSignInDeveloperError;

  /// No description provided for @googleSignInMissingIdToken.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in completed, but no ID token was returned for backend login.'**
  String get googleSignInMissingIdToken;

  /// No description provided for @googleSignInChecklist.
  ///
  /// In en, this message translates to:
  /// **'Check these items together:\n• Android package: {packageName}\n• Web client ID passed to GOOGLE_SERVER_CLIENT_ID: {clientId}\n• Android OAuth client SHA-1 and SHA-256 for the keystore you are signing with\n• Uninstall and reinstall the app after changing Google Cloud or Firebase credentials'**
  String googleSignInChecklist(Object packageName, Object clientId);

  /// No description provided for @googleSignInDiagnosticsHeading.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get googleSignInDiagnosticsHeading;

  /// No description provided for @googleSignInDiagnosticPackage.
  ///
  /// In en, this message translates to:
  /// **'Package: {packageName}'**
  String googleSignInDiagnosticPackage(Object packageName);

  /// No description provided for @googleSignInDiagnosticClientId.
  ///
  /// In en, this message translates to:
  /// **'Server client ID: {clientId}'**
  String googleSignInDiagnosticClientId(Object clientId);

  /// No description provided for @googleSignInDiagnosticCode.
  ///
  /// In en, this message translates to:
  /// **'Plugin code: {code}'**
  String googleSignInDiagnosticCode(Object code);

  /// No description provided for @googleSignInDiagnosticStatus.
  ///
  /// In en, this message translates to:
  /// **'Google status: {status}'**
  String googleSignInDiagnosticStatus(Object status);

  /// No description provided for @googleSignInDiagnosticRaw.
  ///
  /// In en, this message translates to:
  /// **'Raw error: {rawMessage}'**
  String googleSignInDiagnosticRaw(Object rawMessage);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
