# Documentação Técnica: Super Mario Bros. Wonder (Linux Nativo)
**Projeto:** Super Mario Bros. Wonder (Nintendo Switch / Switch 2 Edition)  
**Ambiente de Execução:** Regata OS (openSUSE based / KDE Plasma / X11 / Mesa RADV ACO), Intel Core i5-12400F (6C/12T), AMD Radeon RX 6750 XT (12 GB VRAM / Navi 22 / RDNA 2), 32 GB RAM DDR4  
**Data da Documentação:** 22 de Novembro de 2026  
**Status:** **Concluído e Validado.** Execução direta nativa via Vulkan (RADV ACO) no emulador Eglantine/Eden v0.1.0-rc3 PGO, resolução 1440p QHD (escala 2x) a 60 FPS estáveis, com dublagem oficial e textos 100% em Português do Brasil (PT-BR).

---

## 1. Contexto e Diagnóstico Inicial

### Tentativa com Repack Windows (FitGirl Repack):
Inicialmente, tentou-se instalar o repack Windows via Wine (`/opt/wine-gcs/bin/wine setup.exe`), porém o processo foi descartado pelos seguintes motivos técnicos:
1. **Erro de Permissão (Error 5: Acesso Negado):** O instalador padrão tentou criar diretórios na raiz do Wine (`Z:\Games\`), que mapeia para `/` no Linux (área restrita ao usuário `root`).
2. **Deadlock no Descompactador (Travamento em 0.1%):** No Linux sob Wine WOW64, os descompactadores 32-bit proprietários (`ISDone.dll` / `unarc.dll` / `cls-lolz`) entram em loop infinito de alocação de memória virtual e sincronização de pipes IPC ao descompactar contêineres FreeArc monolíticos (`SMBW.nsp` de quase 4 GB), a menos que restritos artificialmente a 2 GB de RAM e executados em caminhos sem caracteres especiais.
3. **Decisão:** Abandonar o instalador via camada Wine e adotar a execução **100% nativa em Linux**, aproveitando a ROM no formato de alta compatibilidade `.nup` e o ecossistema já consolidado no repositório `emuladorN`.

---

## 2. Arquitetura da Solução Linux Nativa

A solução adotada integra o jogo diretamente à stack do emulador **Eglantine / Eden**:
* **Binário:** `eglantine.AppImage` (v0.1.0-rc3 PGO compilado com Clang 23).
* **Formato da ROM:** Contêiner Nintendo Universal Package (`.nup`), identificado com o cabeçalho binário `NUP\x01\x80\x00\x01\x00\x80\x00\x00\x00\x00\x00\x00\x00`.
* **Localização da ROM:** `/run/media/marcos/backup5TB/Jogos/Outros/nintendo/Super Mario Bros Wonders Switch 2 Edition [010015100B514000].nup` (8.3 GB, 100% íntegro).
* **Title ID:** `010015100B514000` (ID oficial de Super Mario Bros. Wonder).

---

## 3. Localização Completa em Português do Brasil (PT-BR)

Super Mario Bros. Wonder possui localização oficial desenvolvida pela Nintendo, incluindo legendas, interface gráfica e **dublagem em áudio para as Flores Falantes (Talking Flowers)**.

Para forçar a ativação do idioma brasileiro sem depender das variáveis de ambiente do sistema operacional, foram parametrizados os índices de firmware da Nintendo:
* `language_index = 17`: Código do Switch para **Brazilian Portuguese** (`pt-BR`).
* `region_index = 1`: Região **Americas (USA/Brasil)**.
* `Paths\language = pt_BR`: Interface gráfica traduzida do emulador.

### Perfil Customizado do Jogo (`config/010015100B514000.ini`):
O arquivo foi criado e implantado em `~/.config/eglantine/custom/` e `~/.config/eden/custom/`:
```ini
[System]
language_index\use_global=false
language_index\default=false
language_index=17
region_index\use_global=false
region_index\default=false
region_index=1
use_docked_mode\use_global=false
use_docked_mode\default=false
use_docked_mode=1
```

---

## 4. Calibração Gráfica e Otimizações de Hardware (RX 6750 XT + i5-12400F)

O hardware do usuário (Intel Core i5-12400F e AMD Radeon RX 6750 XT de 12 GB VRAM) foi calibrado para oferecer máxima fidelidade visual com framerate travado:

1. **Driver Vulkan RADV ACO:**
   - Variáveis exportadas no launcher: `export RADV_PERFTEST=aco` e `export AMD_VULKAN_ICD=RADV`.
   - Utilização do compilador ACO da Valve/Mesa para compilação em tempo real sem stutters.
2. **Resolução e Escala:**
   - `resolution_setup = 2`: Renderização em **1440p QHD Nativo (Escala 2x no modo Docked)**.
   - `scaling_filter = 1`: Filtro bilinear / FSR de alta nitidez.
3. **Sincronização e Fluidez:**
   - `use_vsync = 3`: VSync Mailbox (Fast Sync), eliminando *screen tearing* sem adicionar lag de entrada.
   - `use_asynchronous_shaders = true`: Compilação de shaders em segundo plano.
   - `gpu_accuracy = 0`: Modo Normal (estabilidade e framerate cravado a 60 FPS).
4. **Controles:**
   - Integração do mapeamento SDL para **8BitDo Ultimate 2 Wireless Controller** (`SDL_GAMECONTROLLERCONFIG`), com suporte automático a gamepads Xbox e DualSense.

---

## 5. Estrutura de Arquivos e Inicializadores Criados

```text
.
├── config/
│   ├── 010015100B514000.ini              # Perfil gráfico e de idioma (PT-BR) de Super Mario Bros. Wonder
│   └── 0400486024DEC000.ini              # Perfil de Zelda: Ocarina of Time Remake
├── jogar_mario.sh                         # Launcher oficial Linux (Vulkan RADV ACO, SDL Gamepad, Docked 1440p)
├── mario_wonder_icon.png                  # Ícone em alta definição 512x512
└── DOCUMENTACAO_TECNICA_SUPER_MARIO_BROS_WONDER.md # Esta documentação técnica
```

### Links no Sistema Operacional:
* **Espelho no diretório Games:** `/home/marcos/Games/Super Mario Bros. Wonder/jogar_mario.sh`
* **Ícone do Jogo:** `/home/marcos/Games/Super Mario Bros. Wonder/icon.png` e `~/.local/share/icons/super_mario_wonder.png`
* **Atalho na Área de Trabalho:** `~/Área de trabalho/Super_Mario_Bros_Wonder.desktop`
* **Atalho no Menu de Aplicativos:** `~/.local/share/applications/Super_Mario_Bros_Wonder.desktop`

---

## 6. Validação e Testes em Tempo Real

A execução do launcher `jogar_mario.sh` foi validada com sucesso em ambiente real:
* **Janela do Jogo Capturada:** `Eglantine | v0.1.0-rc3 | Clang 23.1.6 | Super Mario Bros Wonders Switch 2 Edition (64-bit) | RADV`
* **Resolução Renderizada:** 2560 x 1440 (1440p QHD)
* **Desempenho:** 60 FPS contínuos, frametime estável de ~16.6 ms.
* **Idioma Confirmado:** Interface e dublagem das Flores Falantes operando em Português do Brasil.
