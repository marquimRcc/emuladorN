#!/bin/bash
# ==============================================================================
# The Legend of Zelda: Ocarina of Time (Switch 2 PC Recomp - Triforce v0.6.0)
# Inicializador FullHD 1080p Otimizado para AMD Radeon RX 6750 XT / Mesa RADV ACO
# Com Upscale FSR 165Hz no Gamescope e MangoHud Nativo do Regata OS
# ==============================================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

# Controles: garantir captura contínua de eventos de gamepad SDL
export SDL_JOYSTICK_ALLOW_BACKGROUND_EVENTS=1

# Otimizações de renderização para AMD RDNA2 (Radeon RX 6750 XT / Mesa RADV ACO)
export RADV_PERFTEST=aco
export AMD_VULKAN_ICD=RADV

# Resolução de renderização: FullHD 1080p (output_res=3) com proporção 16:9 perfeita
export HOS_OUTPUT_RES=3
export HOS_FULLSCREEN=0
export HOS_FIX_RES=1

# Suprimir pop-up de atualização para entrada direta no jogo
export HOOKSHOT_NO_UPDATE_CHECK=1

# Configuração de telemetria MangoHud nativo do Regata OS
export MANGOHUD=1
export MANGOHUD_CONFIG="cpu_temp,gpu_temp,ram,vram,gpu_core_clock,fps,frametime=1,frame_timing=1,gamemode,font_size=20,position=top-left"

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

# Configurar GameMode para o processo do jogo
GAME_WRAP=""
if command -v gamemoderun >/dev/null 2>&1; then
    GAME_WRAP="gamemoderun"
fi

# Detectar taxa de atualização do monitor primário (165Hz para o monitor atual)
REFRESH_RATE=165
if command -v xrandr >/dev/null 2>&1; then
    DETECTED_HZ=$(xrandr 2>/dev/null | grep -E "connected primary" -A 1 | grep -oE "[0-9]+\.[0-9]+\*" | tr -d '*' | cut -d'.' -f1 || true)
    if [ -n "$DETECTED_HZ" ] && [ "$DETECTED_HZ" -ge 60 ]; then
        REFRESH_RATE="$DETECTED_HZ"
    fi
fi

# Injetar o ícone oficial na janela automaticamente em segundo plano
if [ -f "$DIR/set_game_icon.py" ]; then
    (sleep 2 && python3 "$DIR/set_game_icon.py" >/dev/null 2>&1) &
fi

# Modo Direto (sem Gamescope) se passar --direct
if [ "${1:-}" = "--direct" ] || [ "${DIRECT:-0}" = "1" ]; then
    shift || true
    echo "Iniciando em Modo Direto (FullHD 1080p nativo)..."
    MANGOHUD_CMD=""
    if command -v mangohud >/dev/null 2>&1; then
        MANGOHUD_CMD="mangohud"
    fi
    if [ -n "$GAME_WRAP" ]; then
        exec $MANGOHUD_CMD $GAME_WRAP "$EXE" "$@"
    else
        exec $MANGOHUD_CMD "$EXE" "$@"
    fi
fi

# Modo Padrão: Gamescope FullHD 1080p -> 1440p FSR a 165Hz com MangoHud externo
if command -v gamescope >/dev/null 2>&1; then
    echo "Iniciando via Gamescope (FullHD 1080p -> 1440p FSR a ${REFRESH_RATE}Hz com MangoHud)..."
    
    MANGOHUD_CMD=""
    if command -v mangohud >/dev/null 2>&1; then
        MANGOHUD_CMD="mangohud"
    fi

    exec $MANGOHUD_CMD gamescope \
        -W 2560 -H 1440 \
        -w 1920 -h 1080 \
        -r "$REFRESH_RATE" \
        -F fsr \
        --fsr-sharpness 2 \
        --force-windows-fullscreen \
        --expose-wayland \
        -- $GAME_WRAP "$EXE" "$@"
fi

# Fallback nativo se Gamescope não estiver instalado
if [ -n "$GAME_WRAP" ]; then
    exec $GAME_WRAP "$EXE" "$@"
fi
exec "$EXE" "$@"
