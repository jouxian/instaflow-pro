@echo off
chcp 65001 >nul
echo Updating InstaFlow runtime tools from their release sources...
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Ensure_Tools.ps1" -ForceUpdate
if errorlevel 1 (
  echo.
  echo One or more required tools could not be updated.
) else (
  echo.
  echo Runtime tools updated successfully.
)
pause
