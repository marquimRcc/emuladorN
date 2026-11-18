#!/bin/bash
# ==============================================================================
# The Legend of Zelda: Ocarina of Time (Switch 2 PC Recomp - Triforce v0.4.0)
# Inicializador Otimizado para Linux (AMD Radeon RX 6750 XT / Mesa RADV ACO)
# Com MangoHud nativo do Regata OS e Feral GameMode
# ==============================================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

# Controles: garantir captura contínua de eventos de gamepad SDL
export SDL_JOYSTICK_ALLOW_BACKGROUND_EVENTS=1

# Otimizações de renderização para AMD RDNA2 (Radeon RX 6750 XT / Mesa RADV ACO)
export RADV_PERFTEST=aco

# Resolução de saída: 1080p Full HD (output_res=3)
export HOS_OUTPUT_RES=3

# Ativação do MangoHud nativo do Regata OS (telemetria em tempo real)
export MANGOHUD=1

# Suprimir pop-up de atualização para entrada direta no jogo
export HOOKSHOT_NO_UPDATE_CHECK=1

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

# Modo Direto (sem Gamescope) se passar --direct ou DIRECT=1
if [ "${1:-}" = "--direct" ] || [ "${DIRECT:-0}" = "1" ]; then
    shift || true
    echo "Iniciando The Legend of Zelda: Ocarina of Time (Triforce - Modo Direto com MangoHud)..."
    if [ -n "$LAUNCHER_WRAP" ]; then
        exec $LAUNCHER_WRAP "$EXE" "$@"
    else
        exec "$EXE" "$@"
    fi
fi

# Por padrão, executar via Gamescope isolado (blindando a sessão Wayland/X11 e aplicando FSR/HDR se desejado)
if command -v gamescope >/dev/null 2>&1; then
    echo "Iniciando via Gamescope isolado (Triforce 1080p FullHD -> 1440p FSR / 60Hz com GameMode e MangoHud)..."
    # Injetar o ícone oficial na janela do Gamescope automaticamente
    if [ -f "$DIR/set_game_icon.py" ]; then
        (sleep 2 && python3 "$DIR/set_game_icon.py" >/dev/null 2>&1) &
    fi

    if [ -n "$LAUNCHER_WRAP" ]; then
        exec gamescope -W 2560 -H 1440 -w 1920 -h 1080 -r 60 -F fsr --expose-wayland -- $LAUNCHER_WRAP "$EXE" "$@"
    else
        exec gamescope -W 2560 -H 1440 -w 1920 -h 1080 -r 60 -F fsr --expose-wayland -- "$EXE" "$@"
    fi
fi

# Fallback nativo se Gamescope não estiver instalado
if [ -n "$LAUNCHER_WRAP" ]; then
    exec $LAUNCHER_WRAP "$EXE" "$@"
fi
exec "$EXE" "$@"
