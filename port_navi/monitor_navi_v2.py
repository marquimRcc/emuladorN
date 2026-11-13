#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
NX2navi v0.10.1 — Monitor Visual V2 (1440p Nativo)
The Legend of Zelda: Ocarina of Time (Switch 2 → PC Nativo)
"""

import os
import sys
import json
import time
import queue
import threading
import subprocess
import tkinter as tk
from pathlib import Path

NAVI_DIR = Path("/home/marcos/Games/Navi_V2")
ICON_PATH = NAVI_DIR / "icon.png"
LOG_PATH = NAVI_DIR / "build_v2.log"
RUNNER_PATH = NAVI_DIR / "jogar_navi_v2.sh"
NUP_PATH = Path("/home/marcos/Downloads/The Legend of Zelda Ocarina of Time [0400486024dec000][v131072].nup")
KIT_DIR = Path("/home/marcos/.local/share/nx2navi_v2/kit")
TOOLCHAIN_DIR = Path("/home/marcos/.local/share/nx2navi_toolchain")
PY_BIN = Path("/tmp/nx2navi-root/usr/python/bin/python3")

BG_DARK = "#121418"
BG_CARD = "#1A1D24"
BG_INPUT = "#0D0E11"
ACCENT_CYAN = "#00E5FF"
ACCENT_GREEN = "#00E676"
ACCENT_RED = "#FF5252"
TEXT_WHITE = "#FFFFFF"
TEXT_MUTED = "#8E9AA8"
BORDER_COLOR = "#2A303C"

STEPS_ORDER = ["check", "exefs", "romfs", "lift", "compile", "shaders", "prompts", "scan"]
STEPS_INFO = {
    "check":    {"title": "1. Verificação da ROM (Build e0f3ccfa)", "weight": (0, 5)},
    "exefs":    {"title": "2. Validação ExeFS (ZBIC Descomprimido)", "weight": (5, 15)},
    "romfs":    {"title": "3. Imagem RomFS (Preservada)", "weight": (15, 30)},
    "lift":     {"title": "4. Recompilação Estática v0.10.1", "weight": (30, 60)},
    "compile":  {"title": "5. Compilação C/C++ (vk_texture.c corrigido)", "weight": (60, 90)},
    "shaders":  {"title": "6. Shaders Vulkan (Cache Pré-construído)", "weight": (90, 95)},
    "prompts":  {"title": "7. Prompts de Botões e Controles", "weight": (95, 98)},
    "scan":     {"title": "8. Conclusão e Testes Finais", "weight": (98, 100)},
}

class NaviV2ProgressApp:
    def __init__(self, root):
        self.root = root
        self.root.title("NX2navi v0.10.1 — Recompilador V2 (1440p)")
        self.root.geometry("740x590")
        self.root.minsize(700, 560)
        self.root.configure(bg=BG_DARK)
        self.root.wm_attributes("-topmost", True)

        if ICON_PATH.is_file():
            try:
                self.icon_photo = tk.PhotoImage(file=str(ICON_PATH))
                self.root.iconphoto(True, self.icon_photo)
                self.header_icon = self.icon_photo.subsample(4, 4)
            except Exception as e:
                self.header_icon = None
        else:
            self.header_icon = None

        self.msg_queue = queue.Queue()
        self.start_time = time.time()
        self.current_step = "check"
        self.step_states = {k: "pending" for k in STEPS_ORDER}
        self.progress_pct = 0.0
        self.build_finished = False
        self.countdown_remaining = 3

        self.build_ui()
        self.start_build_thread()
        self.root.after(50, self.process_queue)
        self.root.after(1000, self.update_timer)

    def build_ui(self):
        header = tk.Frame(self.root, bg=BG_DARK, pady=12, padx=16)
        header.pack(fill=tk.X)

        if self.header_icon:
            icon_lbl = tk.Label(header, image=self.header_icon, bg=BG_DARK)
            icon_lbl.pack(side=tk.LEFT, padx=(0, 14))

        title_box = tk.Frame(header, bg=BG_DARK)
        title_box.pack(side=tk.LEFT, fill=tk.Y)

        title_lbl = tk.Label(
            title_box, text="NX2navi v0.10.1 — Recompilação V2 (1440p)",
            font=("Segoe UI", 16, "bold"), fg=TEXT_WHITE, bg=BG_DARK, anchor="w"
        )
        title_lbl.pack(anchor="w")

        sub_lbl = tk.Label(
            title_box, text="The Legend of Zelda: Ocarina of Time • Correção de VRAM em 1440p Nativo",
            font=("Segoe UI", 10), fg=ACCENT_CYAN, bg=BG_DARK, anchor="w"
        )
        sub_lbl.pack(anchor="w")

        card = tk.Frame(self.root, bg=BG_CARD, bd=1, relief=tk.SOLID, padx=16, pady=14)
        card.pack(fill=tk.X, padx=16, pady=(0, 12))

        status_row = tk.Frame(card, bg=BG_CARD)
        status_row.pack(fill=tk.X, pady=(0, 4))

        self.step_title_lbl = tk.Label(
            status_row, text="Iniciando recompilação incremental v0.10.1...",
            font=("Segoe UI", 12, "bold"), fg=TEXT_WHITE, bg=BG_CARD, anchor="w"
        )
        self.step_title_lbl.pack(side=tk.LEFT)

        self.pct_lbl = tk.Label(
            status_row, text="0%",
            font=("Segoe UI", 13, "bold"), fg=ACCENT_CYAN, bg=BG_CARD, anchor="e"
        )
        self.pct_lbl.pack(side=tk.RIGHT)

        self.step_detail_lbl = tk.Label(
            card, text="Aproveitando assets e preparando compilação...",
            font=("Segoe UI", 9), fg=TEXT_MUTED, bg=BG_CARD, anchor="w"
        )
        self.step_detail_lbl.pack(fill=tk.X, pady=(0, 8))

        self.canvas_w = 670
        self.canvas_h = 24
        self.progress_canvas = tk.Canvas(
            card, width=self.canvas_w, height=self.canvas_h,
            bg=BG_INPUT, highlightthickness=1, highlightbackground=BORDER_COLOR
        )
        self.progress_canvas.pack(fill=tk.X, pady=(0, 8))
        self.bar_fill = self.progress_canvas.create_rectangle(
            0, 0, 0, self.canvas_h, fill=ACCENT_CYAN, width=0
        )

        time_row = tk.Frame(card, bg=BG_CARD)
        time_row.pack(fill=tk.X)

        self.time_lbl = tk.Label(
            time_row, text="⏱ Decorrido: 00:00  •  Restante estimado: Calculando...",
            font=("Segoe UI", 9), fg=TEXT_MUTED, bg=BG_CARD
        )
        self.time_lbl.pack(side=tk.LEFT)

        steps_container = tk.Frame(self.root, bg=BG_DARK, padx=16)
        steps_container.pack(fill=tk.X, pady=(0, 10))

        steps_title = tk.Label(
            steps_container, text="ETAPAS DA RECOMPILAÇÃO V2:",
            font=("Segoe UI", 9, "bold"), fg=TEXT_MUTED, bg=BG_DARK, anchor="w"
        )
        steps_title.pack(anchor="w", pady=(0, 4))

        checklist_card = tk.Frame(steps_container, bg=BG_CARD, bd=1, relief=tk.SOLID, padx=12, pady=8)
        checklist_card.pack(fill=tk.X)

        self.step_labels = {}
        col_left = tk.Frame(checklist_card, bg=BG_CARD)
        col_left.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        col_right = tk.Frame(checklist_card, bg=BG_CARD)
        col_right.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)

        for i, step_key in enumerate(STEPS_ORDER):
            parent_col = col_left if i < 4 else col_right
            row = tk.Frame(parent_col, bg=BG_CARD, pady=2)
            row.pack(fill=tk.X, anchor="w")

            status_icon = tk.Label(
                row, text="○", font=("Segoe UI", 10, "bold"),
                fg="#5A6678", bg=BG_CARD, width=2, anchor="center"
            )
            status_icon.pack(side=tk.LEFT, padx=(0, 4))

            title_txt = STEPS_INFO[step_key]["title"]
            text_lbl = tk.Label(
                row, text=title_txt, font=("Segoe UI", 9),
                fg=TEXT_MUTED, bg=BG_CARD, anchor="w"
            )
            text_lbl.pack(side=tk.LEFT)

            self.step_labels[step_key] = {"icon": status_icon, "text": text_lbl}

        log_frame = tk.Frame(self.root, bg=BG_DARK, padx=16)
        log_frame.pack(fill=tk.BOTH, expand=True, pady=(0, 10))

        log_hdr = tk.Label(
            log_frame, text="LOG DE ATIVIDADE EM TEMPO REAL:",
            font=("Segoe UI", 9, "bold"), fg=TEXT_MUTED, bg=BG_DARK, anchor="w"
        )
        log_hdr.pack(anchor="w", pady=(0, 4))

        self.log_text = tk.Text(
            log_frame, bg=BG_INPUT, fg="#9CDCFE", font=("Consolas", 8),
            height=6, bd=1, relief=tk.SOLID, highlightthickness=1,
            highlightbackground=BORDER_COLOR, wrap=tk.NONE
        )
        self.log_text.pack(fill=tk.BOTH, expand=True)

        footer = tk.Frame(self.root, bg=BG_DARK, padx=16, pady=4)
        footer.pack(fill=tk.X, side=tk.BOTTOM)

        footer_lbl = tk.Label(
            footer,
            text="AMD Radeon RX 6750 XT • Mesa RADV ACO • 1440p QHD Nativo • NX2navi v0.10.1",
            font=("Segoe UI", 8), fg="#5A6678", bg=BG_DARK
        )
        footer_lbl.pack(side=tk.LEFT)

    def append_log(self, text):
        clean_line = text.strip()
        if not clean_line or clean_line.startswith("@@"):
            return
        self.log_text.insert(tk.END, clean_line + "\n")
        self.log_text.see(tk.END)

    def update_step_status(self, step_key, state, detail=""):
        if step_key not in self.step_labels:
            return

        icon_lbl = self.step_labels[step_key]["icon"]
        text_lbl = self.step_labels[step_key]["text"]

        if state == "running":
            icon_lbl.config(text="⏳", fg=ACCENT_CYAN)
            text_lbl.config(fg=TEXT_WHITE)
            self.step_title_lbl.config(text=STEPS_INFO[step_key]["title"])
            if detail:
                self.step_detail_lbl.config(text=detail)
        elif state == "done":
            icon_lbl.config(text="✓", fg=ACCENT_GREEN)
            text_lbl.config(fg=ACCENT_GREEN)
        elif state == "error":
            icon_lbl.config(text="✗", fg=ACCENT_RED)
            text_lbl.config(fg=ACCENT_RED)
        elif state == "skip":
            icon_lbl.config(text="✓", fg=ACCENT_GREEN)
            text_lbl.config(fg=ACCENT_GREEN)

    def update_progress_bar(self, pct):
        self.progress_pct = max(0.0, min(100.0, pct))
        self.pct_lbl.config(text=f"{self.progress_pct:.1f}%")
        self.root.update_idletasks()
        current_w = self.progress_canvas.winfo_width()
        if current_w <= 1:
            current_w = self.canvas_w
        fill_w = (self.progress_pct / 100.0) * current_w
        self.progress_canvas.coords(self.bar_fill, 0, 0, fill_w, self.canvas_h)

    def update_timer(self):
        if not self.build_finished:
            elapsed = int(time.time() - self.start_time)
            m, s = divmod(elapsed, 60)
            if self.progress_pct > 2.0:
                est_total = elapsed / (self.progress_pct / 100.0)
                rem = max(0, int(est_total - elapsed))
                rm, rs = divmod(rem, 60)
                eta_str = f"~{rm:02d}:{rs:02d}"
            else:
                eta_str = "Calculando..."
            self.time_lbl.config(text=f"⏱ Decorrido: {m:02d}:{s:02d}  •  Restante estimado: {eta_str}")
            self.root.after(1000, self.update_timer)

    def process_queue(self):
        try:
            while True:
                msg = self.msg_queue.get_nowait()
                self.handle_message(msg)
        except queue.Empty:
            pass

        if not self.build_finished or self.countdown_remaining > 0:
            self.root.after(50, self.process_queue)

    def handle_message(self, msg):
        mtype = msg.get("type")
        if mtype == "log":
            self.append_log(msg.get("text", ""))
        elif mtype == "event":
            data = msg.get("data", {})
            ev = data.get("ev")
            step = data.get("step")

            if ev == "step":
                state = data.get("state")
                if state == "start":
                    self.current_step = step
                    step_idx = STEPS_ORDER.index(step) if step in STEPS_ORDER else 0
                    for prev in STEPS_ORDER[:step_idx]:
                        self.update_step_status(prev, "done")
                    self.update_step_status(step, "running")
                    w_start, _ = STEPS_INFO.get(step, {}).get("weight", (self.progress_pct, self.progress_pct))
                    self.update_progress_bar(w_start)
                elif state == "done":
                    self.update_step_status(step, "done")
                    _, w_end = STEPS_INFO.get(step, {}).get("weight", (self.progress_pct, self.progress_pct))
                    self.update_progress_bar(w_end)
                elif state == "skip":
                    self.update_step_status(step, "done")
                    _, w_end = STEPS_INFO.get(step, {}).get("weight", (self.progress_pct, self.progress_pct))
                    self.update_progress_bar(w_end)

            elif ev == "progress":
                step = data.get("step", self.current_step)
                detail = data.get("detail", "")
                fraction = data.get("fraction")
                done = data.get("done")
                total = data.get("total")
                unit = data.get("unit", "")

                step_w = STEPS_INFO.get(step, {}).get("weight", (0, 100))
                if fraction is not None:
                    step_prog = float(fraction)
                elif done is not None and total and total > 0:
                    step_prog = done / total
                    if not detail:
                        if unit == "bytes":
                            detail = f"{done / (1024*1024):.1f} MB / {total / (1024*1024):.1f} MB"
                        else:
                            detail = f"{done} / {total} {unit}"
                else:
                    step_prog = 0.0

                overall_pct = step_w[0] + step_prog * (step_w[1] - step_w[0])
                self.update_progress_bar(overall_pct)
                if detail:
                    self.step_detail_lbl.config(text=f"{detail} ({self.progress_pct:.1f}%)")

            elif ev == "phase":
                phase = data.get("phase", "")
                if phase == "link":
                    self.step_detail_lbl.config(text="Linkando executável nativo ocarina com ld.lld...")

            elif ev == "end":
                self.on_build_success(data)

            elif ev == "error":
                self.on_build_error(data.get("message", "Erro desconhecido"))

        elif mtype == "finished":
            code = msg.get("code")
            if code == 0:
                if not self.build_finished:
                    self.on_build_success({})
            else:
                self.on_build_error(f"Processo finalizou com erro (código {code})")

    def on_build_success(self, data):
        self.build_finished = True
        for s in STEPS_ORDER:
            self.update_step_status(s, "done")
        self.update_progress_bar(100.0)
        self.progress_canvas.itemconfig(self.bar_fill, fill=ACCENT_GREEN)
        self.pct_lbl.config(text="100%", fg=ACCENT_GREEN)
        self.step_title_lbl.config(text="✓ Recompilação V2 concluída com sucesso!", fg=ACCENT_GREEN)

        elapsed = int(time.time() - self.start_time)
        m, s = divmod(elapsed, 60)
        self.time_lbl.config(text=f"✓ Concluído em {m:02d}:{s:02d} • Iniciando jogo...")

        self.append_log(f"Sucesso: Jogo v0.10.1 gerado em {NAVI_DIR}/ocarina")
        self.start_countdown()

    def start_countdown(self):
        if self.countdown_remaining > 0:
            self.step_detail_lbl.config(
                text=f"Abrindo The Legend of Zelda: Ocarina of Time V2 (1440p) em {self.countdown_remaining} segundos...",
                fg=ACCENT_CYAN
            )
            self.countdown_remaining -= 1
            self.root.after(1000, self.start_countdown)
        else:
            self.step_detail_lbl.config(
                text="Iniciando jogo via Gamescope 1440p...", fg=ACCENT_GREEN
            )
            self.launch_game()
            self.root.after(3000, self.root.destroy)

    def launch_game(self):
        try:
            self.append_log(f"Executando: {RUNNER_PATH}")
            env = os.environ.copy()
            env["DISPLAY"] = ":0"
            subprocess.Popen(["setsid", str(RUNNER_PATH)], cwd=str(NAVI_DIR), env=env)
        except Exception as e:
            self.step_detail_lbl.config(text=f"Erro ao iniciar o jogo: {e}", fg=ACCENT_RED)
            self.append_log(f"Erro ao iniciar o jogo: {e}")

    def on_build_error(self, message):
        self.build_finished = True
        self.update_step_status(self.current_step, "error")
        self.progress_canvas.itemconfig(self.bar_fill, fill=ACCENT_RED)
        self.step_title_lbl.config(text="Falha na Recompilação", fg=ACCENT_RED)
        self.step_detail_lbl.config(text=message, fg=ACCENT_RED)
        self.append_log(f"ERRO: {message}")

    def start_build_thread(self):
        t = threading.Thread(target=self.build_worker, daemon=True)
        t.start()

    def build_worker(self):
        env = os.environ.copy()
        env["PATH"] = f"{TOOLCHAIN_DIR}/usr/bin:{env.get('PATH', '')}"
        env["C_INCLUDE_PATH"] = f"{TOOLCHAIN_DIR}/usr/include"
        env["CPLUS_INCLUDE_PATH"] = f"{TOOLCHAIN_DIR}/usr/include"
        env["LIBRARY_PATH"] = f"{TOOLCHAIN_DIR}/usr/lib64:/usr/lib64"
        env["LD_LIBRARY_PATH"] = f"{TOOLCHAIN_DIR}/usr/lib64:{env.get('LD_LIBRARY_PATH', '')}"
        env["PYTHONPATH"] = "/home/marcos/.local/share/nx2navi/pydeps"
        env["DISPLAY"] = ":0"

        if "XAUTHORITY" not in env or not os.path.exists(env["XAUTHORITY"]):
            import glob
            xauths = sorted(glob.glob("/tmp/xauth_*"), key=os.path.getmtime, reverse=True)
            if xauths:
                env["XAUTHORITY"] = xauths[0]

        cmd = [
            str(PY_BIN), "-u", "-I",
            str(KIT_DIR / "tools" / "make_game.py"),
            "--nup", str(NUP_PATH),
            "--out", str(NAVI_DIR),
            "--jobs", "10",
            "--events"
        ]

        with open(LOG_PATH, "w", encoding="utf-8") as log_f:
            try:
                proc = subprocess.Popen(
                    cmd,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    text=True,
                    bufsize=1,
                    env=env,
                    cwd=str(NAVI_DIR)
                )

                for line in proc.stdout:
                    log_f.write(line)
                    log_f.flush()
                    line_s = line.strip()
                    if line_s.startswith("@@"):
                        try:
                            ev_data = json.loads(line_s[2:])
                            self.msg_queue.put({"type": "event", "data": ev_data})
                        except Exception:
                            self.msg_queue.put({"type": "log", "text": line_s})
                    else:
                        self.msg_queue.put({"type": "log", "text": line_s})

                proc.wait()
                self.msg_queue.put({"type": "finished", "code": proc.returncode})
            except Exception as e:
                self.msg_queue.put({
                    "type": "event",
                    "data": {"ev": "error", "message": str(e)}
                })
                self.msg_queue.put({"type": "finished", "code": 1})

def main():
    root = tk.Tk(className="nx2navi-v2-build")
    app = NaviV2ProgressApp(root)
    root.mainloop()

if __name__ == "__main__":
    main()
