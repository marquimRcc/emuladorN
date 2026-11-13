#!/bin/bash
# ==============================================================================
# The Legend of Zelda: Ocarina of Time (NX2navi v0.10.1 - V2 1440p Nativo)
# ==============================================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

# Controles: garantir captura contínua de eventos SDL
export SDL_JOYSTICK_ALLOW_BACKGROUND_EVENTS=1

# Otimizações de renderização para AMD RDNA2 (Radeon RX 6750 XT / Mesa RADV ACO)
export RADV_PERFTEST=aco

# Bibliotecas compartilhadas
export LD_LIBRARY_PATH="/home/marcos/.local/share/nx2navi_toolchain/usr/lib64:${LD_LIBRARY_PATH:-}"

# Configurações V2 (Renderização 1080p c/ Render Scale 67 -> FSR Upscale para 1440p QHD / Async Replay / FXAA)
export NX2NAVI_GAME_RES=1080
export NX2NAVI_RENDER_SCALE=67
export NX2NAVI_OUTPUT_RES=2560x1440
export NX2NAVI_WINDOW_SIZE=2560x1440
export NX2NAVI_LOW_END_GPU=1
export NX2NAVI_REPLAY_ASYNC=1
export NX2NAVI_AA=fxaa
export NX2NAVI_ASSUME_FOCUS=1
export NX2NAVI_PERF_OVERLAY=full

EXE="$DIR/ocarina"
if [ ! -f "$EXE" ]; then
    echo "Erro: executável do jogo não encontrado em $DIR"
    exit 1
fi

chmod +x "$EXE" 2>/dev/null || true

# Modo Direto (sem Gamescope)
if [ "${1:-}" = "--direct" ] || [ "${DIRECT:-0}" = "1" ]; then
    shift || true
    echo "Iniciando The Legend of Zelda: Ocarina of Time - NX2navi V2 (1440p Direto)..."
    exec "$EXE" "$@"
fi

# Gamescope 1440p
if command -v gamescope >/dev/null 2>&1; then
    echo "Iniciando via Gamescope isolado (1440p QHD / 60Hz com GameMode)..."
    (sleep 2 && python3 "$DIR/set_game_icon.py" >/dev/null 2>&1) &
    if command -v gamemoderun >/dev/null 2>&1; then
        exec gamescope -W 2560 -H 1440 -w 2560 -h 1440 -r 60 --expose-wayland -- gamemoderun "$EXE" "$@"
    else
        exec gamescope -W 2560 -H 1440 -w 2560 -h 1440 -r 60 --expose-wayland -- "$EXE" "$@"
    fi
fi

if command -v gamemoderun >/dev/null 2>&1; then
    exec gamemoderun "$EXE" "$@"
fi
exec "$EXE" "$@"
