# 📱 Mora AI Frontend — Guidelines

> **Stack:** Flutter (Dart) · go_router · flutter_svg · Bubble Mecha Pink design
> **Status:** UI-only — no animation, no voice, no backend calls yet.

---

## 1. Folder Structure

```
frontend/lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart       ← All hex color tokens
│   │   ├── app_spacing.dart      ← AppSpacing + AppRadius
│   │   └── app_strings.dart      ← All UI text strings
│   ├── theme/
│   │   ├── app_theme.dart        ← MaterialTheme (dark, mecha)
│   │   └── app_text_styles.dart  ← Orbitron + Rajdhani styles
│   └── router/
│       └── app_router.dart       ← go_router, 7 routes, fade transitions
├── shared/
│   └── widgets/
│       ├── grid_background.dart      ← Tiled PNG grid (RepaintBoundary)
│       ├── mecha_button.dart         ← Primary & outlined pill button
│       ├── glassmorphism_button.dart ← Blur circle icon button (Home nav)
│       ├── mecha_text_field.dart     ← Neon-border input + eye toggle
│       ├── status_chip.dart          ← Pill badge (status/category)
│       └── mecha_app_bar.dart        ← Reusable transparent app bar
└── features/
    ├── splash/screens/start_screen.dart
    ├── auth/screens/
    │   ├── login_screen.dart
    │   └── signup_screen.dart
    ├── home/screens/home_screen.dart
    ├── chat/
    │   ├── models/message.dart
    │   └── screens/chat_screen.dart
    ├── reminders/
    │   ├── models/task.dart
    │   └── screens/reminders_screen.dart
    └── config/screens/config_screen.dart

frontend/assets/
├── avatar/          ← Drop mora_avatar.png (or .vrm slot) here
├── icons/           ← SVG mecha icons from Figma
├── fonts/           ← Orbitron-Bold.ttf, Rajdhani-Regular.ttf, Rajdhani-SemiBold.ttf
└── bg_grid.png      ← 40×40px tiled grid exported from Figma
```

---

## 2. Design Rules

| Rule | Detail |
|---|---|
| ❌ No hardcoded colors | Always use `AppColors.*` |
| ❌ No hardcoded strings | Always use `AppStrings.*` |
| ❌ No hardcoded spacing | Always use `AppSpacing.*` / `AppRadius.*` |
| ✅ Reusable widgets | `MechaButton`, `MechaTextField`, `StatusChip`, `MechaAppBar`, `GlassmorphismButton` |
| ✅ const everywhere | Use `const` constructor whenever possible |
| ✅ Long lists | Always `ListView.builder`, never `Column` of fixed children |
| ✅ Avatar wrapped | Always inside `RepaintBoundary` + `ValueKey('avatar-slot')` |

---

## 3. Color Palette (Bubble Mecha Pink)

| Token | Hex | Usage |
|---|---|---|
| `bgDeep` | `#130822` | Page backgrounds |
| `bgCard` | `#1E0F35` | Cards, inputs |
| `primary` | `#FF3CAC` | Buttons, borders, glow |
| `primaryDark` | `#C0006A` | Pressed / inactive |
| `accent` | `#7B2FBE` | Purple secondary |
| `textPrimary` | `#FFFFFF` | Main text |
| `textSecondary` | `#D08ACA` | Labels, hints |
| `statusGreen` | `#39FF14` | MORA ONLINE |

---

## 4. Navigation (go_router)

| Route | Screen | Navigate with |
|---|---|---|
| `/` | StartScreen | `context.go('/')` |
| `/login` | LoginScreen | `context.go('/login')` |
| `/signup` | SignupScreen | `context.push('/signup')` |
| `/home` | HomeScreen | `context.go('/home')` |
| `/chat` | ChatScreen | `context.push('/chat')` |
| `/reminders` | RemindersScreen | `context.push('/reminders')` |
| `/config` | ConfigScreen | `context.push('/config')` |

- Use `context.go()` for root navigation (clears stack, e.g. after login)
- Use `context.push()` for sub-screens (keeps back button)
- Use `context.pop()` for `< BACK` buttons in `MechaAppBar`

All routes use a 350ms **FadeTransition** (`CustomTransitionPage`).

---

## 5. Typography

| Style | Font | Weight | Size | Use |
|---|---|---|---|---|
| `displayLarge` | Orbitron | 700 | 42 | `MORA` title |
| `displayMedium` | Orbitron | 700 | 28 | Screen headings |
| `titleLarge` | Orbitron | 700 | 18 | AppBar, section titles |
| `bodyLarge` | Rajdhani | 600 | 16 | Chat messages |
| `bodyMedium` | Rajdhani | 600 | 14 | General body text |
| `bodySmall` | Rajdhani | 400 | 12 | Hints, timestamps |
| `buttonLabel` | Orbitron | 700 | 14 | Button labels |

---

## 6. How to Add a New Screen

1. Create `lib/features/<feature>/screens/<name>_screen.dart`
2. Add a `GoRoute` in `lib/core/router/app_router.dart`
3. Use `GridBackground` as first child of `Stack`
4. Use `MechaAppBar` for title + back button
5. Wrap body with `SingleChildScrollView` if it has inputs
6. All colors → `AppColors`, all strings → `AppStrings`

---

## 7. How to Replace the Avatar

Replace `assets/avatar/mora_avatar.png` with your actual asset:

```bash
# Drop your file here:
frontend/assets/avatar/mora_avatar.png
```

Every screen uses:
```dart
Container(key: const ValueKey('avatar-slot'), ...)
  └── Image.asset('assets/avatar/mora_avatar.png', errorBuilder: ...)
```

The `errorBuilder` shows a fallback icon if the file is missing — no crashes.

---

## 8. VRM Model Integration Guide

When you're ready to integrate the `.vrm` 3D model:

### Option A — WebView + Three.js (Recommended for mobile)
1. Add `webview_flutter` package
2. Create an HTML page locally that loads `@pixiv/three-vrm`
3. Replace `Image.asset(...)` inside the `ValueKey('avatar-slot')` Container with a `WebViewWidget`

### Option B — `flutter_3d_controller` package
1. Add `flutter_3d_controller: ^1.4.0` to `pubspec.yaml`
2. Convert `.vrm` → `.glb` using online converter (VRM models are GLB-based)
3. Drop the file in `assets/avatar/mora.glb`
4. Replace `Image.asset(...)` with:
   ```dart
   Flutter3DViewer(src: 'assets/avatar/mora.glb')
   ```

> ✦ The `ValueKey('avatar-slot')` Container already exists on every screen — swap only the inner widget, no layout changes needed.

---

## 9. Adding State Management (Riverpod — Future Phase)

When ready to connect to backend or add real state:

1. Add `flutter_riverpod: ^2.5.1` to `pubspec.yaml`
2. Wrap `MoraAiApp` in `ProviderScope` in `main.dart`:
   ```dart
   runApp(const ProviderScope(child: MoraAiApp()));
   ```
3. Convert `_messages` and `_tasks` lists to `StateNotifierProvider`
4. Replace `setState(...)` calls with notifier methods

---

## 10. Setup Commands

```bash
# Install dependencies
cd frontend
flutter pub get

# Add font files (download from Google Fonts)
# → Orbitron-Bold.ttf       → frontend/assets/fonts/
# → Rajdhani-Regular.ttf    → frontend/assets/fonts/
# → Rajdhani-SemiBold.ttf   → frontend/assets/fonts/

# Add avatar placeholder
# → mora_avatar.png          → frontend/assets/avatar/

# Add grid background
# → bg_grid.png (40×40px)   → frontend/assets/

# Run the app
flutter run

# Check for errors
flutter analyze
```
