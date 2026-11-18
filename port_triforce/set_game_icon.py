#!/usr/bin/env python3
import sys
import time
import ctypes
import subprocess
from PIL import Image

def set_icon():
    icon_path = "/home/marcos/Games/Triforce/triforce.png"
    try:
        im = Image.open(icon_path).convert("RGBA")
    except Exception as e:
        return False

    all_data = []
    for s in [16, 24, 32, 48, 64, 128, 256]:
        resized = im.resize((s, s), Image.Resampling.LANCZOS)
        all_data.append(s)
        all_data.append(s)
        for y in range(s):
            for x in range(s):
                r, g, b, a = resized.getpixel((x, y))
                val = ((a & 0xff) << 24) | ((r & 0xff) << 16) | ((g & 0xff) << 8) | (b & 0xff)
                all_data.append(val)

    arr = (ctypes.c_ulong * len(all_data))(*all_data)

    try:
        x11 = ctypes.cdll.LoadLibrary("libX11.so.6")
        x11.XOpenDisplay.restype = ctypes.c_void_p
        x11.XOpenDisplay.argtypes = [ctypes.c_char_p]
        x11.XInternAtom.restype = ctypes.c_ulong
        x11.XInternAtom.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_int]
        x11.XChangeProperty.restype = ctypes.c_int
        x11.XChangeProperty.argtypes = [
            ctypes.c_void_p,
            ctypes.c_ulong,
            ctypes.c_ulong,
            ctypes.c_ulong,
            ctypes.c_int,
            ctypes.c_int,
            ctypes.c_void_p,
            ctypes.c_int
        ]
        x11.XFlush.argtypes = [ctypes.c_void_p]
        x11.XCloseDisplay.argtypes = [ctypes.c_void_p]

        display = x11.XOpenDisplay(None)
        if not display:
            return False

        net_wm_icon = x11.XInternAtom(display, b"_NET_WM_ICON", 0)

        p = subprocess.run(["xdotool", "search", "--class", "gamescope"], capture_output=True, text=True)
        wids = [int(w) for w in p.stdout.split() if w.strip()]
        if not wids:
            x11.XCloseDisplay(display)
            return False

        for wid in wids:
            x11.XChangeProperty(
                display,
                ctypes.c_ulong(wid),
                ctypes.c_ulong(net_wm_icon),
                ctypes.c_ulong(6),
                32,
                0,
                ctypes.cast(arr, ctypes.c_void_p),
                len(all_data)
            )

        x11.XFlush(display)
        x11.XCloseDisplay(display)
        return True
    except Exception as e:
        return False

def main():
    for attempt in range(15):
        if set_icon():
            break
        time.sleep(1)

if __name__ == "__main__":
    main()
