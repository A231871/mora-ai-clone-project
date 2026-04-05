/// All UI strings in one place.
/// Never write inline text strings in widgets — always reference this class.
///
/// App brand  : "MORA AI"  ← product/app name (unchanged)
/// Character  : "Shizuki"  ← official assistant character name
class AppStrings {
  AppStrings._();

  // ── App ──────────────────────────────────────────────────────────────────
  static const appName    = 'Shizuki AI';
  static const appVersion = 'v2.5.0';

  // ── Start Screen ─────────────────────────────────────────────────────────
  static const systemOnline  = '◆ SYSTEM ONLINE ◆';
  static const moraTitle     = 'SHIZUKI';
  static const subtitle      = 'VIRTUAL ASSISTANT';
  static const tapToStart    = '◆ TAP TO START ◆';
  static const startCaption  = 'Your cute AI companion awaits ✦';

  // ── Auth ─────────────────────────────────────────────────────────────────
  static const welcomeBack         = 'WELCOME BACK';
  static const loginSubtitle       = 'Sign in to continue your journey ✦';
  static const joinMora            = 'JOIN SHIZUKI';
  static const signupSubtitle      = 'Create your new account ✦';
  static const logIn               = 'LOG IN';
  static const signUp              = 'SIGN UP';
  static const createAccount       = 'CREATE ACCOUNT';
  static const backToLogin         = 'BACK TO LOGIN';
  static const forgotPassword      = 'Forgot password?';
  static const orDivider           = '— OR —';
  static const usernameLabel       = 'USERNAME';
  static const passwordLabel       = 'PASSWORD';
  static const usernamePlaceholder = 'Enter your username...';
  static const passwordPlaceholder = 'Enter your password...';

  // ── Home ─────────────────────────────────────────────────────────────────
  static const goodMorning      = 'GOOD MORNING';
  static const commander        = 'COMMANDER ✦';
  static const shizukiOnline    = '◆ SHIZUKI ONLINE';
  static const moodHappy        = '♦ HAPPY';
  static const battery          = '⚡ 98%';
  static const shizukiGreeting  = "Hiii~ I'm Shizuki! How can I help you today? ✨";
  static const quickAccess      = '— QUICK ACCESS —';
  static const chat             = 'CHAT';
  static const remind           = 'REMIND';
  static const config           = 'CONFIG';

  // ── Chat ─────────────────────────────────────────────────────────────────
  static const chatMode      = 'CHAT MODE';
  static const todayLabel    = '— TODAY —';
  static const chatHint      = 'Type a message to Shizuki~';
  static const noChatYet     = 'No messages yet. Say hi to Shizuki! 🌸';
  static const shizukiSender = 'SHIZUKI';
  static const youSender     = 'YOU';

  // ── Reminders ────────────────────────────────────────────────────────────
  static const remindersTitle   = "SHIZUKI'S REMINDERS";
  static const noRemindersYet   = 'No reminders yet. Add one! ✨';
  static const addReminderSnack = 'Add reminder — coming soon! 🔔';
  static const categoryWork     = 'WORK';
  static const categoryHealth   = 'HEALTH';
  static const categoryShizuki  = 'SHIZUKI';
  static const categorySocial   = 'SOCIAL';

  // ── Config ───────────────────────────────────────────────────────────────
  static const systemControl    = '⚙ SYSTEM CONTROL';
  static const audioSystems     = '— AUDIO SYSTEMS —';
  static const voiceSelection   = '— VOICE SELECTION —';
  static const systemControls   = '— SYSTEM CONTROLS —';
  static const masterVolume     = 'MASTER VOLUME';
  static const effectVolume     = 'EFFECT VOLUME';
  static const shizukisVoice    = "SHIZUKI'S VOICE";
  static const darkMode         = 'DARK MODE';
  static const darkModeSub      = 'Easier on the eyes';
  static const notifications    = 'NOTIFICATIONS';
  static const notificationsSub = 'System alerts & reminders';
  static const shizukiVoice     = 'SHIZUKI VOICE';
  static const shizukiVoiceSub  = 'Enable voice responses';
  static const hapticFeedback   = 'HAPTIC FEEDBACK';
  static const hapticSub        = 'Touch vibrations';
  static const privacyShield    = 'PRIVACY SHIELD';
  static const privacySub       = 'Encrypt conversation data';
  static const sessionWarning   = '⚠ CAUTION · SESSION TERMINATE';
  static const exitToStart      = '[→ EXIT TO START]';

  // ── Back button ──────────────────────────────────────────────────────────
  static const back = '< BACK';
}
