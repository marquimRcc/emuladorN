#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Triforce v0.4.0 — Monitor Visual de Recompilação (1440p / FSR)
The Legend of Zelda: Ocarina of Time (Switch 2 → PC Nativo)
"""

import os
import sys
import time
import queue
import threading
import subprocess
import tkinter as tk
from pathlib import Path

TRIFORCE_DIR = Path("/home/marcos/Games/Triforce")
ICON_PATH = TRIFORCE_DIR / "icon.png"
LOG_PATH = TRIFORCE_DIR / "build.log"
RUNNER_PATH = TRIFORCE_DIR / "jogar_triforce.sh"

BG_DARK = "#121418"
BG_CARD = "#1A1D24"
BG_INPUT = "#0D0E11"
ACCENT_CYAN = "#00E5FF"
ACCENT_GREEN = "#00E676"
ACCENT_RED = "#FF5252"
TEXT_WHITE = "#FFFFFF"
TEXT_MUTED = "#8E9AA8"
BORDER_COLOR = "#2A303C"

STEPS_ORDER = ["check", "exefs", "romfs", "lift", "compile", "shaders", "prompts", "finish"]
STEPS_INFO = {
    "check":    {"title": "1. Verificação da ROM (Build e0f3ccfa)"},
    "exefs":    {"title": "2. Validação ExeFS (ZBIC Descomprimido)"},
    "romfs":    {"title": "3. Imagem RomFS (Preservada via Hardlinks)"},
    "lift":     {"title": "4. Tradução Estática AArch64 → C"},
    "compile":  {"title": "5. Compilação C/C++ (Clang 8 Jobs / PGO)"},
    "shaders":  {"title": "6. Shaders Vulkan (7.3 GB Pré-vinculados)"},
    "prompts":  {"title": "7. Prompts de Botões e Controles"},
    "finish":   {"title": "8. Conclusão e Executável Pronto"},
}

class TriforceProgressApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Triforce v0.4.0 — Recompilador Nativo (1440p / FSR)")
        self.root.geometry("740x600")
        self.root.minsize(700, 560)
        self.root.configure(bg=BG_DARK)
        self.root.wm_attributes("-topmost", True)

        if ICON_PATH.is_file():
            try:
                self.icon_photo = tk.PhotoImage(file=str(ICON_PATH))
                self.root.iconphoto(True, self.icon_photo)
                self.header_icon = self.icon_photo.subsample(4, 4)
            except Exception:
                self.header_icon = None
        else:
            self.header_icon = None

        self.msg_queue = queue.Queue()
        self.start_time = time.time()
        self.current_step = "compile"
        self.step_states = {k: "pending" for k in STEPS_ORDER}
        for k in ["check", "exefs", "romfs", "lift"]:
            self.step_states[k] = "done"

        self.progress_pct = 27.1
        self.plan_total = 127
        self.plan_compiled = 12
        self.eta_seconds = 1150
        self.build_finished = False
        self.countdown_remaining = 3

        self.build_ui()
        self.start_log_monitor_thread()
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
            title_box, text="Triforce v0.4.0 — Recompilação Nativa (1440p)",
            font=("Segoe UI", 16, "bold"), fg=TEXT_WHITE, bg=BG_DARK, anchor="w"
        )
        title_lbl.pack(anchor="w")

        sub_lbl = tk.Label(
            title_box, text="The Legend of Zelda: Ocarina of Time • Fusão NX2navi + Triforce",
            font=("Segoe UI", 10), fg=ACCENT_CYAN, bg=BG_DARK, anchor="w"
        )
        sub_lbl.pack(anchor="w")

        card = tk.Frame(self.root, bg=BG_CARD, bd=1, relief=tk.SOLID, padx=16, pady=14)
        card.pack(fill=tk.X, padx=16, pady=(0, 12))

        status_row = tk.Frame(card, bg=BG_CARD)
        status_row.pack(fill=tk.X, pady=(0, 4))

        self.step_title_lbl = tk.Label(
            status_row, text="5. Compilação C/C++ (Clang 8 Jobs / PGO)",
            font=("Segoe UI", 12, "bold"), fg=TEXT_WHITE, bg=BG_CARD, anchor="w"
        )
        self.step_title_lbl.pack(side=tk.LEFT)

        self.pct_lbl = tk.Label(
            status_row, text=f"{self.progress_pct:.1f}%",
            font=("Segoe UI", 13, "bold"), fg=ACCENT_CYAN, bg=BG_CARD, anchor="e"
        )
        self.pct_lbl.pack(side=tk.RIGHT)

        self.step_detail_lbl = tk.Label(
            card, text="Compilando módulos C com 8 threads simultâneas...",
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
            0, 0, int((self.progress_pct / 100.0) * self.canvas_w), self.canvas_h, fill=ACCENT_CYAN, width=0
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
            steps_container, text="ETAPAS DA RECOMPILAÇÃO UNIFICADA:",
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
                row, text="✓" if self.step_states[step_key] == "done" else ("⏳" if step_key == "compile" else "○"),
                font=("Segoe UI", 10, "bold"),
                fg=ACCENT_GREEN if self.step_states[step_key] == "done" else (ACCENT_CYAN if step_key == "compile" else "#5A6678"),
                bg=BG_CARD, width=2, anchor="center"
            )
            status_icon.pack(side=tk.LEFT, padx=(0, 4))

            title_txt = STEPS_INFO[step_key]["title"]
            text_lbl = tk.Label(
                row, text=title_txt, font=("Segoe UI", 9),
                fg=ACCENT_GREEN if self.step_states[step_key] == "done" else (TEXT_WHITE if step_key == "compile" else TEXT_MUTED),
                bg=BG_CARD, anchor="w"
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
            text="AMD Radeon RX 6750 XT • Mesa RADV ACO • FSR Frame Generation 2x • Triforce v0.4.0",
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
        elapsed = int(time.time() - self.start_time)
        e_min, e_sec = divmod(elapsed, 60)

        if self.build_finished:
            return

        if self.eta_seconds > 0:
            r_min, r_sec = divmod(int(self.eta_seconds), 60)
            eta_txt = f"{r_min:02d}:{r_sec:02d}"
        else:
            eta_txt = "Calculando..."

        self.time_lbl.config(text=f"⏱ Decorrido: {e_min:02d}:{e_sec:02d}  •  Restante estimado: ~{eta_txt}")
        self.root.after(1000, self.update_timer)

    def start_log_monitor_thread(self):
        def monitor_worker():
            last_pos = 0
            while not self.build_finished:
                if LOG_PATH.is_file():
                    try:
                        with open(LOG_PATH, "r", encoding="utf-8", errors="replace") as f:
                            f.seek(last_pos)
                            lines = f.readlines()
                            last_pos = f.tell()

                            for line in lines:
                                self.msg_queue.put(("log", line))
                    except Exception:
                        pass

                exe_bin = TRIFORCE_DIR / "bin" / "triforce"
                exe_root = TRIFORCE_DIR / "triforce"
                if (exe_bin.is_file() or exe_root.is_file()):
                    r = subprocess.run(["pgrep", "-f", "nx2/build.py"], capture_output=True)
                    if r.returncode != 0:
                        self.msg_queue.put(("done", "Compilação e Linkagem Concluídas!"))
                        break

                time.sleep(0.4)

        t = threading.Thread(target=monitor_worker, daemon=True)
        t.start()

    def process_queue(self):
        try:
            while True:
                msg_type, payload = self.msg_queue.get_nowait()

                if msg_type == "log":
                    line = payload.strip()
                    if line.startswith("@@stage"):
                        parts = line.split(" ", 2)
                        stage_name = parts[1] if len(parts) > 1 else ""
                        if stage_name in STEPS_INFO:
                            self.current_step = stage_name
                            self.update_step_status(stage_name, "running")
                    elif line.startswith("@@progress"):
                        try:
                            val = float(line.split(" ")[1]) * 100.0
                            self.update_progress_bar(val)
                        except Exception:
                            pass
                    elif line.startswith("@@plan"):
                        try:
                            parts = line.split(" ")
                            self.plan_total = int(parts[1])
                        except Exception:
                            pass
                    elif line.startswith("@@file"):
                        try:
                            parts = line.split(" ")
                            fname = parts[1]
                            self.plan_compiled += 1
                            self.step_detail_lbl.config(text=f"Compilado: {fname} ({self.plan_compiled}/{self.plan_total} módulos)")
                        except Exception:
                            pass
                    elif line.startswith("@@eta"):
                        try:
                            self.eta_seconds = float(line.split(" ")[1])
                        except Exception:
                            pass
                    elif line.startswith("@@done") or "progress 1.000 Done" in line:
                        self.trigger_finish()
                    else:
                        self.append_log(payload)

                elif msg_type == "done":
                    self.trigger_finish()

        except queue.Empty:
            pass

        if not self.build_finished:
            self.root.after(100, self.process_queue)

    def trigger_finish(self):
        if self.build_finished:
            return
        self.build_finished = True
        self.update_progress_bar(100.0)
        for k in STEPS_ORDER:
            self.update_step_status(k, "done")

        self.step_title_lbl.config(text="✓ Recompilação Triforce v0.4.0 Concluída!", fg=ACCENT_GREEN)
        self.step_detail_lbl.config(text="Executável 'triforce' pronto em 1440p QHD com FSR Frame Generation.")
        self.progress_canvas.itemconfig(self.bar_fill, fill=ACCENT_GREEN)
        self.append_log("\n=======================================================")
        self.append_log("✓ SUCESSO: Ocarina of Time (Triforce v0.4.0) pronto para jogar!")
        self.append_log("=======================================================\n")
        self.start_launch_countdown()

    def start_launch_countdown(self):
        if self.countdown_remaining > 0:
            self.time_lbl.config(
                text=f"🎮 Inicializando o jogo automaticamente em {self.countdown_remaining} segundos...",
                fg=ACCENT_GREEN, font=("Segoe UI", 10, "bold")
            )
            self.countdown_remaining -= 1
            self.root.after(1000, self.start_launch_countdown)
        else:
            self.time_lbl.config(text="🚀 Jogo iniciado via Gamescope 1440p!", fg=ACCENT_CYAN)
            if RUNNER_PATH.is_file():
                subprocess.Popen(["bash", str(RUNNER_PATH)], cwd=str(TRIFORCE_DIR))

def main():
    root = tk.Tk()
    app = TriforceProgressApp(root)
    root.mainloop()

if __name__ == "__main__":
    main()
