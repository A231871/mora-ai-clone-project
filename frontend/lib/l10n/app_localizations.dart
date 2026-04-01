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
  /// **'Mora AI'**
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
  /// **'MORA'**
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
  /// **'JOIN MORA'**
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
