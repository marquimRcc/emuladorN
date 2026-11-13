@echo off
setlocal
title Configurar Memoria Virtual (Pagefile 16-32GB no D:)

:: Verifica privilegios de Administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Solicitando elevacao de Administrador...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0configurar_pagefile_d.ps1"
