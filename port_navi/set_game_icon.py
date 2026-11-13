#!/usr/bin/env python3
import sys
import subprocess
import tkinter as tk

def main():
    icon_path = "/home/marcos/Games/Navi/icon.png"
    root = tk.Tk()
    root.withdraw()
    try:
        img = tk.PhotoImage(file=icon_path)
    except Exception as e:
        print(f"Error loading image: {e}")
        return

    orig_w = img.width()
    orig_h = img.height()

    factor = max(1, orig_w // 48)
    sub = img.subsample(factor, factor)
    w = sub.width()
    h = sub.height()

    data = [str(w), str(h)]
    for y in range(h):
        for x in range(w):
            rgb = sub.get(x, y)
            r, g, b = rgb[0], rgb[1], rgb[2]
            a = 255
            val = (a << 24) | (r << 16) | (g << 8) | b
            data.append(str(val))

    try:
        p = subprocess.run(
            ["xdotool", "search", "--class", "gamescope"],
            capture_output=True, text=True, check=True
        )
        wids = [line.strip() for line in p.stdout.split() if line.strip()]
    except Exception as e:
        print(f"xdotool search failed: {e}")
        return

    for wid in wids:
        cmd = ["xprop", "-id", wid, "-f", "_NET_WM_ICON", "32c", "-set", "_NET_WM_ICON", ",".join(data)]
        res = subprocess.run(cmd, capture_output=True, text=True)
        print(f"Set icon on window {wid}: return code {res.returncode}")

if __name__ == "__main__":
    main()
