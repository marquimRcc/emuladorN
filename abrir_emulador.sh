#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EMU="$DIR/eglantine.AppImage"

export DISPLAY="${DISPLAY:-:0}"
export SDL_GAMECONTROLLERCONFIG="0300f6b6c82d00000b31000014010000,8BitDo Ultimate 2,a:b0,b:b1,x:b2,y:b3,back:b6,start:b7,guide:b8,leftshoulder:b4,rightshoulder:b5,leftstick:b9,rightstick:b10,leftx:a0,lefty:a1,rightx:a3,righty:a4,lefttrigger:a2,righttrigger:a5,dpup:h0.1,dpdown:h0.4,dpleft:h0.8,dpright:h0.2,platform:Linux,"

if [ ! -f "$EMU" ]; then
    echo "Erro: Emulador não encontrado em: $EMU"
    exit 1
fi

chmod +x "$EMU"
echo "Abrindo interface gráfica do Eglantine..."
exec "$EMU" "$@"
