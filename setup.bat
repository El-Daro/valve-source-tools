@echo off
setlocal

powershell -ExecutionPolicy Bypass -File "%~dp0Install-ValveSourceTools.ps1"

pause