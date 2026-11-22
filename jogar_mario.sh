#!/usr/bin/env bash
# ==============================================================================
# Super Mario Bros. Wonder (Nintendo Switch / Switch 2 Edition)
# Inicializador Nativo Vulkan (RADV ACO) para AMD Radeon RX 6750 XT
# Áudio e Textos 100% em Português do Brasil (PT-BR Oficial)
# Suporte total a Controles SDL (8BitDo Ultimate 2, Xbox, DualSense)
# ==============================================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Localiza o melhor binário do emulador Eglantine / Eden
if [ -f "$DIR/eglantine.AppImage" ]; then
    EMU="$DIR/eglantine.AppImage"
elif [ -f "$DIR/eglantine-daily-20261120-pgo.AppImage" ]; then
    EMU="$DIR/eglantine-daily-20261120-pgo.AppImage"
elif [ -f "$DIR/lichii-v160-pgo.AppImage" ]; then
    EMU="$DIR/lichii-v160-pgo.AppImage"
else
    echo "Erro: Nenhum executável do emulador encontrado em: $DIR"
    exit 1
fi

# Localização da ROM (.nup)
GAME="/run/media/marcos/backup5TB/Jogos/Outros/nintendo/Super Mario Bros Wonders Switch 2 Edition [010015100B514000].nup"

if [ ! -f "$GAME" ]; then
    echo "Erro: Arquivo do jogo não encontrado em: $GAME"
    exit 1
fi

# Configuração de Display e Sessão Gráfica X11
export DISPLAY="${DISPLAY:-:0}"
if [ -z "$XAUTHORITY" ] || [ ! -f "$XAUTHORITY" ]; then
    if [ -f "/run/user/$(id -u)/.Xauthority" ]; then
        export XAUTHORITY="/run/user/$(id -u)/.Xauthority"
    elif [ -f "$HOME/.Xauthority" ]; then
        export XAUTHORITY="$HOME/.Xauthority"
    fi
fi

# Otimizações de driver gráfico AMD RADV ACO para RX 6750 XT
export RADV_PERFTEST=aco
export AMD_VULKAN_ICD=RADV
export EDEN_NX2_SPLIT=2

# Mapeamento do gamepad (8BitDo Ultimate 2 Wireless e compatíveis)
export SDL_GAMECONTROLLERCONFIG="0300f6b6c82d00000b31000014010000,8BitDo Ultimate 2 Wireless Controller,a:b0,b:b1,x:b2,y:b3,back:b6,start:b7,guide:b8,leftshoulder:b4,rightshoulder:b5,leftstick:b9,rightstick:b10,leftx:a0,lefty:a1,rightx:a3,righty:a4,lefttrigger:a2,righttrigger:a5,dpup:h0.1,dpdown:h0.4,dpleft:h0.8,dpright:h0.2,platform:Linux,"

# Sincroniza o perfil gráfico e as opções de idioma PT-BR (Title ID: 010015100B514000)
TITLE_ID="010015100B514000"
if [ -f "$DIR/config/${TITLE_ID}.ini" ]; then
    for app in eglantine eden lichii; do
        mkdir -p "$HOME/.config/$app/custom"
        cp -f "$DIR/config/${TITLE_ID}.ini" "$HOME/.config/$app/custom/${TITLE_ID}.ini"
    done
fi

chmod +x "$EMU"
echo "Iniciando Super Mario Bros. Wonder em PT-BR via $(basename "$EMU")..."

# Tratamento para popups automáticos em background caso use versão legada
(
    for i in {1..20}; do
        sleep 0.5
        WID=$(xdotool search --name "Recommended" 2>/dev/null | head -n 1 || true)
        if [ -n "$WID" ]; then
            xdotool windowactivate "$WID" key --clearmodifiers Escape || true
            break
        fi
    done
) &

exec "$EMU" -g "$GAME" "$@"
