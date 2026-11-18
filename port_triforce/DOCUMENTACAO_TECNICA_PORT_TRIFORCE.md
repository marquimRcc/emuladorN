# Documentação Técnica: Port Triforce v0.4.0 (Triforce Project - Linux Nativo)
**Projeto:** The Legend of Zelda: Ocarina of Time (Switch 2 → PC Linux Nativo)  
**Ambiente de Execução:** Regata OS (Linux x86_64 / KDE Plasma / X11 / Gamescope), Intel Core i5-12400F (6C/12T), AMD Radeon RX 6750 XT (12 GB VRAM / Mesa RADV Navi 22 / ACO)  
**Data:** 18 de Novembro de 2026  
**Status:** Implantado, compilado, integrado e validado (Full HD 1080p com upscale FSR no Gamescope, MangoHud nativo, telemetria in-game e ícone oficial multi-resolução)

---

## 1. Objetivo & Contexto
Com a fusão oficial do projeto **NX2navi** ao ecossistema unificado **Triforce** ([triforceproject.com](https://triforceproject.com)), foi lançado o release `Triforce-v0.4.0-linux-test-x86_64.AppImage`.
O objetivo desta etapa foi implantar de forma isolada e limpa o ambiente **Triforce v0.4.0** em `/home/marcos/Games/Triforce/`, mantendo 100% intactos os ambientes legados (`/home/marcos/Games/Navi/` e `/home/marcos/Games/Navi_V2/`), aproveitando todos os ativos já extraídos e ajustando o pipeline para máxima estabilidade e fluidez.

---

## 2. Arquitetura e Aproveitamento de Recursos
Para evitar consumo redundante de armazenamento (que exigiria dezenas de gigabytes adicionais), adotou-se arquitetura de reaproveitamento de ativos:

```
[ ROM / Repositório Existente ]
         │
         ├──► RomFS (26.2 GB / 186.583 arquivos) ──► Reuso imediato via Hardlinks (0 bytes extras de disco)
         │
         ├──► ExeFS (Build e0f3ccfa) ──────────────► Descompactado e vinculado ao diretório do Triforce
         │
         ├──► Clang Object Cache ──────────────────► 137 arquivos .o reaproveitados em ~/.cache/triforce-build/
         │
         ├──► Lifter C + Clang 23.1 ──────────────► 71 arquivos C gerados (108s) e compilados com -march=x86-64-v3 -O1
         │
         ├──► Binário Final Linkado ───────────────► /home/marcos/Games/Triforce/bin/triforce (533 MB) + triforce_vk.so (12.2 MB)
         │
         └──► Cache de Pipelines Vulkan ───────────► 15.022 pipelines pré-compiladas em triforce_pipelines.bin (380 MB)
```

---

## 3. Telemetria e Monitoramento

### A. MangoHud Nativo do Regata OS
* **Integração:** Injetado via variável de ambiente `MANGOHUD=1` e wrapper `gamemoderun mangohud` no inicializador [`jogar_triforce.sh`](jogar_triforce.sh).
* **Métricas Ativas:**
  - GPU: % uso, clock (`MHz`), temperatura (`°C`)
  - CPU: % uso, frequência (`MHz`), temperatura (`°C`)
  - VRAM e RAM em GiB
  - Motor gráfico (Vulkan) com FPS e Frametime em `ms`
  - Nome do dispositivo: `AMD Radeon RX 6750 XT`
  - Gráfico de frametime contínuo (linha verde)
  - Status do GameMode: `GAMEMODE ON`
  - Atalho de alternância: `Shift Direito + F12`.

### B. Contador de FPS Nativo do Recompilador
* **In-Game HUD:** Ativado via `fps_counter=1` no arquivo [`triforce_options.ini`](triforce_options.ini) ou via menu in-game (`F1` / `Insert` -> aba **Display** -> **FPS counter: On**).
* Exibe os dígitos oficiais do HUD de Ocarina of Time no canto superior direito da tela sem impacto de desempenho.

---

## 4. Análise de Upscaling: FSR 3.1 vs. FSR 4

| Tecnologia | Status no Triforce v0.4.0 | Detalhes Técnicos |
| :--- | :---: | :--- |
| **AMD FSR 3.1 (Upscaler)** | **100% Nativo** | Passes de computação SPIR-V compilados diretamente no motor (`vk_fsr3.cpp`), sem dependência de bibliotecas externas. Suporta câmera jitter e reconstrução temporal. |
| **AMD FSR 3.1 (Frame Gen)** | **Disponível / Experimental** | Presente em `vk_fsr3fi.cpp`. **Atenção:** Apresenta bug conhecido de acúmulo de submissões na fila Vulkan (`queue submit > 30ms`), podendo congelar em 2 FPS no Linux/RADV. Desativado por padrão para estabilidade. |
| **AMD FSR 4** | **Suportado via Gancho** | Infraestrutura completa programada em `vk_fsr4.cpp`. Aguarda liberação do binário compilado pela AMD (`amd_fidelityfx_upscaler_vk.so`). Sem o binário, o jogo recorre automaticamente ao FSR 3.1. |
| **Gamescope FSR** | **Ativo e Otimizado** | Flag `-F fsr` executada pelo compositor Gamescope por hardware, realizando o upscale nítido de 1080p para a resolução nativa de 1440p do monitor a 165Hz com latência zero. |

---

## 5. Injeção de Ícone Multi-Resolução em X11 (ctypes)

### O Problema:
O utilitário padrão `xprop -set _NET_WM_ICON` trunca propriedades que excedam 64 elementos por linha de comando. Como o ícone oficial em alta resolução do Triforce possui centenas de milhares de valores inteiros, o X11 descartava a imagem, deixando a janela e a barra de tarefas do KDE com ícone genérico ou transparente.

### A Solução:
Desenvolveu-se o script [`set_game_icon.py`](set_game_icon.py) utilizando `ctypes` para comunicação direta com a biblioteca de baixo nível `libX11.so.6`:
* **Resoluções Injetadas:** 16x16, 24x24, 32x32, 48x48, 64x64, 128x128 e 256x256 em um único vetor contíguo de `CARDINAL` ARGB (com canal alpha real).
* **Loop de Liveness:** Monitora a criação da janela do Gamescope por até 15 segundos após o disparo, garantindo aplicação confiável mesmo em partidas frias.
* **Integração KDE:** Arquivos `.desktop` instalados em `~/.local/share/applications/` associando `WM_CLASS="gamescope"` ao logotipo oficial [`triforce.png`](triforce.png).

---

## 6. Procedimentos de Execução

### Modo Gamescope Recomendado (1080p FSR / 60Hz):
```bash
/home/marcos/Games/Triforce/jogar_triforce.sh
```

### Modo Direto (Sem Gamescope / Janela KDE):
```bash
/home/marcos/Games/Triforce/jogar_triforce.sh --direct
```

---

## 7. Próximos Passos & Recomendações
1. **Monitoramento Upstream do FSR 4:** Acompanhar repositório oficial do Triforce Project para obter a biblioteca `amd_fidelityfx_upscaler_vk.so` assim que disponibilizada para Linux.
2. **Correção do Frame Generation:** Monitorar releases subsequentes do Triforce que desacoplem o render do HUD do pipeline de interpolação, permitindo ativar o Frame Gen 2x sem gargalo de fila Vulkan.
