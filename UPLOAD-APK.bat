@echo off
title SET MIND - upload an APK
cd /d "%~dp0"
echo.
echo   SET MIND - putting an APK on your website
echo   -----------------------------------------
echo.
echo   (Tip: you can drag an .apk file straight onto this .bat)
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0upload-apk.ps1" %1
echo.
pause
