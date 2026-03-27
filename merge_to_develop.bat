@echo off
setlocal enabledelayedexpansion

echo ================================================
echo  MERGING ALL FEATURE BRANCHES INTO DEVELOP
echo ================================================

cd /d e:\mora-ai-clone-project

echo [1/7] Fetching all remote branches...
git fetch --all
if %errorlevel% neq 0 (echo FETCH FAILED && exit /b 1)

echo [2/7] Checking out origin/develop as local develop...
git checkout -B develop origin/develop
if %errorlevel% neq 0 (echo CHECKOUT FAILED && exit /b 1)

echo --- Current develop log ---
git log --oneline -5

echo.
echo ================================================
echo MERGING feature/UI (Flutter full UI design system)
echo ================================================
git merge origin/feature/UI --no-edit -m "Merge feature/UI: Bubble Mecha Pink design system, shared widgets, 6 screens, router"
if %errorlevel% neq 0 (
    echo Conflicts detected in feature/UI - resolving...
    git checkout --theirs -- frontend/
    git add frontend/
    git merge --continue --no-edit
)

echo.
echo ================================================
echo MERGING feature/UI-screens (UI screen implementations)
echo ================================================
git merge origin/feature/UI-screens --no-edit -m "Merge feature/UI-screens: all 6 screens fully implemented"
if %errorlevel% neq 0 (
    echo Conflicts detected in feature/UI-screens - resolving...
    git checkout --theirs -- frontend/
    git add frontend/
    git merge --continue --no-edit
)

echo.
echo ================================================
echo MERGING feature/UI-avatar (Shizuki avatar sprites)
echo ================================================
git merge origin/feature/UI-avatar --no-edit -m "Merge feature/UI-avatar: Shizuki animator widget + 6 transparent PNG sprites"
if %errorlevel% neq 0 (
    echo Conflicts detected in feature/UI-avatar - resolving...
    git checkout --theirs -- frontend/assets/avatar/ frontend/lib/shared/widgets/shizuki_animator.dart
    git add frontend/
    git merge --continue --no-edit
)

echo.
echo ================================================
echo MERGING feat/voice-and-cron-reminder-and-avatar-states-and-timezone-sync
echo ================================================
git merge origin/feat/voice-and-cron-reminder-and-avatar-states-and-timezone-sync --no-edit -m "Merge feat/voice-cron-reminder-avatar-timezone: backend voice, cron, timezone sync"
if %errorlevel% neq 0 (
    echo Conflicts detected - resolving by keeping backend changes for backend, frontend for frontend...
    REM For backend files keep theirs (backend branch), for frontend keep ours
    git checkout --theirs -- backend/ 2>nul
    git checkout --ours -- frontend/ 2>nul
    git add .
    git merge --continue --no-edit
)

echo.
echo ================================================
echo PUSHING merged develop to origin...
echo ================================================
git push origin develop
if %errorlevel% neq 0 (echo PUSH FAILED && exit /b 1)

echo.
echo ================================================
echo Final develop log:
echo ================================================
git log --oneline -12

echo.
echo ================================================
echo ALL DONE - develop is now up to date!
echo ================================================
