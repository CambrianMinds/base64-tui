@echo off
chcp 65001 >nul
title CAMBRIANSYSTEMS // DATA TRANSMUTATION CONSOLE
mode con: cols=90 lines=34
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0cambriansystems-tui.ps1" %*
