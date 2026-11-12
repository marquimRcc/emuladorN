@echo off
set "EMU=%USERPROFILE%\Documentos\emulador\eglantine\eglantine.exe"
set "GAME=%USERPROFILE%\Documentos\emulador\The Legend of Zelda Ocarina of TIme [04004860224DEC000].nup"

if not exist "%EMU%" (
    echo [ERRO] Emulador nao encontrado em: %EMU%
    echo Execute primeiro o script preparar_windows.ps1
    pause
    exit /b 1
)

if not exist "%GAME%" (
    echo [AVISO] Coloque o arquivo .nup do jogo na mesma pasta:
    echo %GAME%
    pause
    exit /b 1
)

echo Iniciando The Legend of Zelda Ocarina of Time no Windows...
start "" "%EMU%" -g "%GAME%"
