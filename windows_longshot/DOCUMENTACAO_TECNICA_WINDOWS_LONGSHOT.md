# Documentação Técnica: Port Longshot (Windows FullHD 1080p)
**Projeto:** The Legend of Zelda: Ocarina of Time (Nintendo Switch 2 / NUP `0400486024DEC000` → PC Windows Nativo)  
**Emulador / Port:** Longshot (Team MagicBean v1.0.0-rc.3 / LongshotBuilder v3.0.0-rc)  
**Ambiente de Execução:** Windows 11 Pro 64-bit, Intel Core i5-12400F, AMD Radeon RX 6750 XT (12 GB VRAM / RDNA2), 32 GB RAM DDR4  
**Base de Conhecimento:** Histórico de commits e benchmarks validados em [emuladorN](https://github.com/marquimRcc/emuladorN)  
**Data:** 13 de Novembro de 2026  

---

## 1. Contexto e Transição

O projeto **Longshot** (evolução direta do Hookshot pelo Team MagicBean) é uma infraestrutura de recompilação estática nativa que converte o código AArch64 de *The Legend of Zelda: Ocarina of Time* em instruções nativas x86_64 com renderizador Vulkan de alto desempenho.

Este documento consolida a transposição dos testes práticos e correções refinadas nos commits do repositório `emuladorN` (especialmente os commits `386c8e0`, `2315941` e `cc451a6`) para a arquitetura de configuração do Longshot (`longshot_options.ini`).

---

## 2. Mapeamento das Configurações dos Commits para o Longshot

| Parâmetro Técnico | NX2navi / Commits Anteriores | Longshot (`longshot_options.ini`) | Motivação Técnica / Evidência dos Commits |
| :--- | :--- | :--- | :--- |
| **Resolução de Saída** | `output_res = 1920x1080` | `output_res=1920x1080` | Resolução FullHD nativa em janela, perfeita para o display. |
| **Resolução de Renderização** | `render_scale = 100` / `Res1X` | `resolution=1` (100% Native) | Evita a perda de fidelidade de `Scale: 0.5x` corrigida no commit `cc451a6`. |
| **Resolução Dinâmica (DRS)** | Desativada via IPS32 patch | `HOS_DYNRES=0` | Impede que o jogo reduza dinamicamente a contagem de pixels internos. |
| **Upscaler / Nitidez** | FSR 1 80% (`upscaler=fsr`) | `dlss=3` (AMD FSR 3.1) / `sharpness=80` | Aplica o filtro espacial/temporal com nitidez em 80% sem o custo excessivo de DLAA. |
| **Frame Generation** | Desativado (`framegen=off`) | `frame_generation=0` (Off) | Evita judder, oscilações térmicas e latência indesejada documentadas no commit `50d31b3`. |
| **Cadência de Quadro** | `step_steady=1` / `realtime=1` | `frame_pacing=1` / `realtime=1` | Mantém a linha de frametime estável e horizontal (33.3 ms sem engasgos). |
| **Sincronização Vertical** | `use_vsync=3` / `vk_present=fifo` | `vsync=1` | Elimina screen tearing e sincroniza com a taxa de atualização do monitor. |
| **Teto de VRAM / Budget** | `low_end_gpu=1` / 6.2 GB pool | `preset=4` / `vram_budget=4` | **Crítico:** No commit `386c8e0`, sem limite de VRAM o uso saltou para 10.4 GB gerando queda para 12 FPS por PCIe thrashing. O preset High 12GB segura o consumo em ~6.2 GB. |
| **Compressão ASTC** | `astc_bc=1` (perfil estável) | `astc_rgba8=0` | Mantém as texturas sob alocação controlada para não estourar os 12 GB da RX 6750 XT. |
| **Latência AMD** | RADV low latency | `antilag=1` | Ativa o AMD Anti-Lag 2 diretamente no pipeline Vulkan da GPU. |
| **Filtragem Anisotrópica** | `aniso=16` | `anisotropy=4` (16x) | Garante nitidez máxima em texturas em ângulos oblíquos (chão, grama, caminhos). |
| **Controles** | `pad_layout=xbox` | `pad_layout=1` / `prompts=1` | Mapeamento nativo Xbox/PC (A=baixo, B=direita, X=esquerda, Y=cima) e botões visuais Xbox. |
| **Captura em Segundo Plano** | `SDL_JOYSTICK_ALLOW_BACKGROUND_EVENTS=1` | `controller_in_background=1` | Permite alternar de janela sem perder a resposta do controle. |
| **Idioma** | `lang=pt-BR` / `locale=pt_BR` | `game_lang=8` / `menu_lang=8` | Interface e legendas do jogo em Português do Brasil. |

---

## 3. Arquivo de Configuração Consolidado (`longshot_options.ini`)

Localizado em:
- `C:\Users\marcos\Games\Longshot\longshot_options.ini`
- `C:\Users\marcos\Documents\PC\emuladorN\windows_longshot\longshot_options.ini`

```ini
[display]
output_res=1920x1080
resolution=1
fullscreen=0
ultrawide=0
handheld_profile=0

[graphics]
preset=4
vram_budget=4
upscaling=0
dlss=3
sharpness=80
frame_generation=0
frame_pacing=1
vsync=1
antilag=1
anisotropy=4
astc_rgba8=0

[performance]
frame_rate_cap=0
realtime=1
compile_shaders=0

[gameplay]
show_fps=1
fps_corner=0
skip_opening=0
game_lang=8
menu_lang=8

[controls]
pad_layout=1
prompts=1
rumble=1
controller_in_background=1
mouse_camera=0
```

---

## 4. Estrutura de Pastas e Execução

- **Pasta da ROM:**  
  `E:\outros\nintendo\zelda\The Legend of Zelda Ocarina of TIme [04004860224DEC000].nup`
- **Instalação do Emulador / Launcher Longshot:**  
  `C:\Users\marcos\Documents\emulador\longshot\LongshotLauncher.exe`
- **Launcher Otimizado em 1 Clique:**  
  `C:\Users\marcos\Documents\PC\emuladorN\windows_longshot\jogar_zelda_longshot.bat`
- **Importação de Saves:**  
  O Longshot Launcher detecta e importa saves existentes tanto do **NX2navi** (`E:\outros\nintendo\zelda\Zelda_Ocarina_Navi_PC\profile\saves`) quanto do **Hookshot** automaticamente através da tela *Manage Saves*.

---

## 5. Cuidados com Memória Virtual (Windows 11)

Conforme documentado no incidente resolvido pelo script `configurar_pagefile.bat` no repositório:
- O jogo mapeia ~24 GB de endereçamento virtual. Em sistemas Windows com arquivo de paginação restrito no disco C:, pode ocorrer timeout do driver de vídeo (`VK_ERROR_DEVICE_LOST`).
- Mantenha ativo o pagefile dedicado de **16.384 MB a 32.768 MB** no disco `D:\` (`configurar_pagefile_d.ps1`) para imunidade completa a estouro de commit.

---

## 6. Resultados Práticos de Validação em Jogo (Kokiri Forest)

Com a compilação nativa concluída e o cache Vulkan de 1,49 GB gerado, o jogo foi validado em execução real com a telemetria em nível Desenvolvedor (`fps_counter=5`):

| Métrica de Desempenho | Valor Medido | Avaliação Técnica |
| :--- | :---: | :--- |
| **Taxa de Quadros (FPS)** | **47 FPS** | Fluidez excelente, muito acima dos 20 FPS do motor original |
| **Tempo de Quadro (Frametime)** | **25.8 ms** | Linha perfeitamente plana entre 16,7 ms e 33 ms no gráfico |
| **1% Low (Piores Quadros)** | **31 FPS** | Zero quedas abaixo de 30 FPS nos piores momentos de render |
| **Tempo de CPU (Game)** | **6.6 ms** | Baixo overhead de lógica de jogo no Core i5-12400F |
| **Tempo de Renderizador** | **18.4 ms** | Submissão de comandos Vulkan otimizada |
| **Tempo Real da GPU** | **16.2 ms** | GPU trabalhando com folga na RX 6750 XT |
| **GPU Wait** | **0.1 ms** | Fila de render quase sem ociosidade |
| **Frame Pacing** | **0.7 ms** | Cadência de apresentação uniforme sem screen tearing |
| **Shaders Built (últimos 4s)** | **0** | **Zero stuttering**: todos os 25.344 pipelines pré-compilados |
| **Consumo de VRAM** | **8.9 GB / 10.6 GB** | Seguro: 1,7 GB de folga abaixo do teto de 10,6 GB |
| **Pool de Texturas** | **1.184 (2.7 GB)** | Texturas sob controle, sem PCIe thrashing |
| **Idioma & Interface** | **Português (BR)** | Textos e comandos visuais calibrados ("Saltar [Y]") |

---

## 7. Atalhos e Navegação em Jogo

- **`F1` / `Insert` / `Esc`:** Abre e fecha o menu interno de ajustes gráficos, áudio e controles em tempo real.
- **`Q` / `E`:** Alterna entre as abas do menu (`Gráficos`, `Áudio`, `Jogo`, `Controles`, `Debug`).
- **`RShift` (Shift Direito):** Alterna para o menu compacto de telemetria.
- **Aba `Jogo` $\to$ `Contador de FPS`:** Ajusta o nível de telemetria na tela (`FPS`, `Tempo de quadro`, `Gráfico`, `Detalhado`, `Desenvolvedor`).
- **`Ctrl + Shift + O`:** Ativa o overlay global de métricas térmicas e elétricas do driver **AMD Adrenalin**.
