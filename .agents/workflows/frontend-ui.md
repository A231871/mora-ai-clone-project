---
description: Build the Flutter frontend UI for Mora AI Virtual Companion (Bubble Mecha Pink theme, no animation/voice yet)
---

# Mora AI — Frontend UI Workflow
> **Scope:** UI-only. No backend calls, no animation, no voice/TTS yet.
> **Target:** Flutter (Dart) — 6 screens, Bubble Mecha Pink design.

---

## Step 0 — Verify Project & Folder Structure

The Flutter project already exists at `frontend/`. Confirm the target folder layout before writing any code:

```
frontend/lib/
├── core/
│   ├── constants/       ← AppColors, AppSpacing, AppRadius, AppStrings
│   ├── theme/           ← app_theme.dart, app_text_styles.dart
│   └── router/          ← app_router.dart
├── shared/
│   └── widgets/         ← reusable widgets (button, textfield, chip, appbar, bg)
└── features/
    ├── splash/screens/
    ├── auth/screens/
    ├── home/screens/
    ├── chat/
    │   ├── models/      ← message.dart
    │   └── screens/
    ├── reminders/
    │   ├── models/      ← task.dart
    │   └── screens/
    └── config/screens/
```

> **Rule:** ❌ Never hardcode colors or text. Always use `AppColors` / `AppStrings` constants.

---

## Step 1 — Add Required Packages

Edit `frontend/pubspec.yaml` — add under `dependencies`:

```yaml
  google_fonts: ^6.2.1       # Orbitron + Rajdhani (download locally — see Step 2)
  go_router: ^14.2.0         # Declarative routing
  flutter_svg: ^2.0.10+1     # SVG mecha icons — no pixel blur at any size
```

Download font files locally into `frontend/assets/fonts/` (Orbitron + Rajdhani `.ttf`) and declare in `pubspec.yaml`:

```yaml
flutter:
  fonts:
    - family: Orbitron
      fonts:
        - asset: assets/fonts/Orbitron-Bold.ttf
          weight: 700
    - family: Rajdhani
      fonts:
        - asset: assets/fonts/Rajdhani-Regular.ttf
        - asset: assets/fonts/Rajdhani-SemiBold.ttf
          weight: 600
  assets:
    - assets/avatar/
    - assets/fonts/
    - assets/icons/       # SVG mecha icons from Figma
    - assets/bg_grid.png  # 40×40px tiled grid PNG (see Step 3)
```

> ⚠️ Using local fonts (not Google Fonts runtime) avoids first-launch loading delay.

Then run:
```bash
cd frontend
flutter pub get
```

---

## Step 2 — Design Tokens

Create all constants in `frontend/lib/core/constants/`:

### `app_colors.dart`

| Constant | Hex | Usage |
|---|---|---|
| `bgDeep` | `#130822` | Page scaffold background |
| `bgCard` | `#1E0F35` | Cards, input fills |
| `primary` | `#FF3CAC` | Neon pink — buttons, borders, glow |
| `primaryDark` | `#C0006A` | Pressed states, inactive tab |
| `accent` | `#7B2FBE` | Purple — secondaries |
| `textPrimary` | `#FFFFFF` | Main text |
| `textSecondary` | `#D08ACA` | Labels, hints, timestamps |
| `statusGreen` | `#39FF14` | MORA ONLINE indicator |
| `chipWork` | `#FF6B6B` | Reminder WORK badge |
| `chipHealth` | `#6BFF9E` | Reminder HEALTH badge |
| `chipMora` | `#FF3CAC` | Reminder MORA badge |
| `chipSocial` | `#6BB5FF` | Reminder SOCIAL badge |

### `app_spacing.dart`
```dart
class AppSpacing {
  static const double xs   = 4.0;
  static const double sm   = 8.0;
  static const double md   = 16.0;
  static const double lg   = 24.0;
  static const double xl   = 32.0;
  static const double xxl  = 48.0;
}
```

### `app_radius.dart`
```dart
class AppRadius {
  static const double sm     = 8.0;
  static const double md     = 12.0;
  static const double lg     = 20.0;
  static const double pill   = 100.0;
}
```

### `app_strings.dart`
All UI text in English — one single source of truth. No inline strings in widget files.

```dart
class AppStrings {
  static const appName          = 'Mora AI';
  static const systemOnline     = '◆ SYSTEM ONLINE ◆';
  static const tapToStart       = '◆ TAP TO START ◆';
  static const welcomeBack      = 'WELCOME BACK';
  static const joinMora         = 'JOIN MORA';
  static const logIn            = 'LOG IN';
  static const signUp           = 'SIGN UP';
  static const createAccount    = 'CREATE ACCOUNT';
  static const backToLogin      = 'BACK TO LOGIN';
  static const quickAccess      = '— QUICK ACCESS —';
  static const chatMode         = 'CHAT MODE';
  static const remindersTitle   = "MORA'S REMINDERS";
  static const systemControl    = '⚙ SYSTEM CONTROL';
  static const exitToStart      = '[→ EXIT TO START]';
  static const chatHint         = 'Type a message to Mora~';
  static const noChatYet        = 'No messages yet. Say hi to Mora! 🌸';
  static const noRemindersYet   = 'No reminders yet. Add one! ✨';
  // ... add more as needed
}
```

---

## Step 3 — Theme & Typography

### `lib/core/theme/app_text_styles.dart`
- **Display / Titles:** `Orbitron` Bold 700, all-caps, letter-spacing 2–4, color `primary`
- **Body / Labels:** `Rajdhani` SemiBold 600, letter-spacing 1, color `textPrimary`
- **Hints / Timestamps:** `Rajdhani` Regular, color `textSecondary`

### `lib/core/theme/app_theme.dart`
```dart
ThemeData get mechaTheme => ThemeData(
  scaffoldBackgroundColor: AppColors.bgDeep,
  colorScheme: ColorScheme.dark(
    primary: AppColors.primary,
    surface: AppColors.bgCard,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.bgCard,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: AppColors.primary, width: 1.5),
    ),
    // ...
  ),
);
```

---

## Step 4 — Shared Widgets

Create `frontend/lib/shared/widgets/`:

### `grid_background.dart`
> ⚡ **Performance:** Do NOT use `CustomPainter` for the grid — it causes repaints on every frame.

Use a **tiled PNG** instead:
1. Export a 40×40px grid-cell PNG from Figma (or create manually) → `assets/bg_grid.png`
2. In the widget, use `Image.asset` with `repeat: ImageRepeat.repeat` inside a `SizedBox.expand`.
3. Wrap the screen `Stack` in `RepaintBoundary` to isolate it from children repaints.

```dart
// Usage on every screen
Stack(children: [
  const GridBackground(),
  // ... screen content
])
```

### `mecha_button.dart`
Pill-shaped button, two variants:

| Variant | Style |
|---|---|
| `primary` | Gradient `#FF3CAC → #7B2FBE` + `BoxShadow(blurRadius:15, spreadRadius:2, color: primary.withOpacity(0.6))` |
| `outlined` | Transparent fill + `Border.all(color: primary)` + same glow shadow |

- Label: `Orbitron` uppercase, letter-spacing 2
- Full-width by default (`double.infinity`)
- Use `const` constructor

### `glassmorphism_button.dart`
For the 3 Home quick-access circles:
- `BackdropFilter(filter: ImageFilter.blur(sigmaX:10, sigmaY:10))`
- `BoxDecoration` with `color: Colors.white.withOpacity(0.08)` + pink border
- SVG icon + label below

### `mecha_text_field.dart`
- Fill `bgCard`, border `primary` 1.5px, radius `AppRadius.md`
- `Rajdhani` hint in `textSecondary`
- Eye icon toggle for password fields
- Wrap in `SingleChildScrollView` parent on Login/Signup screens so content scrolls when keyboard appears

### `status_chip.dart`
Pill chip `(◆ LABEL)` with tinted bg + neon border. Props: `label`, `color`, `icon`.

### `mecha_app_bar.dart`
Reusable `PreferredSizeWidget` app bar for Chat / Reminders / Config screens:
- Left: `< BACK` text button → `context.pop()`
- Center: title (Orbitron)
- Right: optional icon slot
- Background: transparent (shows grid behind)

---

## Step 5 — Routing with Custom Transitions

Create `frontend/lib/core/router/app_router.dart`:

| Route | Path | Screen |
|---|---|---|
| `start` | `/` | `StartScreen` |
| `login` | `/login` | `LoginScreen` |
| `signup` | `/signup` | `SignupScreen` |
| `home` | `/home` | `HomeScreen` |
| `chat` | `/chat` | `ChatScreen` |
| `reminders` | `/reminders` | `RemindersScreen` |
| `config` | `/config` | `ConfigScreen` |

Use `CustomTransitionPage` for all routes to get a smooth **fade-in** instead of the default OS slide:

```dart
CustomTransitionPage(
  child: const StartScreen(),
  transitionsBuilder: (_, animation, __, child) =>
    FadeTransition(opacity: animation, child: child),
)
```

Navigation rules:
- `context.go('/home')` — for main screen jumps (replaces stack)
- `context.push('/chat')` — for sub-screens (keeps back stack)
- `context.pop()` — for `< BACK` buttons

Update `main.dart`:
```dart
MaterialApp.router(routerConfig: AppRouter.router)
```

---

## Step 6 — Data Models (UI-only, no backend)

Create lightweight models for state — prepares for Riverpod/backend later.

### `lib/features/chat/models/message.dart`
```dart
class Message {
  final String text;
  final bool isUser;
  final String timestamp; // e.g. "09:01"
  const Message({required this.text, required this.isUser, required this.timestamp});
}
```

### `lib/features/reminders/models/task.dart`
```dart
class Task {
  final String id;
  final String title;
  final String category;   // 'WORK' | 'HEALTH' | 'MORA' | 'SOCIAL'
  final String time;
  final String frequency;
  bool isDone;
  Task({required this.id, required this.title, required this.category,
        required this.time, required this.frequency, this.isDone = false});
}
```

> Use `setState` for toggling/deleting in this phase. Structure is Riverpod-ready for Phase 2.

---

## Step 7 — Start Screen (`/`)

File: `lib/features/splash/screens/start_screen.dart`

**Layout** (`Stack` → `GridBackground` behind, `Column` on top, centered):
1. `StatusChip('◆ SYSTEM ONLINE ◆', color: statusGreen)` — top center
2. `MORA` — Orbitron bold 42px, `primary`, subtle glow via `Shadow`
3. `VIRTUAL ASSISTANT` — Rajdhani, white, tracking 5
4. Avatar `Image.asset('assets/avatar/mora_avatar.png')` — large, with fallback:
   ```dart
   errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 120, color: AppColors.primary)
   ```
   Wrap in `RepaintBoundary`.
5. `v2.5.0` — Rajdhani small, `textSecondary`
6. `MechaButton(label: AppStrings.tapToStart, onTap: () => context.go('/login'))`
7. `Your cute AI companion awaits ✦` — caption

---

## Step 8 — Login (`/login`) & Signup (`/signup`) Screens

Files: `lib/features/auth/screens/login_screen.dart` / `signup_screen.dart`

Wrap `Scaffold` body in `SingleChildScrollView` → keyboard never covers inputs.

**Shared structure:**
- `MechaAppBar` with `< BACK` → `context.go('/')`
- Avatar (medium) + fallback
- Title + subtitle (Orbitron / Rajdhani)
- Tab row: LOG IN | SIGN UP pills (toggle via `setState` or navigate)
- `MechaTextField` × 2 (USERNAME, PASSWORD with eye toggle)

**Login buttons:**
1. `MechaButton(primary)` `LOG IN` → `context.go('/home')`
2. `— OR —`
3. `MechaButton(outlined)` `CREATE ACCOUNT` → `context.push('/signup')`
4. `Forgot password?` text (no action)

**Signup buttons:**
1. `MechaButton(primary)` `CREATE ACCOUNT` → `context.go('/home')`
2. `— OR —`
3. `MechaButton(outlined)` `BACK TO LOGIN` → `context.pop()`

---

## Step 9 — Home Screen (`/home`)

File: `lib/features/home/screens/home_screen.dart`

**Layout** (`Stack` → `GridBackground` + `Column`):
1. Top bar: `GOOD MORNING / COMMANDER ✦` + static signal/battery icons
2. Status chips row: ×3 `StatusChip` — `MORA ONLINE`, `HAPPY`, `98%`
3. Speech bubble (top-right aligned): `Container` with tail decoration, `Hiii~ I'm Mora!...`
4. Avatar — large, pink `BoxShadow` glow, `RepaintBoundary`, with fallback

   > **VRM Slot:** Wrap avatar in a named `Container(key: const ValueKey('avatar-slot'))`.
   > Later, replace `Image.asset` with a 3D widget here — no layout rework needed.

5. `— QUICK ACCESS —` label
6. Row of 3 `GlassmorphismButton` circles:
   - 💬 CHAT → `context.push('/chat')`
   - 🔔 REMIND → `context.push('/reminders')`
   - ⚙️ CONFIG → `context.push('/config')`

---

## Step 10 — Chat Screen (`/chat`)

File: `lib/features/chat/screens/chat_screen.dart`

**State:** `List<Message> _messages` — initialized with 4 hardcoded demo messages.

**Layout:**
1. `MechaAppBar` — left `< BACK`, right sakura SVG icon + `CHAT MODE`
2. `— TODAY —` centered label
3. `Expanded(child: ListView.builder(...))` — `_messages.isEmpty` shows `AppStrings.noChatYet` centered empty state
   - Mora bubble: left-aligned, `bgCard` + pink glow border, `MORA · timestamp`
   - User bubble: right-aligned, gray-purple translucent, `YOU · timestamp`
4. Bottom input row: `MechaTextField` + pink send `IconButton`
   - Tapping send appends a new `Message(isUser: true)` via `setState`

> Use `const` for static bubble sub-widgets where possible. `ListView.builder` is mandatory (not `Column`).

---

## Step 11 — Reminders Screen (`/reminders`)

File: `lib/features/reminders/screens/reminders_screen.dart`

**State:** `List<Task> _tasks` — 4 hardcoded tasks, 1 pre-done.

**Layout:**
1. `MechaAppBar` — `< BACK` + bell SVG + title + `X/Y DONE` badge
2. Pink `LinearProgressIndicator` (value: `done / total`)
3. `_tasks.isEmpty` → empty state: `AppStrings.noRemindersYet`
4. `ListView.builder` — each `Task` card:
   - `StatusChip(category)` with per-category color
   - Task title (strike-through if `isDone`)
   - Clock + time/frequency text
   - Circle checkbox (toggle `isDone` via `setState`)
   - Trash icon → `_tasks.removeAt(i)` + `setState`
5. FAB `+` (pink gradient circle) → `SnackBar("Add reminder — coming soon! 🔔")`

---

## Step 12 — Config Screen (`/config`)

File: `lib/features/config/screens/config_screen.dart`

**State:** `Map<String, bool> _toggles` + `double _masterVol`, `_effectVol`.

**Layout** (wrap body in `SingleChildScrollView`):
1. `MechaAppBar` — `< BACK` + `⚙ SYSTEM CONTROL`
2. Section `— AUDIO SYSTEMS —`
   - `MASTER VOLUME` pink `Slider`
   - `EFFECT VOLUME` pink `Slider`
3. Section `— VOICE SELECTION —`
   - `MORA'S VOICE` — `DropdownButton` (Voice A / Voice B)
4. Section `— SYSTEM CONTROLS —`
   
   Each row (`bgCard` card): SVG icon + title (Orbitron) + subtitle (Rajdhani) + pink `Switch`
   - DARK MODE | NOTIFICATIONS | MORA VOICE | HAPTIC FEEDBACK | PRIVACY SHIELD

5. `⚠ CAUTION · SESSION TERMINATE` — `textSecondary` centered
6. `MechaButton(primary)` `EXIT TO START` → `context.go('/')` (clears nav stack)

---

## Step 13 — Assets

1. `frontend/assets/avatar/mora_avatar.png` — placeholder (can be any pink moe PNG for now)
2. `frontend/assets/bg_grid.png` — 40×40px grid PNG, exported from Figma
3. `frontend/assets/icons/*.svg` — mecha icons (chat, bell, gear, moon, mic, shield, etc.) exported from Figma as SVG
4. `frontend/assets/fonts/*.ttf` — Orbitron-Bold, Rajdhani-Regular, Rajdhani-SemiBold

All declared in `pubspec.yaml` (see Step 1).

---

## Step 14 — Write `guidelines-front-end.md`

Write `frontend/guidelines-front-end.md` after all screens are done:
- Full folder structure diagram
- Design token references (colors, spacing, radius, strings)
- Rule: no hardcoded colors / text
- How to add a new screen (router + feature folder pattern)
- How to swap avatar asset (just replace `assets/avatar/mora_avatar.png`)
- How to add real state management (Riverpod — install, wrap `ProviderScope` in `main.dart`)
- **VRM integration guide:** use the `avatar-slot` Container key; replace `Image.asset` with a `WebViewWidget` running Three.js + `@pixiv/three-vrm`, or use `flutter_3d_controller` package once models are ready

---

## Step 15 — Push to GitHub

```bash
git add .
git commit -m "feat(frontend): implement Bubble Mecha Pink UI — all 6 screens (UI-only, no animation/voice)"
git push origin main
```

---

## Verification Checklist

- [ ] `flutter pub get` — exits code 0
- [ ] `flutter analyze` — 0 errors, `const` used wherever possible
- [ ] All 6 routes navigable without crash
- [ ] Keyboard does not cover inputs on Login / Chat / Config
- [ ] Grid background is tiled PNG (not CustomPainter)
- [ ] Empty states shown in Chat and Reminders when lists are empty
- [ ] All text from `AppStrings`, all colors from `AppColors`
- [ ] No backend calls made (UI-only)
- [ ] All screens match Bubble Mecha Pink visual reference images