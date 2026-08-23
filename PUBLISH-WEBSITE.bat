@echo off
setlocal enabledelayedexpansion
title SET MIND - publish website
cd /d "%~dp0"
set LOG=%~dp0publish-log.txt
echo ==== %DATE% %TIME% ==== > "%LOG%"

echo.
echo   SET MIND - publishing your website
echo   ----------------------------------
echo.

:: --- git present? ---
where git >nul 2>&1
if errorlevel 1 (
  echo   Git is not installed. Installing...
  winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements >> "%LOG%" 2>&1
  set "PATH=%PATH%;%ProgramFiles%\Git\cmd"
  where git >nul 2>&1 || (echo   Git install failed. See publish-log.txt & pause & exit /b 1)
)

:: --- gh present? ---
where gh >nul 2>&1
if errorlevel 1 (
  echo   Installing GitHub tool...
  winget install --id GitHub.cli -e --source winget --accept-package-agreements --accept-source-agreements >> "%LOG%" 2>&1
  set "PATH=%PATH%;%ProgramFiles%\GitHub CLI"
  where gh >nul 2>&1 || (echo   GitHub tool install failed. See publish-log.txt & pause & exit /b 1)
)

:: --- logged in? ---
gh auth status >> "%LOG%" 2>&1
if errorlevel 1 (
  echo.
  echo   A browser will open. Log into GitHub, then come back here.
  echo.
  gh auth login --web -h github.com -s repo,workflow
  gh auth status >nul 2>&1 || (echo   Login failed. Run me again. & pause & exit /b 1)
)

for /f "delims=" %%u in ('gh api user --jq .login 2^>nul') do set USER=%%u
if "%USER%"=="" (echo   Could not read your GitHub username. See publish-log.txt & pause & exit /b 1)

:: --- git repo ---
if not exist ".git" (
  git init -b main >> "%LOG%" 2>&1
)
git add -A >> "%LOG%" 2>&1
git -c user.email="wizzing1212@gmail.com" -c user.name="SET MIND" commit -m "website" >> "%LOG%" 2>&1

:: --- create or push ---
gh repo view %USER%/setmind >nul 2>&1
if errorlevel 1 (
  echo   Creating the repo...
  gh repo create setmind --public --source=. --remote=origin --push >> "%LOG%" 2>&1
) else (
  git remote add origin https://github.com/%USER%/setmind.git >> "%LOG%" 2>&1
  git branch -M main >> "%LOG%" 2>&1
  git push -u origin main --force >> "%LOG%" 2>&1
)

:: --- turn on Pages ---
echo   Turning on hosting...
gh api -X POST repos/%USER%/setmind/pages -f "source[branch]=main" -f "source[path]=/" >> "%LOG%" 2>&1
if errorlevel 1 gh api -X PUT repos/%USER%/setmind/pages -f "source[branch]=main" -f "source[path]=/" >> "%LOG%" 2>&1

echo.
echo   ==================================================
echo     Your website:
echo     https://setmind.net   (once DNS points here)
echo     https://%USER%.github.io/setmind/
echo.
echo     Give it 1-2 minutes to go live after a change.
echo   ==================================================
echo.
start "" "https://%USER%.github.io/setmind/"
pause
