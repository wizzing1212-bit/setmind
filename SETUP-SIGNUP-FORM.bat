@echo off
setlocal
title SET MIND - switch on tester signups
cd /d "%~dp0"
echo.
echo   SET MIND - tester signup form
echo   ------------------------------
echo.
echo   1. A browser will open formspree.io
echo   2. Sign up (free), create a form called "SET MIND testers"
echo   3. Copy the endpoint it gives you - it looks like:
echo        https://formspree.io/f/abcdwxyz
echo.
start "" "https://formspree.io/register"
echo.
set /p EP=  Paste it here and press Enter: 
if "%EP%"=="" (echo   Nothing pasted. Run me again. & pause & exit /b 1)
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$p='%~dp0index.html'; $t=Get-Content $p -Raw; $t=$t -replace 'const FORM_ENDPOINT = \"[^\"]*\";', ('const FORM_ENDPOINT = \"%EP%\";'); Set-Content $p $t -Encoding UTF8"
git add index.html >nul 2>&1
git -c user.email="wizzing1212@gmail.com" -c user.name="SET MIND" commit -m "signup form on" >nul 2>&1
git push >nul 2>&1
echo.
echo   Done. Signups now email you at wizzing1212@gmail.com.
echo   Live on the site in about a minute.
echo.
pause
