@echo off
title The Legend of Zelda: Ocarina of Time (Longshot Windows - FullHD 1080p)
echo =======================================================================
echo   The Legend of Zelda: Ocarina of Time - Longshot (FullHD 1080p)
echo   Hardware: AMD Radeon RX 6750 XT (12GB) • Intel Core i5-12400F
echo   Configuracao: Perfil Validado nos Commits do emuladorN
echo   Resolucao: 1920x1080 • FSR 80%% • Frame Pacing Ativo • Xbox Controls
echo =======================================================================

rem Captura continua de controles XInput / SDL em segundo plano
set SDL_JOYSTICK_ALLOW_BACKGROUND_EVENTS=1

rem Driver Vulkan AMD Adrenalin nativo
set AMD_VULKAN_ICD=1

rem Travas de fluidez e tempo real dos commits
set HOS_REALTIME_STEP=1
set HOS_DYNRES=0
set RX_VK_PACE=1
set RX_VK_FRAMEGEN_MULT=0
set RX_VK_ASTC_RGBA8=0

rem Sincronizacao de configuracao
if not exist "C:\Users\marcos\Games\Longshot" mkdir "C:\Users\marcos\Games\Longshot"
copy /y "%~dp0longshot_options.ini" "C:\Users\marcos\Games\Longshot\longshot_options.ini" >nul 2>&1

rem Verificacao do binario executavel do jogo Longshot
if exist "C:\Users\marcos\Games\Longshot\longshot.exe" (
    echo Iniciando o jogo via Longshot compilado...
    cd /d "C:\Users\marcos\Games\Longshot"
    copy /y "%~dp0longshot_options.ini" "longshot_options.ini" >nul 2>&1
    start "" "longshot.exe"
    exit /b 0
)

if exist "E:\outros\nintendo\zelda\Longshot\longshot.exe" (
    echo Iniciando o jogo via Longshot compilado em E:\...
    cd /d "E:\outros\nintendo\zelda\Longshot"
    copy /y "%~dp0longshot_options.ini" "longshot_options.ini" >nul 2>&1
    start "" "longshot.exe"
    exit /b 0
)

rem Caso ainda nao tenha compilado o jogo pelo Longshot, abre o Launcher oficial
echo.
echo Executavel nativo do jogo ainda nao encontrado no diretorio padrao.
echo Abrindo o Longshot Launcher para selecao do dump/construcao...
echo ROM do jogo: E:\outros\nintendo\zelda\The Legend of Zelda Ocarina of TIme [04004860224DEC000].nup
echo.

cd /d "C:\Users\marcos\Documents\emulador\longshot"
start "" "LongshotLauncher.exe"
