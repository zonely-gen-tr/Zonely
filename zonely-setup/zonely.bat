@echo off
setlocal
title Zonely
set "SCRIPT_DIR=%~dp0"
set "PS1=%SCRIPT_DIR%zonely.ps1"

REM If launched inside Windows Terminal, re-open in classic CMD for reliable sizing
if defined WT_SESSION (
  start "" /max cmd.exe /c "\"%~f0\" %*"
  exit /b
)

mode con: cols=160 lines=45 >nul 2>nul
powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Normal -File "%PS1%" %*
if errorlevel 1 pause
endlocal
