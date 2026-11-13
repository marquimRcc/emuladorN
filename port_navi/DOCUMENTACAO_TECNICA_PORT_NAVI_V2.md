# Documentação Técnica: Port NX2navi v0.10.1 (Navi V2 - 1440p)
**Projeto:** The Legend of Zelda: Ocarina of Time (Switch 2 → PC Linux Nativo)  
**Ambiente de Execução:** Linux (KDE Plasma / X11 / Gamescope), Intel Core i5-12400F (6C/12T), AMD Radeon RX 6750 XT (12 GB VRAM / RADV Navi 22)  
**Data:** 13 de Novembro de 2026  
**Status:** Concluído, testado e validado (19 FPS contínuos, 51.9 ms de frametime, zero leak)  

---

## 1. Objetivo & Contexto
O objetivo desta etapa foi criar um ambiente isolado denominado **Navi V2**, atualizando o motor de recompilação estática do **NX2navi v0.10.0 para v0.10.1**, preservando integralmente o ambiente anterior (`/home/marcos/Games/Navi/`) e o emulador/Hookshot.

### Motivação:
No teste inicial em 1440p da versão v0.10.0:
1. O jogo alcançava apenas **12 FPS** com tempos de quadro na casa dos **80 a 105 ms**.
2. O consumo de VRAM atingia **9.3 GB (8.7 GB alocados só pelo jogo)** com vazamento contínuo ao rotacionar a câmera.
3. Havia um conflito de resolução interno: o jogo desenhava a 1440p bruto, encolhia internamente para 1080p e o Gamescope ampliava de volta para 1440p, gerando desperdício massivo de processamento.

---

## 2. Arquitetura e Fluxo do Port

```
[ ROM .nup (24 GB) ]
         │
         ├──► Extração ExeFS (Descompressão ZBIC) ──► 5 módulos descompactados (main, sdk, subsdk0, rtld)
         │
         ├──► RomFS (26.2 GB / 186.583 arquivos) ──► Reuso via hardlink de romfs.bin + index.json (0 GB duplicados)
         │
         ├──► Lifter Estático (recomp/gen.py) ──► 548 blocos C (249.960 funções AArch64 convertidas)
         │
         ├──► Compilação Nativa (Clang 23.1 + LLD) ──► Binário nativo 'ocarina' (320 MB ELF x86_64)
         │
         ├──► Pré-Build de Shaders Vulkan ──► 42.142 variantes Maxwell traduzidas para SPIR-V / Driver Cache
         │
         └──► Camada de Execução ──► Feral GameMode (CPU 4.0 GHz) + Gamescope (2560x1440 @ 60Hz) + Mesa RADV ACO
```

---

## 3. Fatos Confirmados e Diagnóstico de Gargalos

| Fato Confirmado | Evidência Técnica | Ação / Solução Adotada |
| :--- | :--- | :--- |
| **Leak de VRAM no v0.10.0** | Changelog v0.10.1: Imagens de render target mortas ficavam presas por 120 frames ao mover a câmera (~6.7 GB vazados em 1440p). | Atualização para o kit **v0.10.1**. VRAM caiu de **8.7 GB para 7.3 GB** imediatos. |
| **Gargalo de Serialização CPU/GPU** | Telemetria F10: `Preparo CPU: 38 ms` + `Render GPU: 41 ms` = ~80 ms quando em fila sequencial (`replay_async = 0`). | Ativação do **`replay_async = 1`**. A CPU prepara o quadro $N+1$ em paralelo enquanto a GPU renderiza o quadro $N$, derrubando o frametime para **51.9 ms**. |
| **Conflito de Resolução (Downscale oculto)** | Log: `vk: FSR sharpens the shrunk picture: 2560x1440 to 1920x1080`. Janela estava travada no padrão de 1080p do motor. | Sincronização explícita: `window_size = 2560x1440` e `output_res = 2560x1440`. |
| **FSR 1 em Modo Real de Reconstrução** | Configuração de `game_res = 1080` com upscale de saída para 1440p. | A GPU desenha 44% menos pixels brutos, aliviando o tempo de desenho de 50 ms para ~35–41 ms. |
| **Instabilidade de Workers no driver RADV** | Quando forçado `replay_workers = 4`, `replay_pipe` e `replay_small`, a tela ficava preta (*device lost* no RDNA2). | Reversão para a alocação padrão de workers e uso do **Feral GameMode (`gamemoderun`)** para manter clocks máximos sem corromper as filas Vulkan. |
| **FSR 3.1 Frame Gen no Linux** | Código-fonte `runtime/vk_ffx.cpp`: o suporte ao FSR 3.1 com interpolação de quadros está isolado com `#ifdef _WIN32`. No Linux (`#else`), ele recorre ao FSR 1 e mantém `Frame generation: Off`. | Aceito como limitação atual do upstream no Linux. Configurado agendamento automatizado diário para monitorar novidades. |

---

## 4. Evolução dos Resultados (Métricas de Telemetria F10)

| Estágio de Teste | FPS | Frametime Médio | Pico Máximo | VRAM (Jogo) | GPU % | CPU / Temp |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **1. V1 Inicial (0.10.0 - 1440p Bruto c/ Leak)** | 12 | 80.8 ms | 104.9 ms | 8.7 GB | 54% | 36 °C (700 MHz) |
| **2. V2 Alinhado (0.10.1 - 1080p FSR Alinhado)** | 15 | 66.3 ms | 79.4 ms | 7.6 GB | 64% | 37 °C |
| **3. V2 Otimizado (Async Replay + FXAA)** | 18 | 54.7 ms | 64.5 ms | 7.4 GB | 93% | 38 °C |
| **4. V2 Consolidado (GameMode + Render Scale 67)** | **19** | **51.9 ms** | **63.2 ms** | **7.3 GB** | **53%** | **40 °C (4.0 GHz)** |

> **Resultado Final:** Ganho de **+58% na taxa de quadros**, corte de **28.9 ms no tempo de quadro**, eliminação de **1.4 GB de VRAM vazada** e achatamento dos picos de atraso de 105 ms para 63 ms (linha estável e sem trancos).

---

## 5. Arquivos e Configurações Entregues

### A. Configuração do Motor (`/home/marcos/Games/Navi_V2/nx2navi.ini`)
```ini
[frame rate]
fps_limit = 60
realtime = 1

[display]
perf_overlay = full
window_size = 2560x1440
output_res = 2560x1440
game_res = 1080
render_scale = 67
game_aspect = 16:9
assume_focus = 1
upscaler = fsr
sharpness = 80
aa = fxaa

[performance]
low_end_gpu = 1
replay_async = 1
```

### B. Inicializador (`/home/marcos/Games/Navi_V2/jogar_navi_v2.sh`)
* Exporta variáveis prioritárias (`NX2NAVI_GAME_RES`, `NX2NAVI_OUTPUT_RES`, `NX2NAVI_LOW_END_GPU=1`, `NX2NAVI_REPLAY_ASYNC=1`).
* Dispara via **Gamescope** com suporte a Wayland e **GameMode** (`gamemoderun`).
* Define ícone dinâmico da janela via `set_game_icon.py`.

### C. Atalho de Desktop
* Arquivo: `/home/marcos/Área de trabalho/Zelda_Ocarina_Navi_V2.desktop`
* Ícone: `/home/marcos/Games/Navi_V2/icon.png`

---

## 6. Procedimentos de Segurança e Rollback

1. **Backup do Estado Inicial (V1 1440p):**
   - Pasta: `/home/marcos/Games/Navi_BACKUP_ORIGINAL_1440P/`
   - Archive: `/home/marcos/Games/Navi_BACKUP_ORIGINAL_1440P.tar.gz`
   - Restauração: `/home/marcos/Games/Navi/restaurar_backup_original.sh`
2. **Backup do Estado Otimizado V2 (18–19 FPS):**
   - Pasta: `/home/marcos/Games/Navi_V2_BACKUP_DEFINITIVO_18FPS/`
   - Archive: `/home/marcos/Games/Navi_V2_BACKUP_DEFINITIVO_18FPS.tar.gz`
   - Restauração: `/home/marcos/Games/Navi_V2/restaurar_backup_18fps.sh`

---

## 7. Monitoramento Automatizado de Atualizações
* **Script de checagem:** `/home/marcos/Games/Navi/verificar_atualizacoes.sh` (faz consulta silenciosa à API de lançamentos do NX2navi e emite `notify-send` com o ícone do jogo caso encontre versão nova).
* **Autostart no Login/Boot:** `~/.config/autostart/nx2navi-update-check.desktop`
* **Agendamento Recorrente:** `~/.config/systemd/user/nx2navi-update.timer` (disparado todos os dias pontualmente às 09:00).
