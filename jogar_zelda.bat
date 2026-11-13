@echo off
title The Legend of Zelda: Ocarina of Time (FullHD 1080p @ 30 FPS Travado)
echo =======================================================================
echo   The Legend of Zelda: Ocarina of Time - NX2navi (FullHD 1080p @ 30 FPS)
echo   Hardware: AMD Radeon RX 6750 XT (12GB) • Intel Core i5-12400F
echo   Resolucao: 1920x1080 (Janela FullHD) • Limite: 30 FPS Cravados
echo =======================================================================

rem Captura continua de controles XInput / SDL
set SDL_JOYSTICK_ALLOW_BACKGROUND_EVENTS=1

rem Perfil 1080p 30 FPS Rock-Solid Validado (6.2 GB VRAM • 33.3 ms)
set NX2NAVI_GAME_RES=1080
set NX2NAVI_RENDER_SCALE=100
set NX2NAVI_OUTPUT_RES=1920x1080
set NX2NAVI_WINDOW_SIZE=1920x1080
set NX2NAVI_FULLSCREEN=0
set NX2NAVI_UPSCALER=fsr
set NX2NAVI_SHARPNESS=80
set NX2NAVI_AA=fxaa
set NX2NAVI_FRAMEGEN=off
set NX2NAVI_VK_PRESENT=fifo
set NX2NAVI_FPS_LIMIT=30
set NX2NAVI_REALTIME=1
set NX2NAVI_HIGHFPS_FIX=1
set NX2NAVI_STEP_STEADY=1
set NX2NAVI_PERF_OVERLAY=full
set NX2NAVI_ASSUME_FOCUS=1
set NX2NAVI_LOW_END_GPU=1
set NX2NAVI_REPLAY_ASYNC=1
set NX2NAVI_TEX_COMPACT=1

cd /d "E:\outros\nintendo\zelda\Zelda_Ocarina_Navi_PC"
start "" "ocarina.exe"
