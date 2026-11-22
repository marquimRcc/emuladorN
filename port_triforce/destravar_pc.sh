#!/bin/bash
# ==============================================================================
# Script de Emergência: Destravar Sessão Gráfica Linux (AMD GPU / Triforce)
# ==============================================================================
echo "Destravando sessão gráfica..."
pkill -9 -f "bin/triforce" 2>/dev/null || true
pkill -9 -f "mangohud" 2>/dev/null || true
killall -9 triforce 2>/dev/null || true
killall -9 mangohud 2>/dev/null || true

# Se o compositor KWin (KDE) tiver pausado por timeout de fence da GPU, reinicia-o sem fechar janelas:
if pgrep -x "kwin_x11" >/dev/null 2>&1; then
    DISPLAY=:0 kwin_x11 --replace >/dev/null 2>&1 &
fi

echo "Processos encerrados e compositor liberado com sucesso!"
