#!/usr/bin/env bash
# ==============================================================================
# Script de Inicialização Rápida: Super Mario Bros. Wonder (Port Nativo PC)
# Projeto: SuperWonders v0.7.0 (Static Binary Translation)
# Plataforma: Linux x86_64 | Gráficos: Vulkan (Mesa RADV ACO)
# Localização: 100% PT-BR | Controles: Layout Nativo Xbox (A/B/X/Y)
# ==============================================================================

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUPERWONDERS_DIR="/home/marcos/Games/SuperWonders_Recomp"
BIN="$SUPERWONDERS_DIR/squashfs-root/usr/bin/wonder"
APPIMAGE="$SUPERWONDERS_DIR/SuperWonders.AppImage"

# Se o script isolado existir, priorizá-lo
if [ -x "$SUPERWONDERS_DIR/jogar_superwonders_recomp.sh" ]; then
    exec "$SUPERWONDERS_DIR/jogar_superwonders_recomp.sh" "$@"
fi

# Fallback: execução direta com variáveis de ambiente
TARGET_EXEC="$BIN"
if [ ! -x "$TARGET_EXEC" ]; then
    TARGET_EXEC="$APPIMAGE"
fi

if [ ! -f "$TARGET_EXEC" ]; then
    echo "Erro: Binário do SuperWonders não encontrado em $SUPERWONDERS_DIR."
    echo "Verifique se a recompilação foi realizada conforme DOCUMENTACAO_PORT_RECOMPILADO_SUPER_MARIO_BROS_WONDER.md."
    exit 1
fi

export NX_DATA_ROOT="/home/marcos/.local/share/superwonders"
export NX_GAMELIB="/home/marcos/.local/share/superwonders/game/libwonder_game.so"
export NX_NO_LAUNCHER=1

# Otimizações de renderização Vulkan para AMD Radeon RX 6750 XT (RDNA 2)
export MESA_LOADER_DRIVER_OVERRIDE=radv
export RADV_PERFTEST=aco
export AMD_VULKAN_ICD=RADV

echo "Iniciando Super Mario Bros. Wonder (Port Nativo PC)..."
exec "$TARGET_EXEC" "$@"
