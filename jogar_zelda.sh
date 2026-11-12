#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$DIR/lichii-v160-pgo.AppImage" ]; then
    EMU="$DIR/lichii-v160-pgo.AppImage"
elif [ -f "$DIR/eglantine.AppImage" ]; then
    EMU="$DIR/eglantine.AppImage"
else
    echo "Erro: Nenhum emulador encontrado em: $DIR"
    exit 1
fi
GAME="$DIR/The Legend of Zelda Ocarina of TIme [04004860224DEC000].nup"

export DISPLAY="${DISPLAY:-:0}"
if [ -z "$XAUTHORITY" ] || [ ! -f "$XAUTHORITY" ]; then
    if [ -f "/run/user/$(id -u)/.Xauthority" ]; then
        export XAUTHORITY="/run/user/$(id -u)/.Xauthority"
    elif [ -f "$HOME/.Xauthority" ]; then
        export XAUTHORITY="$HOME/.Xauthority"
    fi
fi
export EDEN_NX2_SPLIT=2
export SDL_GAMECONTROLLERCONFIG="0300f6b6c82d00000b31000014010000,8BitDo Ultimate 2 Wireless Controller,a:b0,b:b1,x:b2,y:b3,back:b6,start:b7,guide:b8,leftshoulder:b4,rightshoulder:b5,leftstick:b9,rightstick:b10,leftx:a0,lefty:a1,rightx:a3,righty:a4,lefttrigger:a2,righttrigger:a5,dpup:h0.1,dpdown:h0.4,dpleft:h0.8,dpright:h0.2,platform:Linux,"

if [ ! -f "$GAME" ]; then
    echo "Erro: Arquivo do jogo não encontrado em: $GAME"
    exit 1
fi

# Sincroniza perfil gráfico otimizado (High GPU accuracy + Bloom fix + Shaders síncronos)
if [ -f "$DIR/config/0400486024DEC000.ini" ]; then
    for app in eglantine eden lichii; do
        mkdir -p "$HOME/.config/$app/custom"
        cp -f "$DIR/config/0400486024DEC000.ini" "$HOME/.config/$app/custom/0400486024DEC000.ini"
    done
fi

chmod +x "$EMU"
echo "Iniciando The Legend of Zelda: Ocarina of Time via $(basename "$EMU")..."

# Tratamento do popup caso use Eglantine legado (responde Escape para NÃO sobrepor os gráficos)
(
    for i in {1..20}; do
        sleep 0.5
        WID=$(xdotool search --name "Recommended Ocarina of Time settings" 2>/dev/null | head -n 1 || true)
        if [ -n "$WID" ]; then
            echo "Popup de configurações detectado. Fechando com Escape para preservar gráficos corretos..."
            xdotool windowactivate "$WID" key --clearmodifiers Escape || true
            break
        fi
    done
) &

exec "$EMU" -g "$GAME" "$@"
