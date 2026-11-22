# Emulador Nintendo Switch 2 (Eglantine) - The Legend of Zelda: Ocarina of Time Remake

Scripts de automação, patches de desempenho (60 FPS), configurações gráficas e guias técnicos para emulação de **The Legend of Zelda: Ocarina of Time (Nintendo Switch 2 Remake)** no **Linux (Regata OS)** e **Windows**.

---

## 🎮 Informações dos Jogos e Emulador

- **Jogos Suportados**:
  - **The Legend of Zelda: Ocarina of Time (Nintendo Switch 2 Remake)**
    - Title ID: `0400486024DEC000` | Build ID: `E0F3CCFAF50065AE4EA01EB5AEB13B1A45DA3348`
  - **Super Mario Bros. Wonder (Nintendo Switch / Switch 2 Edition)**
    - Title ID: `010015100B514000` | Localização: **PT-BR Oficial (Vozes e Textos)**
- **Emulador**: Eglantine v0.1.0-rc3 PGO (fork de Eden/Yuzu com suporte à API gráfica NVN2 e formato .nup)
- **Driver Gráfico Testado**: Vulkan (Mesa RADV 26.x ACO em AMD Radeon RX 6750 XT / Windows Adrenalin)

---

## 📁 Estrutura do Repositório

```text
.
├── abrir_emulador.sh           # Abre a interface gráfica do emulador Eglantine
├── jogar_zelda.sh              # Inicializador otimizado de Zelda (SDL, AMD RADV, Docked)
├── jogar_mario.sh              # Inicializador otimizado de Super Mario Bros. Wonder (PT-BR, Vulkan ACO)
├── instalar_patches.py         # Injetor automático dos patches de 60 FPS e Resolução Máxima (Zelda)
├── mario_wonder_icon.png       # Ícone oficial em alta definição (512x512)
├── DOCUMENTACAO_TECNICA_SUPER_MARIO_BROS_WONDER.md # Registro técnico completo da implementação Linux
├── config/
│   ├── 010015100B514000.ini    # Perfil gráfico e de idioma PT-BR (Super Mario Bros. Wonder)
│   └── 0400486024DEC000.ini    # Configuração gráfica recomendada (Zelda OOT Remake)
├── port_navi/                  # Port nativo estático Linux (NX2navi v0.10.1 - V2 1440p QHD / FSR)
│   ├── DOCUMENTACAO_TECNICA_PORT_NAVI_V2.md # Registro completo do port Linux, benchmarks e correções
│   ├── nx2navi.ini             # Configuração otimizada Linux (FSR 1, Async Replay, Low-End GPU)
│   ├── jogar_navi_v2.sh        # Launcher nativo Gamescope + Feral GameMode (4.0 GHz)
│   ├── monitor_navi_v2.py      # Widget gráfico de compilação em tempo real (Tkinter)
│   ├── restaurar_backup_18fps.sh # Script de rollback automático em 1 clique
│   ├── set_game_icon.py        # Fix de ícone da janela para o KDE Plasma / Wayland
│   └── icon.png                # Ícone oficial da Navi
├── port_triforce/              # Port nativo unificado Linux (Triforce Project v0.5.2 - 1080p FSR)
│   ├── DOCUMENTACAO_TECNICA_PORT_TRIFORCE.md # Documentação completa do port v0.5.2, benchmark e MangoHud
│   ├── triforce_options.ini    # Configuração gráfica e telemetria (1080p nativo, FPS counter)
│   ├── jogar_triforce.sh       # Launcher Gamescope 1080p -> 1440p FSR + GameMode + MangoHud
│   ├── set_game_icon.py        # Injetor ctypes libX11 multi-resolução com canal alpha real
│   ├── monitor_triforce.py     # Widget gráfico de compilação em tempo real (Tkinter)
│   ├── triforce.png            # Brasão oficial do Triforce Project em alta definição
│   ├── Zelda_Triforce_v0.5.2.desktop # Atalho do jogo para o ambiente desktop
│   └── Triforce_Launcher.desktop     # Atalho do novo Launcher Oficial com benchmark e mods
├── windows_navi_fullHD/        # Port nativo estático Windows 11 (NX2navi v0.10.1 - FullHD 1080p @ 30 FPS)
│   ├── DOCUMENTACAO_TECNICA_WINDOWS_FULLHD.md # Relatório técnico completo de validação (30 FPS, 33.3 ms, 63 °C)
│   ├── nx2navi.ini             # Configuração consolidada (FSR 1 80%, ASTC RGBA8 puro, heap_lazy)
│   ├── jogar_zelda.bat         # Launcher Windows 1080p com variáveis de ambiente e suporte a controle
│   ├── configurar_pagefile.bat # Script com elevação UAC para fix de memória virtual no D:\
│   ├── configurar_pagefile_d.ps1 # Script WMI de paginação (16-32 GB dedicados)
│   ├── romfs-check.json        # Auditoria de integridade do RomFS
│   ├── icon.png                # Ícone em alta resolução
│   └── README.md               # Guia rápido de execução no Windows
├── windows_longshot/           # Configuração e automação do emulador/port Longshot 3.0 (Team MagicBean)
│   ├── DOCUMENTACAO_TECNICA_WINDOWS_LONGSHOT.md # Relatório técnico de fixes (ASTC, Vulkan 1.4, DIB icon, memória)
│   ├── longshot_options.ini    # Configuração calibrada para RX 6750 XT e 1080p 60 FPS
│   ├── jogar_zelda_longshot.bat # Launcher automatizado com travas de ambiente e Anti-Lag 2
│   ├── criar_atalho_desktop.ps1 # Automação para gerar atalho com ícone nativo no Desktop
│   ├── longshot.ico            # Ícone oficial multi-resolução nativo DIB (16-128px) + PNG (256px)
│   ├── longshot.png            # Logotipo oficial 512x512 com canal alpha
│   └── README.md               # Guia de uso do Longshot 3.0 no Windows
├── jogar_zelda.bat             # Script de inicialização rápida para Windows (raiz)
├── preparar_windows.ps1        # Automação completa para configuração no Windows PowerShell
├── REGISTRO_DESEMPENHO_E_AJUSTES.md # Relatório técnico de desempenho e fixes de clarões brancos
├── GUIA_MIGRACAO_WINDOWS.md    # Guia detalhado de migração e configuração no Windows
├── icon.png                    # Ícone em alta resolução do jogo (512x512)
└── README.md
```

---

## 🚀 Como Executar no Linux (Regata OS)

### 1. Pré-requisitos
- Coloque o binário `eglantine.AppImage` (versão v0.1.0-rc3 PGO ou superior) na pasta raiz.
- Coloque a sua ROM do jogo (ex.: `The Legend of Zelda Ocarina of TIme [04004860224DEC000].nup`).

### 2. Configuração Gráfica
Copie o arquivo de configuração para os diretórios do emulador (o script `jogar_zelda.sh` também faz isso automaticamente):
```bash
mkdir -p ~/.config/eglantine/custom/ ~/.config/eden/custom/
cp config/0400486024DEC000.ini ~/.config/eglantine/custom/
cp config/0400486024DEC000.ini ~/.config/eden/custom/
```

### 3. Aplicar Patches de 60 FPS e Resolução Máxima
O script `instalar_patches.py` gera e injeta os arquivos binários IPS32 necessários para desativar o limitador nativo de 20 FPS e impedir a queda de resolução dinâmica (DRS). Compatível com Linux e Windows:
```bash
python3 instalar_patches.py
```

### 4. Jogar

- **Para iniciar The Legend of Zelda: Ocarina of Time**:
  ```bash
  chmod +x jogar_zelda.sh
  ./jogar_zelda.sh
  ```

- **Para iniciar Super Mario Bros. Wonder (100% em PT-BR)**:
  ```bash
  chmod +x jogar_mario.sh
  ./jogar_mario.sh
  ```
  *Ou use o atalho criado na Área de Trabalho: `Super_Mario_Bros_Wonder.desktop`.*

Consulte [DOCUMENTACAO_TECNICA_SUPER_MARIO_BROS_WONDER.md](./DOCUMENTACAO_TECNICA_SUPER_MARIO_BROS_WONDER.md) para todos os detalhes técnicos da calibração gráfica, driver RADV ACO e localização PT-BR.

---

## 🪟 Como Executar no Windows

1. Consulte o guia passo a passo em [GUIA_MIGRACAO_WINDOWS.md](./GUIA_MIGRACAO_WINDOWS.md).
2. Para automação rápida, abra o PowerShell como usuário e execute:
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   .\preparar_windows.ps1
   ```
3. Inicie o jogo pelo arquivo `jogar_zelda.bat`.

---

## ⚙️ Principais Ajustes Aplicados

- **Correção de Clarões Brancos / Bloom Estourado (AMD RADV)**: Ajustado `gpu_accuracy=1` (Alta Precisão) e `fix_bloom_effects=true` no arquivo INI para evitar saturação excessiva do pós-processamento.
- **Desativação de Frame Generation Interno**: Desativado (`frame_gen=false`) para eliminar judder/tremor na imagem, permitindo taxa de quadros limpa.
- **Modo Docked Forçado**: `use_docked_mode=1` para garantir a resolução e qualidade máxima dos shaders.
- **Idioma**: Configurado para Português do Brasil (`language_index=17`, `region_index=1`).

---

## 🧚 Ports Nativos para PC (NX2navi & Longshot)

Além da emulação tradicional com Eglantine, o repositório inclui os arquivos e guias técnicos dos ports nativos via recompilação estática com **NX2navi v0.10.1** e **Longshot** (Team MagicBean):

### 1. Windows Longshot 3.0 Nativo ([`windows_longshot/`](windows_longshot/))
- **Documentação Completa:** [DOCUMENTACAO_TECNICA_WINDOWS_LONGSHOT.md](windows_longshot/DOCUMENTACAO_TECNICA_WINDOWS_LONGSHOT.md)
- **Emulador/Port:** Longshot v3.0.0 (sucessor do Hookshot).
- **Desempenho Validado em Jogo (Kokiri Forest):** **60.0 FPS** cravados e contínuos, tempo de GPU de apenas **0.82 ms** por quadro, **zero draws descartados** (`0.0 draws left out`) e memória RAM estabilizada em ~3,5 GB.
- **Configurações dos Commits Aplicadas:** Resolução FullHD 1080p nativa (`output_res = 1920x1080`, `resolution = 1`), AMD Anti-Lag 2 ativo (`amd_anti-lag_2 = 1`), cadência fixa (`frame_pacing = 1`, `realtime = 1`), teto de VRAM protegido em 4 GB (`preset = 4`, `vram_budget = 4`) e mapeamento Xbox em português (`pad_layout = 1`, `game_lang = 8`).
- **Launcher e Atalho:** [`jogar_zelda_longshot.bat`](windows_longshot/jogar_zelda_longshot.bat) e [`criar_atalho_desktop.ps1`](windows_longshot/criar_atalho_desktop.ps1) com ícone oficial [`longshot.ico`](windows_longshot/longshot.ico).

### 2. Windows FullHD 1080p @ 30 FPS Travado ([`windows_navi_fullHD/`](windows_navi_fullHD/))
- **Documentação Completa:** [DOCUMENTACAO_TECNICA_WINDOWS_FULLHD.md](windows_navi_fullHD/DOCUMENTACAO_TECNICA_WINDOWS_FULLHD.md)
- **Resolução:** 1920x1080 (Janela FullHD).
- **Desempenho Validado:** **30.0 FPS cravados** (1% piores: 30 FPS | 0.1% piores: 30 FPS), tempo de quadro perfeitamente plano em **33.3 ms**.
- **Consumo e Térmica:** GPU a frios **63 °C** com apenas **52W** de consumo (AMD Radeon RX 6750 XT).
- **Correções Gráficas:** Zero blocos cianos em Kokiri (`astc_bc = 0`), zero piscadas pretas (`replay_async = 0`) e arquivo de paginação dedicado no disco D: (`configurar_pagefile.bat`).

### 2. Linux 1440p QHD ([`port_navi/`](port_navi/))
- **Documentação Completa:** [DOCUMENTACAO_TECNICA_PORT_NAVI_V2.md](port_navi/DOCUMENTACAO_TECNICA_PORT_NAVI_V2.md)
- **Resolução:** 2560x1440 (QHD) com **AMD FSR 1** e nitidez de 80%.
- **Desempenho Alcançado:** 19 FPS contínuos e estáveis (frametime médio de **51.9 ms**, sem travamentos de shader e sem leak de VRAM).
* **Otimizações Inclusas:** `replay_async = 1` (paralelismo CPU/GPU), `low_end_gpu = 1` (submissões em lote Vulkan) e integração com o **Feral GameMode (`gamemoderun`)**.

---

## 🔺 Port Nativo para PC (Triforce Project v0.5.2 - 1080p FSR)

Com a fusão oficial do NX2navi ao projeto Triforce ([triforceproject.com](https://triforceproject.com)), o repositório inclui a suíte atualizada de scripts, configurações e guia técnico do **Triforce v0.5.2** na pasta [`port_triforce/`](port_triforce/):

* **Documentação Completa:** [DOCUMENTACAO_TECNICA_PORT_TRIFORCE.md](port_triforce/DOCUMENTACAO_TECNICA_PORT_TRIFORCE.md)
* **Novo Launcher Oficial & Benchmark:** Interface imersiva com suporte a saves, GameBanana mods e ferramenta de benchmark automático **"Find my best settings"** (sobrevoo de 2 minutos que afere métricas e calcula os ajustes ideais).
* **Resolução:** Renderização interna em 1920x1080 (Full HD) com upscaling AMD FSR por hardware via Gamescope para o monitor 1440p a 165Hz.
* **Telemetria Dupla:** MangoHud nativo do Regata OS (GPU/CPU %, temps, frequências, VRAM/RAM, gráfico de frametime) + novo contador in-game integrado com métricas completas de 1% e 0.1% lows.
* **Otimizações para RDNA 2 (RX 6750 XT):** Occlusion culling nativo (+3-5% FPS), compressão de texturas BC1, 8 workers paralelos para compilação de shaders e correção do gargalo de render pass na vegetação.
* **Injeção de Ícone:** Utilitário Python ctypes com `libX11.so.6` para suporte a ícones ARGB 32-bit (16x16 até 256x256 com canal alpha real).

---

## ⚠️ Aviso Legal
Este repositório **NÃO contém ROMs, chaves de decodificação (prod.keys) ou binários protegidos por direitos autorais**. Todos os scripts e patches destinam-se exclusivamente para fins de preservação e execução de cópias legalmente adquiridas pelo próprio usuário.
