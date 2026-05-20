@echo off
cd /d C:\Microtik
powershell -ExecutionPolicy Bypass -File "C:\Microtik\generate-config.ps1"
pause
