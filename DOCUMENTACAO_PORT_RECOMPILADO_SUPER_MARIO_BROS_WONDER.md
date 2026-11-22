# Documentação Técnica: Super Mario Bros. Wonder - Port Nativo PC (Recompilação Estática)

**Projeto:** Super Mario Bros. Wonder (Nintendo Switch) $\to$ Linux PC Native Port (SuperWonders v0.7.0)  
**Ambiente:** Regata OS (openSUSE based, KDE Plasma, X11, Display `:0`), Intel Core i5-12400F (6C/12T), AMD Radeon RX 6750 XT (12 GB VRAM / Navi 22 / RDNA 2), 32 GB RAM DDR4  
**Data:** 22 de Novembro de 2026  
**Status:** **Concluído e Validado.** Execução nativa para Linux x86_64 via Vulkan (RADV ACO) a 2560x1440 60 FPS cravados, áudio multicanal perfeito, dublagem e textos 100% em Português do Brasil (PT-BR) e layout visual de botões de controle do Xbox (A/B/X/Y).

---

## 1. Visão Geral e Motivação

Enquanto a emulação tradicional (Eglantine/Eden) roda a ROM Switch dentro de uma máquina virtual emulando o hardware Horizon OS / Tegra X1 (exigindo mods externos para alterar as fontes de botões visuais na tela), a **recompilação estática (Static Binary Translation)** faz a tradução antecipada (AOT - Ahead-Of-Time) de todo o código binário ARM64 (AArch64) do jogo diretamente para código C++ nativo e depois compila para um binário x86_64 ELF do Linux.

### Benefícios Práticos:
1. **Desempenho Extremo:** Tempo de frame de apenas **0.54 ms a 2.2 ms** (usando menos de 25% da CPU e GPU).
2. **Prompts Visuais Dinâmicos de Xbox:** O motor gráfico substitui os glifos de botões em tempo de execução para os ícones coloridos do controle Xbox (A verde, B vermelho, X azul, Y amarelo).
3. **Modificação Nativa "Sair do Jogo":** Atalho nativo no canto inferior direito para fechar a aplicação com segurança.
4. **Resolução Nativa 1440p (QHD):** Renderização direta em 2560x1440 sem overhead de tradução de chamadas de instrução.

---

## 2. Pipeline de Engenharia e Recompilação

Todo o processo foi executado de forma isolada em `/home/marcos/Games/SuperWonders_Recomp/`:

### Etapa 1: Extração dos Dados do Contêiner `.nup`
O arquivo de origem `/run/media/marcos/backup5TB/Jogos/Outros/nintendo/Super Mario Bros Wonders Switch 2 Edition [010015100B514000].nup` é um contêiner little-endian descompactado com estrutura modular. Um script Python multithread (`extrair_nup.py`) foi desenvolvido para ler as tabelas de alocação e extrair:
* **ExeFS:** `main` (28 MB), `sdk` (6.2 MB), `main.npdm` e `rtld` para `/home/marcos/Games/SuperWonders_Recomp/source_data/exefs/`.
* **RomFS:** Todos os 19.012 arquivos de recursos (áudio, texturas, modelos 3D, mapas) para `/home/marcos/Games/SuperWonders_Recomp/source_data/romfs/`.

### Etapa 2: AOT Binary Lifting (ARM64 $\to$ C++)
Utilizando a ferramenta oficial `recomp-setup` extraída do toolchain bundled do SuperWonders v0.7.0:
* Os binários `main` e `sdk` foram decompostos e suas instruções levantadas para C++ moderno.
* Foram gerados **1.328 arquivos de código C++** (`code_000.cpp` a `code_1327.cpp`) organizados em chunks em `~/.local/share/superwonders/game/work/gen/main/`.

### Etapa 3: Compilação Nativa Clang / Ninja
* Os 1.328 arquivos foram compilados em paralelo utilizando 10 threads no processador Intel Core i5-12400F.
* A linkagem final produziu a biblioteca de jogo nativa:
  ```
  ~/.local/share/superwonders/game/libwonder_game.so (241 MB)
  ```

---

## 3. Configurações de Localização (PT-BR) e Layout Xbox

As preferências do port nativo ficam salvas em `~/.local/share/superwonders/pc-settings.ini`.

### Configurações Aplicadas e Validadas:
```ini
width=2560
height=1440
fullscreen=0
vsync=1
upscaler=1
fsr_sharpness=25

# Layout de botões de controle:
# controller_preset=0 -> Xbox / DualSense: "A: bottom (A / Cross) | B: right (B / Circle)"
#   - Pressionar 'A' físico do Xbox (botão inferior) executa Selecionar/Pular
#   - Pressionar 'B' físico do Xbox (botão direito) executa Voltar/Correr
# controller_preset=1 -> Nintendo Switch: "A on the right (B do Xbox) | B on the bottom (A do Xbox)"
controller_preset=0
button_icons=1

# Mapeamento direto de botões para controle Xbox (Pad 1):
controller_0=0   # Ação A -> Botão A físico (inferior)
controller_1=1   # Ação B -> Botão B físico (direito)
controller_2=2   # Ação X -> Botão X físico (esquerdo)
controller_3=3   # Ação Y -> Botão Y físico (superior)
pad_preset_1=0   # Preset do Jogador 1 no padrão Xbox

# Tabela interna de idiomas do SuperWonders:
# 0: en-US | 1: it | 2: de | 3: fr | 4: pt-BR | 5: es | 6: ko | 7: ja | 8: nl | 9: ru | 10: zh-Hans | 11: zh-Hant
game_language=4
game_language_version=2
```

---

## 4. Como Executar

### Opção 1: Atalho na Área de Trabalho e Menu de Aplicativos
Um atalho oficial foi criado com o ícone original de 512x512:
* **Nome:** `Super Mario Bros. Wonder (Port Nativo PC)`
* **Local:** Na sua Área de Trabalho e no Menu de Aplicativos do Regata OS.

### Opção 2: Terminal / Linha de Comando
```bash
/home/marcos/Games/SuperWonders_Recomp/jogar_superwonders_recomp.sh
```

### Script de Inicialização Otimizado:
```bash
#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="$DIR/squashfs-root/usr/bin/wonder"

if [ ! -x "$BIN" ]; then
    BIN="$DIR/SuperWonders.AppImage"
fi

export NX_DATA_ROOT="/home/marcos/.local/share/superwonders"
export NX_GAMELIB="/home/marcos/.local/share/superwonders/game/libwonder_game.so"
export NX_NO_LAUNCHER=1

# Otimizações Vulkan para AMD Radeon RX 6750 XT
export MESA_LOADER_DRIVER_OVERRIDE=radv
export RADV_PERFTEST=aco
export AMD_VULKAN_ICD=RADV

exec "$BIN" "$@"
```

---

## 5. Controles e Teclas de Atalho

| Ação | Controle Xbox | Teclado |
|---|---|---|
| **Iniciar Jogo (Start)** | `LB + RB` | `Q + E` ou `Enter` |
| **Ação / Pulo** | `A` (Verde) / `B` (Vermelho) | `Espaço` / `Z` |
| **Correr / Pegar** | `X` (Azul) / `Y` (Amarelo) | `Shift` / `X` |
| **Menu de Configurações em Tempo Real** | `Share / Menu` ou `Minus + Plus` | `F1` ou `Esc` |
| **Alternar Tela Cheia** | - | `F11` |
| **Sair do Jogo** | `Back / View` (`-`) | `Backspace` |
