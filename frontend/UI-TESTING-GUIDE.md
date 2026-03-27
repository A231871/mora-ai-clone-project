# 🧪 Mora AI — UI Testing Guide

> **Goal:** Get the Flutter frontend running locally and test all 6 screens.
> **Time:** ~10 minutes (first time), ~1 minute (subsequent runs)

---

## ⚡ Prerequisites

Before you start, make sure these are installed:

| Tool | Check version | Download |
|---|---|---|
| Flutter SDK | `flutter --version` | https://docs.flutter.dev/get-started/install |
| Dart SDK | (bundled with Flutter) | — |
| Android Studio **or** Chrome | `flutter devices` | https://developer.android.com/studio |
| Git | `git --version` | https://git-scm.com |

> [!IMPORTANT]
> Your installed Flutter uses **Dart 3.5.4** — make sure you are on the correct branch:
> ```
> git checkout feature/UI
> ```

---

## 🚀 Step 1 — Add Required Assets (First Time Only)

The app needs 3 font files and 1 avatar image to look correct.
**Without them the app still runs** — fallback icons and system fonts are used.

### 1A. Download Fonts (Google Fonts)

1. Go to https://fonts.google.com/specimen/Orbitron → click **Download family**
2. Go to https://fonts.google.com/specimen/Rajdhani → click **Download family**
3. Copy the following files into `frontend/assets/fonts/`:

```
frontend/assets/fonts/
├── Orbitron-Bold.ttf           ← from Orbitron download
├── Rajdhani-Regular.ttf        ← from Rajdhani download
└── Rajdhani-SemiBold.ttf       ← from Rajdhani download
```

### 1B. Add Avatar Placeholder

Copy any PNG image (your Mora character or any placeholder) into:

```
frontend/assets/avatar/mora_avatar.png
```

> [!TIP]
> No avatar yet? The app shows a 🌸 fallback icon instead — still functional.

---

## 📦 Step 2 — Install Dependencies

Open a terminal in the **frontend** folder:

```bash
cd e:\mora-ai-clone-project\frontend
flutter pub get
```

Expected output:
```
Resolving dependencies...
Changed X dependencies!
```

---

## 📱 Step 3 — Choose Your Test Target

Run this to see available devices:

```bash
flutter devices
```

You'll see something like:

```
Android SDK built for x86 (emulator) • emulator-5554  • android-x86
Windows (desktop)                    • windows        • windows
Chrome (web)                         • chrome         • web-javascript
```

> [!TIP]
> **Fastest option: Chrome** — no emulator setup needed.
> **Best visual result: Android emulator** — most accurate to the Figma design.

---

## ▶️ Step 4 — Run the App

### Option A — Chrome (Fastest)
```bash
flutter run -d chrome
```

### Option B — Android Emulator
```bash
# First start an emulator in Android Studio, then:
flutter run -d emulator-5554
```

### Option C — Windows Desktop
```bash
flutter run -d windows
```

> [!NOTE]
> First build takes 30–60 seconds. Subsequent hot reloads are instant (`r` key).

---

## 🗺️ Step 5 — Navigate All 6 Screens

Once the app launches, test every screen using this flow:

### Screen Flow Map
```
[START] → TAP TO START → [LOGIN] → LOG IN button → [HOME]
                       ↕
               CREATE ACCOUNT → [SIGNUP]

[HOME] → 💬 Chat button     → [CHAT]
       → 🔔 Remind button   → [REMINDERS]
       → ⚙️ Config button   → [CONFIG] → EXIT TO START → [START]
```

### ✅ Checklist Per Screen

#### 🟣 `Start Screen` (`/`)
- [ ] MORA title appears with pink glow
- [ ] "SYSTEM ONLINE" green chip visible
- [ ] "VIRTUAL ASSISTANT" subtitle visible
- [ ] Avatar slot visible (image or fallback icon)
- [ ] **TAP TO START** button navigates to Login

#### 🔐 `Login Screen` (`/login`)
- [ ] LOG IN / SIGN UP tab selector works (tap SIGN UP → goes to Signup)
- [ ] Username and Password fields accept text
- [ ] Password field has 👁 eye toggle (show/hide)
- [ ] **LOG IN** button navigates to Home (no auth check — UI only)
- [ ] **CREATE ACCOUNT** button goes to Signup
- [ ] `< BACK` button returns to Start

#### 📝 `Signup Screen` (`/signup`)
- [ ] SIGN UP tab is active (pink gradient)
- [ ] Form fields work
- [ ] **CREATE ACCOUNT** button goes to Home
- [ ] **BACK TO LOGIN** button goes back

#### 🏠 `Home Screen` (`/home`)
- [ ] "MORA ONLINE" + "MOOD: HAPPY" + "⚡ 98%" chips visible
- [ ] Speech bubble shows Mora's greeting
- [ ] Avatar (or fallback) centered with pink glow
- [ ] 💬 **Chat** → goes to Chat screen
- [ ] 🔔 **Remind** → goes to Reminders screen
- [ ] ⚙️ **Config** → goes to Config screen

#### 💬 `Chat Screen` (`/chat`)
- [ ] 5 pre-loaded demo messages visible (alternating Mora / You)
- [ ] Mora messages: pink border, flower icon
- [ ] Your messages: white bubble, right-aligned
- [ ] Type in the input bar → tap send or press Enter → new message appears
- [ ] List scrolls to bottom on new message
- [ ] `< BACK` (top-left) returns to Home

#### 📋 `Reminders Screen` (`/reminders`)
- [ ] Progress bar shows 1/4 complete (1 task pre-checked)
- [ ] 4 tasks visible with correct category chips (WORK / HEALTH / MORA / SOCIAL)
- [ ] Tap ○ circle → task checks off ✅ (strikethrough text, glow)
- [ ] Tap ○ again → unchecks
- [ ] Tap 🗑 delete → task removed, progress bar updates
- [ ] FAB `+` button → snackbar "Add reminder" appears
- [ ] `< BACK` returns to Home

#### ⚙️ `Config Screen` (`/config`)
- [ ] MASTER VOLUME slider is draggable
- [ ] EFFECT VOLUME slider is draggable
- [ ] MORA'S VOICE dropdown opens (Voice A / Voice B)
- [ ] 5 switches toggle on/off (DARK MODE, NOTIFICATIONS, etc.)
- [ ] **EXIT TO START** button navigates back to Start screen
- [ ] `< BACK` returns to Home

---

## 🔥 Step 6 — Hot Reload (Development Loop)

While the app is running in terminal, use these keys:

| Key | Action |
|---|---|
| `r` | **Hot reload** — update UI instantly (keeps state) |
| `R` | **Hot restart** — full restart (resets state) |
| `q` | **Quit** the app |
| `h` | Show all available commands |

> [!TIP]
> Change any color in `AppColors` → press `r` → see it change live!

---

## 🐛 Common Issues & Fixes

| Problem | Cause | Fix |
|---|---|---|
| `No devices found` | No emulator running | Run Chrome: `flutter run -d chrome` |
| Fonts look wrong (no Orbitron) | Font files missing | Add `.ttf` files to `assets/fonts/` |
| `flutter pub get` fails | SDK version mismatch | Check `pubspec.yaml` has `sdk: ^3.5.4` |
| Avatar is a flower icon | PNG missing | Add `mora_avatar.png` to `assets/avatar/` |
| Background grid not visible | `bg_grid.png` is placeholder | Replace with a real 40×40px grid PNG |
| Keyboard overlaps input (Login/Chat) | Scroll not working | Wrap in `SingleChildScrollView` ✅ already done |
| `Developer Mode` warning | Windows symlinks | Enable in Settings → Developers (optional) |

---

## 📊 What Is and Isn't Tested

| Feature | Status |
|---|---|
| Screen navigation (all routes) | ✅ Works |
| Chat message sending | ✅ Works (local state only) |
| Reminder toggle / delete | ✅ Works (local state only) |
| Config sliders & switches | ✅ Works (local state only) |
| Login validation | ❌ None — UI only, any input works |
| Real backend API calls | ❌ None — no network requests |
| Mora voice / animation | ❌ Not implemented yet |
| VRM 3D model | ❌ Slot reserved, not integrated yet |

---

## 🔗 Quick Reference

```bash
# Install packages
cd e:\mora-ai-clone-project\frontend && flutter pub get

# Run on Chrome (fastest)
flutter run -d chrome

# Run on Android emulator
flutter run -d emulator-5554

# Check for errors
flutter analyze

# See all connected devices
flutter devices
```

---

*After testing, continue with:*
1. 🎨 **Font assets** — replace fallback fonts with real Orbitron/Rajdhani TTFs
2. 🖼 **Avatar** — drop your `mora_avatar.png` into `assets/avatar/`
3. 🎯 **Next phase** — connect backend API (`/login`, `/chat`) and add Riverpod state
