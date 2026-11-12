#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EMU="$DIR/eglantine.AppImage"
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

if [ ! -f "$EMU" ]; then
    echo "Erro: Emulador não encontrado em: $EMU"
    exit 1
fi

if [ ! -f "$GAME" ]; then
    echo "Erro: Arquivo do jogo não encontrado em: $GAME"
    exit 1
fi

# Sincroniza perfil gráfico otimizado (Bloom fix + High GPU accuracy)
if [ -f "$DIR/config/0400486024DEC000.ini" ]; then
    mkdir -p "$HOME/.config/eglantine/custom" "$HOME/.config/eden/custom"
    cp -u "$DIR/config/0400486024DEC000.ini" "$HOME/.config/eglantine/custom/0400486024DEC000.ini" 2>/dev/null || cp "$DIR/config/0400486024DEC000.ini" "$HOME/.config/eglantine/custom/"
    cp -u "$DIR/config/0400486024DEC000.ini" "$HOME/.config/eden/custom/0400486024DEC000.ini" 2>/dev/null || cp "$DIR/config/0400486024DEC000.ini" "$HOME/.config/eden/custom/"
fi

chmod +x "$EMU"
echo "Iniciando The Legend of Zelda: Ocarina of Time com auto-confirmação das configurações recomendadas..."

# Auto-confirmador do popup em background (responde 'Yes' automaticamente)
(
    for i in {1..20}; do
        sleep 0.5
        WID=$(xdotool search --name "Recommended Ocarina of Time settings" 2>/dev/null | head -n 1 || true)
        if [ -n "$WID" ]; then
            echo "Detectado popup de configurações recomendadas. Aplicando 'Yes'..."
            xdotool windowactivate "$WID" key --clearmodifiers alt+y || true
            break
        fi
    done
) &

exec "$EMU" -g "$GAME" "$@"
