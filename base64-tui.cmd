@echo off
title CAMBRIANSYSTEMS // BASE64 TRANSMUTATION CONSOLE
mode con: cols=90 lines=34
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0base64-tui.ps1"
