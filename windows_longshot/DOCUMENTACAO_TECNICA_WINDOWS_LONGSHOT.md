# Documentação Técnica: Longshot 3.0 no Windows (AMD Radeon RX 6750 XT)

> **Data de Atualização:** 19 de Novembro de 2026  
> **Hardware de Validação:** AMD Radeon RX 6750 XT (12 GB VRAM, RDNA 2, driver 26.11.2) • Intel Core i5-12400F (6C / 12T) • 32 GB RAM DDR4 • Windows 11 64-bit  
> **Projeto:** The Legend of Zelda: Ocarina of Time (Nintendo Switch 2 Remake -> PC Nativo via Longshot 3.0 Vulkan)

---

## 1. Visão Geral da Arquitetura

O **Longshot 3.0** é um motor de execução nativa para PC que recompila o binário AArch64 (Switch 2) em instruções x86_64 nativas e traduz a API de renderização **NVN / NVN2** para **Vulkan 1.4**. 

Diferente de um emulador interpretado convencional, o Longshot gera pipelines gráficos Vulkan e shaders SPIR-V nativos, armazenando-os em caches locais persistentes:
- `mkw_vk_pipelines.bin`: Cache binário dos pipelines gráficos compilados pelo driver Vulkan.
- `longshot_programs.bin`: Cache das chaves de programas e shaders AArch64/NVN.
- `longshot_options.ini`: Parâmetros de resolução, limites de VRAM, escalonamento e mapeamento de periféricos.

---

## 2. Histórico de Problemas Diagnosticados e Soluções

### Problema A: Ícone do Atalho Quebrado / Corrompido no Windows Explorer

- **Sintoma:** Ao criar o atalho para a Área de Trabalho, o ícone aparecia distorcido, preto ou com miniatura genérica do sistema.
- **Investigação Técnica:**
  - O arquivo `.ico` gerado inicialmente gravava apenas fluxos PNG em todas as resoluções (16x16, 32x32, 48x48, 64x64, 128x128, 256x256).
  - O subsistema Shell e a biblioteca `User32 / GDI+` do Windows suportam PNG dentro do contêiner `.ico` **exclusivamente para a resolução 256x256**.
  - Para tamanhos menores (32x32 e 48x48 usados pelo desktop do Windows), o `LoadImage` / `CreateIconFromResourceEx` exige cabeçalho de bitmap **DIB (BITMAPINFOHEADER 40 bytes) 32-bit BGRA com máscara AND de 1-bit**.
  - A tentativa de leitura gerava a exceção GDI+: `Intervalo solicitado ultrapassa o fim da matriz` (`IndexOutOfRangeException`).
- **Solução Implementada:**
  - Reconstruído o compilador de ícone nativo (`NativeIcoGenerator`) gerando DIBs puros descompactados de 32bpp com canal alfa para 16, 32, 48, 64 e 128 px, e reservando PNG apenas para 256 px.
  - Tamanho final do ícone calibrado em 161.558 bytes, com 100% de compatibilidade e aprovação em testes de carregamento do Explorer.

---

### Problema B: Água Branca Estourada e 26.346 Draws Descartados (Kokiri Forest)

- **Sintoma:** Ao carregar Kokiri Forest, o lago e o rio apareciam com branco puro cegante (saturado a 1.0) e o log indicava `Draws left out (4 s) 26346`.
- **Investigação Técnica:**
  - O Switch armazena texturas de água, reflexos e mapas normais no formato **ASTC**.
  - O motor utiliza compilação assíncrona de shaders. Com `compile_shaders=0` e `RX_VK_PRECOMPILE=0`, os pipelines Vulkan não estavam prontos quando o quadro começou a ser desenhado.
  - Para evitar congelamento na inicialização, o motor **descartava os draws calls não compilados** (26.346 draws pulados em 4 segundos).
  - Como o passe de *Tone Mapping* (ACES) e os passes de malha de água foram pulados, a iluminação HDR crua foi enviada diretamente para o framebuffer SDR, saturando os canais para branco puro.
- **Solução Implementada:**
  - Ativado `RX_VK_PRECOMPILE=1` e `compile_shaders=1`, garantindo que os pipelines de pós-processamento, tone mapping e água estejam pré-aquecidos.
  - O arquivo de cache `mkw_vk_pipelines.bin` acumulou os pipelines compilados (42 MB), zerando os draws descartados (`0.0 draws left out`).

---

### Problema C: Queda Severa da Taxa de Quadros para 2 FPS

- **Sintoma:** O jogo entrava em engasgos brutais, caindo para 2 FPS e frametimes acima de 120 ms.
- **Investigação Técnica via Log:**
  1. `RX_VK_PIPE_SKIP=0`: Forçava o thread principal do jogo a esperar sincronamente por qualquer pipeline pendente (`0.32 waits for shaders or pipelines: 100.6 ms`).
  2. `RX_VK_ASTC_RGBA8=1`: Forçava a descompactação integral de **todas** as texturas do jogo para 32-bit RGBA8 sem compressão. Isso elevou o uso de memória do processo para **12,36 GB de RAM** e 5 GB de VRAM.
  3. O comparador de memória hóspede precisava escanear e diferenciar **3,39 GB de buffers a cada 600 envios de comandos** (`write-back diff: 5455 runs, 3393.6 MB compared`). A CPU Intel i5-12400F atingia 100% de uso apenas calculando diffs na memória, estrangulando o framerate.
- **Solução Implementada:**
  - Removido `RX_VK_PIPE_SKIP=0` para permitir compilação assíncrona multithread sem travar a CPU.
  - Desativado o modo pesado `RX_VK_ASTC_RGBA8=1`. O cache de texturas voltou ao teto seguro (~3,5 GB RAM), eliminando o diff massivo de 3,4 GB.

---

### Problema D: Tela Preta Congelada a 27 FPS na Transição de Mapa

- **Sintoma:** Ao carregar o jogo, a tela permanecia preta estática com contador em 27 FPS.
- **Investigação Técnica via Log:**
  - A flag experimental `RX_VK_ASTC_BC7=1` tentava recodificar texturas ASTC 1365x1365 para BC7 em tempo real. No driver proprietário da AMD, isso gerou falha catastrófica de alocação de visualizações de textura (`vk: texture slot 0xa88: no image for it`).
  - Sem imagens válidas, o renderizador paralisou por 119 segundos (`slow submit: 119711.2 ms`) e entrou em espera mútua na apresentação (`RX_VK_PRESENT_THREAD=1` e `RX_VK_BATCH=1`).
- **Solução Implementada:**
  - Expurgadas todas as flags experimentais instáveis (`RX_VK_ASTC_BC7`, `RX_VK_PRESENT_THREAD`, `RX_VK_BATCH`, `RX_VK_UNEVEN_RGBA8`).
  - Retorno ao pipeline padrão estável com Vulkan puro.

---

## 3. Configuração Final Validada

### Variáveis de Ambiente no Batch (`jogar_zelda_longshot.bat`)
```bat
set SDL_JOYSTICK_ALLOW_BACKGROUND_EVENTS=1
set AMD_VULKAN_ICD=1
set HOS_REALTIME_STEP=1
set HOS_DYNRES=0
set RX_VK_PACE=1
set RX_VK_ANTILAG=1
set RX_VK_PRECOMPILE=1
set RX_VK_COMPILE_SHADERS=1
set LONGSHOT_PRIORITY=High
```

### Configurações Gráficas Críticas (`longshot_options.ini`)
```ini
output_res=1920x1080
resolution=1
preset=4
vram_budget=4
compile_shaders=1
fps_counter=1
amd_anti-lag_2=1
frame_pacing=1
astc_as_rgba8=0
astc_rgba8=0
```

---

## 4. Resultados Medidos em Telemetria (Kokiri Forest)

| Métrica | Antes (Instável) | Depois (Otimizado) |
|---|---|---|
| **Taxa de Quadros (FPS)** | 2 ~ 27 FPS (com quedas) | **60.0 FPS** (cravado) |
| **Tempo de GPU por Quadro** | 37.9 ms | **0.82 ms** |
| **Draws Perdidos / 4s** | 26.346 descartados | **0.0 descartados** |
| **Uso de Memória RAM** | 12,36 GB (estrangulamento) | **~3,5 GB** (estável) |
| **Tempo de Replay Vulkan** | 127 ms | **5.04 ms** |
| **Pipelines em Cache** | 0 KB (recompilação contínua) | **42 MB** pré-compilados |
