#!/bin/bash
# ==============================================================================
# The Legend of Zelda: Ocarina of Time (Switch 2 PC Recomp - Triforce v0.6.0)
# Inicializador de Alta Performance para Linux (AMD Radeon RX 6750 XT / Mesa RADV ACO)
# Com AMD FSR 4 Nativo, MangoHud Ativo e Feral GameMode
# ==============================================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

# Controles: garantir captura contínua de eventos de gamepad SDL
export SDL_JOYSTICK_ALLOW_BACKGROUND_EVENTS=1

# Otimizações de renderização para AMD RDNA2 (Radeon RX 6750 XT / Mesa RADV ACO)
export RADV_PERFTEST=aco
export AMD_VULKAN_ICD=RADV

# Suprimir pop-up de atualização para entrada direta no jogo
export HOOKSHOT_NO_UPDATE_CHECK=1

# Ativação do MangoHud nativo do Regata OS com métricas de alta visibilidade
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

# Configurar prefixo de execução com GameMode e MangoHud
LAUNCHER_WRAP=""
if command -v gamemoderun >/dev/null 2>&1; then
    LAUNCHER_WRAP="gamemoderun"
fi
if command -v mangohud >/dev/null 2>&1; then
    LAUNCHER_WRAP="${LAUNCHER_WRAP} mangohud"
fi

# Modo Gamescope opcional (apenas se solicitado explicitamente com --gamescope)
if [ "${1:-}" = "--gamescope" ] || [ "${GAMESCOPE:-0}" = "1" ]; then
    shift || true
    if command -v gamescope >/dev/null 2>&1; then
        echo "Iniciando via Gamescope isolado (1080p -> 1440p)..."
        if [ -f "$DIR/set_game_icon.py" ]; then
            (sleep 2 && python3 "$DIR/set_game_icon.py" >/dev/null 2>&1) &
        fi
        if [ -n "$LAUNCHER_WRAP" ]; then
            exec gamescope -W 2560 -H 1440 -w 1920 -h 1080 -r 60 -F fsr --expose-wayland -- $LAUNCHER_WRAP "$EXE" "$@"
        else
            exec gamescope -W 2560 -H 1440 -w 1920 -h 1080 -r 60 -F fsr --expose-wayland -- "$EXE" "$@"
        fi
    fi
fi

# MODO PADRÃO: Direto Nativo Vulkan (Máxima fluidez, latência zero e MangoHud visível)
if [ "${1:-}" = "--direct" ]; then
    shift || true
fi

echo "Iniciando The Legend of Zelda: Ocarina of Time (Triforce v0.6.0 + AMD FSR 4 + MangoHud)..."
if [ -n "$LAUNCHER_WRAP" ]; then
    exec $LAUNCHER_WRAP "$EXE" "$@"
else
    exec "$EXE" "$@"
fi
