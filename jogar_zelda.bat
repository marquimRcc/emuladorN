@echo off
title The Legend of Zelda: Ocarina of Time (1440p Nativo)
echo =======================================================================
echo   The Legend of Zelda: Ocarina of Time - 1440p QHD Nativo
echo   Configurado para: AMD Radeon RX 6750 XT + i5-12400F
echo =======================================================================

set "EMU=C:\Users\marcos\Documents\emulador\eglantine\eglantine.exe"
set "GAME=E:\outros\nintendo\zelda\The Legend of Zelda Ocarina of TIme [04004860224DEC000].nup"

set EDEN_NX2_SPLIT=2
set EDEN_NX2_FENCE_BATCH=1
set EDEN_NX2_VRAM_POOL=12288
set AMD_VULKAN_ICD=1

cd /d "C:\Users\marcos\Documents\emulador\eglantine"
start "" "%EMU%" -g "%GAME%"
