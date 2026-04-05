# 🤖 Project: Mora-Like AI Virtual Companion
**Context:** School Project (2026)
**Inspiration:** "Mora" by RedMagic

## 📖 1. Project Overview
We are building a highly interactive, personalized AI Virtual Companion. 
While the original RedMagic "Mora" is praised for its gaming flair and mecha aesthetics, critics note it leans heavily on entertainment rather than deep practicality (mostly offering basic animations and static alerts). 

**Our Goal:** To solve Mora's limitations by blending its engaging 2D avatar and Mecha UI with a **real AI brain** (Google Gemini). Our app will not only look cool but will feature contextual assistance, actual conversational memory, active schedule reminders, and a customizable avatar.

## 🧑‍💻 2. Team Workflow & Responsibilities
This is a collaborative Monorepo. We divide the work so we don't block each other:

*   **[Your Name] (Base & Systems Engineer):**
    *   Sets up the Monorepo architecture.
    *   Develops the Node.js Backend (APIs, Database, Socket.IO, Cron Jobs).
    *   Builds the core Flutter logic (State management, API calls, TTS/STT).
    *   Integrates Google Gemini API.
*   **[Friend's Name] (Avatar & UI/UX Designer):**
    *   Designs the Mecha-style UI (Neon, Cyberpunk, Glowing borders).
    *   Draws and exports the 2D Avatar layers (Base body, Hair, Eyes, Outfits as transparent PNGs).
    *   Handles UI animations and styling in Flutter once the base logic is ready.

## 🛠️ 3. Tech Stack
*   **Frontend:** Flutter (Dart)
    *   Packages: `http`, `shared_preferences`, `socket_io_client`, `flutter_tts`, `speech_to_text`, `flutter_local_notifications`.
*   **Backend:** Node.js + Express.js
    *   Packages: `mongoose`, `cors`, `dotenv`, `socket.io`, `jsonwebtoken`, `bcrypt`, `@google/generative-ai`, `node-cron`.
*   **Database:** MongoDB Atlas (Distributed Cloud Cluster - meets school requirements).
*   **AI Engine:** Google Gemini API (Free Tier).

## 🧩 4. Core Features & Architecture
1.  **Auth System:** JWT-based login so users can save their chats, schedules, and avatar outfits.
2.  **Real-Time AI Chat:** Powered by Socket.IO and Gemini. The AI has a "system prompt" to act like a Mecha anime assistant.
3.  **Voice Interaction:** User speaks -> STT -> Gemini -> TTS -> AI speaks back.
4.  **Proactive Reminders:** 
    *   *Backend:* `node-cron` checks MongoDB for schedules and emits Socket events.
    *   *Frontend:* Tracks screen time and shows Mecha-styled popup warnings if the user is on the app too long.
5.  **Dynamic Avatar:** A Flutter `Stack` widget that overlays PNG layers based on the user's saved DB preferences.

> **REST API MANDATE:** Even if a feature uses WebSockets for real-time updates, all CRUD operations MUST ALSO have standard HTTP REST endpoints exposed in the `backend/src/routes/` folder so they can be tested via Postman.

## 📂 5. Monorepo Structure
We are using a simple Monorepo structure to keep everything in one place.

\`\`\`text
mora-ai-project/
├── .git/
├── guidelines.md          <-- You are reading this
├── backend/               <-- Node.js workspace
│   ├── src/
│   ├── package.json
│   └── .env               <-- NEVER COMMIT THIS (Contains Gemini API Key & DB URI)
└── frontend/              <-- Flutter workspace
    ├── lib/
    ├── assets/
    │   └── avatar/        <-- Friend drops PNG layers here
    └── pubspec.yaml
\`\`\`

## 💻 6. Important Commands

**For Git (Collaborating):**
*   `git pull origin main` (Always run this before you start coding for the day to get your friend's updates!)
*   `git add .`
*   `git commit -m "feat: description of what you did"`
*   `git push origin main`

**For Backend (Node.js):**
*   `cd backend`
*   `npm install` (First time setup)
*   `npm run dev` (Runs server with nodemon for auto-reloading)

**For Frontend (Flutter):**
*   `cd frontend`
*   `flutter pub get` (First time setup/adding packages)
*   `flutter run` (Starts the app on emulator/device)

## 🚀 7. Next Immediate Steps (Phase 1)
1. Initialize this Git Monorepo and invite team members.
2. Setup MongoDB Atlas and get the connection string.
3. Get a Google Gemini API Key.
4. Build the `User` schema and Auth APIs in Node.js.