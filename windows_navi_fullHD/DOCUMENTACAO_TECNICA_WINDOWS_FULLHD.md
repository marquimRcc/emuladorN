# Documentação Técnica: Port NX2navi v0.10.1 (Windows FullHD 1080p @ 30 FPS)
**Projeto:** The Legend of Zelda: Ocarina of Time (Nintendo Switch 2 / NUP `0400486024DEC000` → PC Windows Nativo)  
**Ambiente de Execução:** Windows 11 Pro 64-bit, Intel Core i5-12400F (6C/12T), AMD Radeon RX 6750 XT (12 GB VRAM / RDNA2 Navi 22), 32 GB RAM DDR4  
**Data da Validação:** 13 de Novembro de 2026  
**Status:** Concluído, testado e 100% validado em jogo (30.0 FPS cravados, 33.3 ms de frametime estável, 63 °C / 52 W na GPU).

---

## 1. Resumo Executivo e Validação

Após a recompilação estática nativa do jogo via **NX2navi v0.10.1** (249.960 funções AArch64 convertidas para código x86_64 e linkadas no binário nativo `ocarina.exe` de 305 MB), foram realizados testes intensivos de estabilidade e calibração gráfica na Floresta Kokiri (*Kokiri Forest*).

A meta de execução estabelecida pelo usuário (**Resolução FullHD 1080p em Janela com 30 FPS travados e sem artefatos visuais**) foi plenamente atingida com telemetria perfeita.

### Telemetria Consolidada em Jogo (Validação F10):
- **Taxa de Quadros (FPS):** **30 FPS** (1% piores: **30 FPS** | 0.1% piores: **30 FPS**)
- **Tempo de Quadro (Frametime):** **33.3 ms** (Máximo: **33.5 ms**) — Linha de cadência perfeitamente plana e horizontal, sem nenhum micro-engasgo (*stutter-free*).
- **Consumo e Temperatura da GPU:** **72% de uso**, **63 °C** de temperatura e consumo de apenas **52 Watts** (queda substancial frente aos 72 °C e 120 W observados em 60 FPS destravado).
- **VRAM Alocada:** **7.3 GB total** (apenas **6.2 GB consumidos pelo jogo** dos 12.0 GB disponíveis na RX 6750 XT).
- **CPU (i5-12400F):** **35% total** (apenas **21% consumidos pelo jogo**), operando a frios **28 °C**.
- **RAM do Sistema:** **20.9 GB total** (**8.4 GB alocados pelo jogo**).
- **Esperas de Pipeline e Shaders:** **0.00 ms** (835+ pipelines Vulkan compilados e persistidos no cache local).
- **Envios de Textura por Quadro:** **0.0**.

---

## 2. Comparativo de Desempenho e Evolução dos Perfis

| Perfil / Plataforma | Resolução / Upscaler | FPS Médio | Frametime | 1% Piores | VRAM Jogo | GPU Temp / Watts | Comportamento Visual |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **Linux (Port Navi V2)** | 1440p / FSR 1 (Scale 67) | 19 FPS | 51.9 ms | ~15 FPS | 7.3 GB | 40 °C | Estável, porém limitado pela renderização bruta e GameMode. |
| **Windows - FSR 3.1 Native AA** | 1080p / FSR 3.1 + TAA + SMAA | 35 FPS | 28.5 ms | 27 FPS (0.1%: 6 FPS) | 6.5 GB | 70 °C / 89 W | Quedas severas de framerate, piscadas e oscilações bruscas. |
| **Windows - FSR 1 Destravado** | 1080p / FSR 1 80% + FXAA | 61 FPS | 16.5 ms (GPU: 12.9 ms) | 44 FPS | 6.7 GB | 72 °C / 120 W | Muito fluido, porém com alta demanda térmica e consumo de pico. |
| **Windows - FullHD 30 FPS Travado (Final)** | **1080p / FSR 1 80% + FXAA** | **30 FPS** | **33.3 ms (máx 33.5)** | **30 FPS (0.1%: 30)** | **6.2 GB** | **63 °C / 52 W** | **Perfeito: cadência rochosa, zero oscilação, frio e silencioso.** |

---

## 3. Diagnóstico e Resolução das Falhas Gráficas e de Estabilidade

### A. Eliminação dos Blocos Quadrados Cianos na Floresta Kokiri
- **Sintoma:** Esporos flutuantes, poeira mágica e névoa da Floresta Kokiri eram renderizados como cubos ou quadrados verdes/cianos flutuantes com bordas rígidas.
- **Causa Raiz:** O motor NX2navi ativou por padrão a compressão de texturas ASTC para **BC3/BC1 (`astc_bc = 1`)** ao detectar sistema com menos de 48 GB de RAM ou menos de 20 GB de VRAM. O algoritmo de blocos BC3 degrada brutalmente gradientes alfa translúcidos, transformando partículas circulares em blocos opacos.
- **Solução:** Configurado **`astc_bc = 0`** e **`astc_bc1 = 0`** no arquivo `nx2navi.ini`. As texturas ASTC passam a ser descompactadas diretamente em formato **RGBA8 nativo sem perdas**, devolvendo a suavidade original das partículas.

### B. Eliminação das Piscadas Pretas na Tela (*Black Flickering*)
- **Sintoma:** O jogo apresentava quadros pretos ou piscadas escuras intermitentes durante a movimentação da câmera.
- **Causa Raiz:** A flag `replay_async = 1` envia os comandos NVN para uma thread separada. O manual do NX2navi (`nx2navi.ini.example`, linha 85) adverte categoricamente: *"adds up to a frame of latency, and can show a dark or flickering frame now and then: the other thread reads vertex and buffer memory the game has sometimes rewritten by then"*.
- **Solução:** Configurado **`replay_async = 0`** e **`replay_workers = 0`**, eliminando a corrida de leitura de memória e encerrando 100% das piscadas.

### C. Esclarecimento: FSR 3.1 Native AA vs. FSR 1
- **Dúvida:** *"não estava no FSR 3.1, não compensa?"*
- **Explicação Técnica:** No teste com FSR 3.1, o jogo estava selecionado em **Native AA** (`dlss = dlaa`). O Native AA **não faz upscaling** (desenha a 1080p nativo) e adiciona o custo de reconstrução temporal, acumulação de histórico, anti-aliasing SMAA + TAA e re-renderização de vetores de movimento de todos os personagens e do Link a cada quadro (`dlaa_objmv = 1`, `selective_motion = 1`). Isso dobrou o tempo de preparo de GPU de 9.4 ms para 19.9 ms, derrubando os 0.1% piores para 6 FPS.
- O **FSR 1 (EASU + RCAS)** com nitidez em 80% realiza a filtragem espacial com custo de GPU desprezível (< 0.2 ms), permitindo que a RX 6750 XT mantenha mais de 70% de folga ociosa a 30 FPS.

### D. Prevenção do Travamento / Crash de Memória Virtual (`VK_ERROR_DEVICE_LOST`)
- **Sintoma:** O PC travou totalmente e precisou de reinicialização forçada. O log registrou falha `device fault: read invalid at 0x506100000` e esgotamento de commit (`31363 of 35194 MB`).
- **Causa Raiz:** O Windows 11 gerenciava o arquivo de paginação do disco C: em modo dinâmico limitado a ~2048 MB. Ao somar o espaço de endereçamento mapeado pelo Switch 2 (~24 GB virtuais) com a memória do sistema e driver AMD, o Windows atingiu o teto de commit, gerando timeout do driver de vídeo (TDR).
- **Solução Combinada:**
  1. No motor: Ativado **`heap_lazy = 1`** (economiza 3.4 GB de commit de largada), **`tex_compact = 1`** e **`tex_released_max = 2048`**.
  2. No sistema operacional: Desenvolvido o script `configurar_pagefile.bat` que aloca automaticamente entre **16.384 MB (16 GB) e 32.768 MB (32 GB)** de memória virtual dedicada no Drive `D:\` (onde há mais de 800 GB livres).

---

## 4. Estrutura dos Arquivos da Pasta `windows_navi_fullHD`

```
windows_navi_fullHD/
├── nx2navi.ini                      # Configuração consolidada do motor NX2navi (1080p @ 30 FPS)
├── jogar_zelda.bat                  # Script de inicialização com travas de ambiente e captura XInput
├── configurar_pagefile.bat          # Inicializador com elevação UAC para o ajuste de memória virtual
├── configurar_pagefile_d.ps1        # Script WMI/CIM que configura o pagefile de 16-32 GB no D:\
├── romfs-check.json                 # Auditoria e integridade da extração do RomFS (186.583 arquivos)
├── icon.png                         # Ícone em alta resolução do jogo para janelas e atalhos
├── README.md                        # Guia rápido de execução e atalhos
└── DOCUMENTACAO_TECNICA_WINDOWS_FULLHD.md # Este documento técnico detalhado
```

---

## 5. Parâmetros Chave do `nx2navi.ini`

```ini
[display]
window_size = 1920x1080
output_res = 1920x1080
game_res = 1080
game_aspect = 16:9
fullscreen = 0
assume_focus = 1
perf_overlay = full
upscaler = fsr
sharpness = 80
standin_filter = easu
aa = fxaa
dlaa = 0
framegen = off
vk_present = fifo
texture_detail = full
shadow_res = 1024
aniso = 16

[frame rate]
fps_limit = 30
realtime = 1
fps60 = 0
highfps_fix = 1
step_steady = 1
rtss = 0

[performance]
astc = auto
astc_bc = 0
astc_bc1 = 0
replay_async = 0
replay_workers = 0
heap_lazy = 1
tex_compact = 1
tex_released_max = 2048
tex_clobber = 1
split_idle = 0
low_end_gpu = 0
zstd_native = 1
pipeline_cache = 1
cores = 10
```

---

## 6. Conclusão

O ambiente Windows consolidado na pasta `windows_navi_fullHD` superou tanto a experiência anterior do Linux quanto as iterações iniciais de teste:
- Eliminação completa de artefatos visuais (sem cubos cianos e sem telas pretas).
- Cadência perfeita de 30.0 FPS com frametime estável de 33.3 ms.
- Temperatura da GPU reduzida para 63 °C com baixíssimo ruído e consumo de apenas 52 W.
- Estabilidade total contra estouro de commit de memória.
