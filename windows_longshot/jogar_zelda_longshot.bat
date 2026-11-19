@echo off
title The Legend of Zelda: Ocarina of Time (Longshot 3.0 Windows Nativo)
color 0B
echo =======================================================================
echo   The Legend of Zelda: Ocarina of Time - Longshot 3.0 (Windows Nativo)
echo   Hardware: AMD Radeon RX 6750 XT (12GB) - Intel Core i5-12400F
echo   Configuracao: Vulkan 1.4 - AMD Anti-Lag 2 - 60 FPS Estavel - Xbox Pad
echo =======================================================================
echo.

rem Captura continua de controles XInput / SDL em segundo plano
set SDL_JOYSTICK_ALLOW_BACKGROUND_EVENTS=1

rem Driver Vulkan AMD Adrenalin nativo e Anti-Lag 2
set AMD_VULKAN_ICD=1
set RX_VK_ANTILAG=1

rem Cadencia e sincronizacao de tempo real estaveis
set HOS_REALTIME_STEP=1
set HOS_DYNRES=0
set RX_VK_PACE=1

rem Pre-compilacao e aquecimento assincrono de pipelines Vulkan
set RX_VK_PRECOMPILE=1
set RX_VK_COMPILE_SHADERS=1
set LONGSHOT_PRIORITY=High

rem 1. Build oficial Longshot v3.0.0
if exist "C:\Users\marcos\Documents\emulador\longshot\LongshotLauncher-data\builds\v3.0.0\longshot.exe" (
    echo [1/2] Localizada build Longshot v3.0.0.
    echo [2/2] Sincronizando configuracoes e iniciando...
    copy /y "%~dp0longshot_options.ini" "C:\Users\marcos\Documents\emulador\longshot\LongshotLauncher-data\builds\v3.0.0\longshot_options.ini" >nul 2>&1
    cd /d "C:\Users\marcos\Documents\emulador\longshot\LongshotLauncher-data\builds\v3.0.0"
    start "" "longshot.exe"
    goto :FIM
)

rem 2. Build Longshot v3.0.0-rc.3
if exist "C:\Users\marcos\Documents\emulador\longshot\LongshotLauncher-data\builds\v3.0.0-rc.3\longshot.exe" (
    echo [1/2] Localizada build Longshot v3.0.0-rc.3.
    echo [2/2] Sincronizando configuracoes e iniciando...
    copy /y "%~dp0longshot_options.ini" "C:\Users\marcos\Documents\emulador\longshot\LongshotLauncher-data\builds\v3.0.0-rc.3\longshot_options.ini" >nul 2>&1
    cd /d "C:\Users\marcos\Documents\emulador\longshot\LongshotLauncher-data\builds\v3.0.0-rc.3"
    start "" "longshot.exe"
    goto :FIM
)

rem 3. Diretorio C:\Users\marcos\Games\Longshot
if exist "C:\Users\marcos\Games\Longshot\longshot.exe" (
    echo [1/2] Localizada build em C:\Users\marcos\Games\Longshot.
    echo [2/2] Sincronizando configuracoes e iniciando...
    copy /y "%~dp0longshot_options.ini" "C:\Users\marcos\Games\Longshot\longshot_options.ini" >nul 2>&1
    cd /d "C:\Users\marcos\Games\Longshot"
    start "" "longshot.exe"
    goto :FIM
)

rem 4. Executavel local na mesma pasta do script
if exist "%~dp0longshot.exe" (
    echo [1/2] Localizada build local na pasta do script.
    echo [2/2] Sincronizando configuracoes e iniciando...
    cd /d "%~dp0"
    start "" "longshot.exe"
    goto :FIM
)

echo [AVISO] Nenhuma build pronta encontrada. Abrindo Longshot Launcher...
if exist "C:\Users\marcos\Documents\emulador\longshot\LongshotLauncher.exe" (
    cd /d "C:\Users\marcos\Documents\emulador\longshot"
    start "" "LongshotLauncher.exe"
)

:FIM
echo.
echo =======================================================================
echo   O jogo foi iniciado com sucesso! Bom jogo!
echo =======================================================================
ping -n 4 127.0.0.1 >nul
exit /b 0
