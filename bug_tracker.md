# E2E Bug & Feature Backlog

## 1. Auth Flow (Login & Register)
- [x] **Bug**: Routing is broken. If a user navigates to the Register screen, the 'Back to Login' button doesn't work, and they are trapped.
- [x] **Feature**: Add a 'Confirm Password' text field to the Register screen.
- [x] **Feature**: Add regex password validation (e.g., must contain uppercase, lowercase, number, special char like Password@123).
- [x] **Feature**: 'Forgot Password' / Google path — user can sign in with Google (`POST /api/auth/google`, `google_sign_in` + ID token). Configure `GOOGLE_CLIENT_ID` (backend `.env`) and build the app with `--dart-define=GOOGLE_SERVER_CLIENT_ID=<Web client ID>` (see `backend/.env.example`).
- [x] **Feature**: Implement OAuth / Login via Google feature (backend JWT after Google ID token verification; optional `googleId` on user).

## 2. Main Screen (Mascot & Data)
- [x] **Bug**: The Shizuki model does not render properly/at all.
- [x] **UI Tweak**: Scale the model up (it is currently too small).
- [x] **Bug**: The UI statuses are using mock/fake data instead of real state.
- [x] **Bug**: The displayed time is incorrect. Sync it to `DateTime.now()` (device's local timezone).

## [DEFERRED] Mascot Rendering
- [ ] **Bug**: Model physics are broken (she floats statically instead of idling/breathing).
  - *Note: Will be handled manually by a human animator later using proper Live2D/Spine tools.*
  - *Rigged source assets live under `frontend/assets/` (e.g. `Shizuke_App_Model/`). When an export format is chosen, register assets in `pubspec.yaml` (comment placeholder added there).*

## 3. Reminder Screen (Tasks & Notifications)
- [x] **Bug**: CRUD operations are broken. Crossing out tasks works visually, but creating new tasks fails, and deleting tasks does not persist to the database.
- [x] **Feature**: Sync reminders to the device's local time.
- [x] **Feature**: Background Notifications. Implement local push notifications so the app alerts the user even when closed (requires OS permissions).
- [x] **Feature** (Phase 2): Add a 'Delete All' button to clear all tasks.
- [x] **Feature** (Phase 2): Add an 'Edit' button/flow to modify existing reminders.
- [x] **Feature** (Phase 2): Add recurring scheduling (allow users to select specific days of the week like Monday, Tuesday, etc., for a reminder to repeat).
- [x] **Bug**: Reminders UI STILL does not update in real-time. Requires a screen refresh to show new/edited/deleted tasks.
- [x] **Logic Tweak**: Recurring tasks should NOT auto-complete.
- [x] **Feature**: Add a 'Complete All' button.

## 4. Config Screen
- [x] **Bug**: Volume sliders are fake.
- [x] **Feature**: Add an audio feedback callback (play a short test sound when the user adjusts the Master or Voice sliders).
- [x] **Feature**: Add a confirmation Dialog pop-up when tapping 'EXIT TO START' to prevent accidental logouts.

## 5. Chat & AI Identity
- [x] **Bug**: The AI is referring to itself as 'Mora' instead of 'Shizuki'. Update her system prompt/identity variables in the backend/services.
- [x] **Bug**: The microphone STT feature is failing to prompt the user for native OS permissions before activating.
- [x] **Bug** (Phase 2): State Disposal Issue — fixed by awaiting `ChatService.connect()` after attaching stream listeners, then calling `fetchHistory()` (`chat_screen.dart`, `chat_service.dart`). Reminders screen also awaits connect before `fetchPendingReminders()`.

## 6. Localization (i18n)
- [x] **Feature**: App-wide localization (EN default, VI switch in Config) via `AppLocalizations` + `languageProvider` + ARB files; remaining hardcoded strings moved into ARB where applicable.
- [x] **Feature**: Selected language is passed to the AI backend on `chat:send` as `lang`, and to on-device TTS/STT via `VoiceService` (`socket.js` → `ai.service.js`, `voice_service.dart`).
