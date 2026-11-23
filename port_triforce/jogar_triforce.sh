#!/bin/bash
# ==============================================================================
# The Legend of Zelda: Ocarina of Time (Switch 2 PC Recomp - Triforce v0.7.1)
# Inicializador Direto Nativo FullHD 1080p para AMD Radeon RX 6750 XT (Mesa RADV ACO)
# Máxima Qualidade Gráfica, Latência Zero, Sem Gamescope (Estabilidade Total)
# ==============================================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

# Controles: garantir captura contínua de eventos de gamepad SDL
export SDL_JOYSTICK_ALLOW_BACKGROUND_EVENTS=1
export HOS_INPUT_BACKGROUND=1

# Otimizações de renderização para AMD RDNA2 (Radeon RX 6750 XT / Mesa RADV ACO)
export RADV_PERFTEST=aco
export AMD_VULKAN_ICD=RADV

# Controle de Clock e Performance de GPU (Forçar clock alto sem permissão root)
if [ -w /sys/class/drm/card0/device/power_dpm_force_performance_level ]; then
    echo "high" > /sys/class/drm/card0/device/power_dpm_force_performance_level 2>/dev/null || true
fi
export RX_VK_GPU_CLOCK=peak

# Inicialização Instantânea e Eliminação de Tela Preta (Bypass do loop de 13 min de predição)
export RX_VK_PREDICT_S=0

# Desativação de Filtros e Módulos Experimentais (Cenário 3D Limpo em SDR)
export RX_VK_N64=0
export RX_VK_RENODX=0

# Sincronização e Estabilidade Vulkan / Pacing de Vídeo a 60 FPS
export RX_VK_MIRROR_PIECES=0
export RX_VK_HOLD_MS=0
export RX_VK_FIFO=1
export RX_VK_MOVIE_UPSCALE=linear
export HOS_MOVIE_PACE=0
export HOS_VIDEO_NO_CATCHUP=1
export HOS_SHORT_SLEEP_TIMER=1
export HOS_FPS_MAX=60
export HOS_FPS_TARGET=60
export RX_VK_SYNC_CAPTURE=0
export RX_VK_CAPTURE_BEHIND=1
export RX_VK_NO_READBACK_WAIT=1
export RX_VK_LAZY_WB=1

# Otimizações de CPU e Threads (Elimina Starvation de Vcores no Intel Core i5-12400F)
export HOS_VCORE_SPIN_US=0
export HOS_VCORES=off
export HOS_PRIO=0

# Resolução: Travar em FullHD 1080p Nativo e forçar tamanho de janela real (Fim do 720p/blur)
export HOS_OUTPUT_RES=3
export HOS_WINDOW_SIZE=1920x1080
export HOS_FULLSCREEN=1
export HOS_FIX_RES=1

# Suprimir pop-up de atualização para entrada direta no jogo
export HOOKSHOT_NO_UPDATE_CHECK=1

# Telemetria MangoHud estabilizada a 60 FPS
export MANGOHUD=1
export MANGOHUD_CONFIG="fps_limit=60,cpu_temp,gpu_temp,ram,vram,gpu_core_clock,fps,frametime=1,frame_timing=1,gamemode,font_size=18,position=top-left"

# Localizar o binário do Triforce
EXE=""
if [ -x "$DIR/bin/triforce" ]; then
    EXE="$DIR/bin/triforce"
elif [ -x "$DIR/triforce" ]; then
    EXE="$DIR/triforce"
elif [ -x "$DIR/bin/hookshot" ]; then
    EXE="$DIR/bin/hookshot"
else
    echo "Erro: executável do Triforce não encontrado em $DIR"
    exit 1
fi

chmod +x "$EXE" 2>/dev/null || true

# Configurar prefixo com GameMode e MangoHud
LAUNCHER_WRAP=""
if command -v gamemoderun >/dev/null 2>&1; then
    LAUNCHER_WRAP="gamemoderun"
fi
if command -v mangohud >/dev/null 2>&1; then
    LAUNCHER_WRAP="${LAUNCHER_WRAP} mangohud"
fi

# Injetar o ícone oficial na janela automaticamente em segundo plano
if [ -f "$DIR/set_game_icon.py" ]; then
    (sleep 2 && python3 "$DIR/set_game_icon.py" >/dev/null 2>&1) &
fi

# Fallback opcional caso queira testar Gamescope: passar --gamescope
if [ "${1:-}" = "--gamescope" ]; then
    shift || true
    if command -v gamescope >/dev/null 2>&1; then
        echo "Iniciando via Gamescope isolado (1080p -> 1440p)..."
        exec gamescope -W 2560 -H 1440 -w 1920 -h 1080 -r 165 -F fsr --force-windows-fullscreen -- $LAUNCHER_WRAP "$EXE" "$@"
    fi
fi

# MODO PADRÃO: Direto Nativo Vulkan (Sem Gamescope, Sem congelamentos, Alta Qualidade)
echo "Iniciando The Legend of Zelda: Ocarina of Time (Triforce v0.7.1 - FullHD 1080p Nativo)..."
LOG_FILE="$DIR/game_live.log"
echo "=== Sessão iniciada em $(date) ===" >> "$LOG_FILE"

# Watchdog automático de proteção contra congelamento:
# Se o Triforce perder o dispositivo Vulkan ou o driver acusar timeout, o watchdog
# detecta e mata o processo imediatamente, liberando o X11 e impedindo o freeze do PC.
(
    tail -n 0 -F "$LOG_FILE" 2>/dev/null | while read -r line; do
        if echo "$line" | grep -qiE "VK_ERROR_DEVICE_LOST|GPU device was lost|context is lost"; then
            echo "[WATCHDOG] Detectada perda de dispositivo Vulkan! Abortando processo para evitar congelamento do PC..." >> "$LOG_FILE"
            pkill -9 -f "bin/triforce" 2>/dev/null || true
            pkill -9 -f "mangohud" 2>/dev/null || true
            (sleep 1 && DISPLAY=:0 kwin_x11 --replace >/dev/null 2>&1) &
            break
        fi
    done
) &
WATCHDOG_PID=$!

trap 'kill $WATCHDOG_PID 2>/dev/null || true; echo auto > /sys/class/drm/card0/device/power_dpm_force_performance_level 2>/dev/null || true' EXIT

if [ -n "$LAUNCHER_WRAP" ]; then
    $LAUNCHER_WRAP "$EXE" "$@" 2>&1 | tee -a "$LOG_FILE"
else
    "$EXE" "$@" 2>&1 | tee -a "$LOG_FILE"
fi

echo auto > /sys/class/drm/card0/device/power_dpm_force_performance_level 2>/dev/null || true
kill $WATCHDOG_PID 2>/dev/null || true
