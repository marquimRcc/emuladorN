# Documentação Técnica: Análise Comparativa do Port de Zelda Ocarina of Time (Navi vs. Triforce v0.7.1)

**Projeto:** The Legend of Zelda: Ocarina of Time (Switch 2 → PC Linux Nativo)  
**Ambiente de Execução:** Linux (openSUSE / Regata OS / KDE Plasma X11), Intel Core i5-12400F (6C/12T), AMD Radeon RX 6750 XT (12 GB GDDR6 / Mesa RADV RDNA 2 Navi 22)  
**Data da Análise:** 23 de Novembro de 2026  
**Status do Ciclo:** Encerrado para revisão upstream no próximo mês. Ambiente estável de referência: **Navi V2 (NX2navi v0.10.1)**.

---

## 1. Objetivo e Contexto

Avaliar a transição do port estático nativo de **The Legend of Zelda: Ocarina of Time** do ecossistema maduro **NX2navi (v0.10.1 - Navi V2)** para a nova versão unificada **Triforce (v0.7.1)**.

O projeto Triforce absorveu o desenvolvimento ativo do recompilador com a promessa de suporte contínuo, novas técnicas de renderização e automação de atualizações. O objetivo deste trabalho foi diagnosticar, estabilizar e validar o Triforce v0.7.1 no hardware corporativo/gamer do usuário (AMD Radeon RX 6750 XT com driver Mesa RADV), registrando exaustivamente todas as tentativas, causas-raiz de falhas e divergências arquiteturais entre os dois motores.

---

## 2. Arquitetura e Fluxo dos Motores

```
=============================================================================================
FLUXO ARQUITETURAL COMPARATIVO
=============================================================================================

[ NAVI V2 (NX2navi v0.10.1) - ESTÁVEL ]
  ROM .nup (v1.1.1) 
    ├──► ExeFS (ZBIC lifter) ──► 548 blocos C ──► Clang 23.1 ──► Binário nativo 'ocarina' (320 MB)
    ├──► RomFS indexado ──► 174.513 shaders pré-compilados em shader-cache.pack
    └──► Renderizador Vulkan Clássico:
           ├──► Modo Direto ou Gamescope 1440p (FSR 1 upscale de 1080p interno)
           ├──► Low-End GPU = 1 (Mesh Shaders emulados via Compute Shader)
           ├──► Replay Assíncrono Multithread (CPU prepara quadro N+1 enquanto GPU desenha N)
           └──► VRAM estável em 7.3 GB sem vazamento contínuo

[ TRIFORCE (v0.7.1) - INSTÁVEL NO LINUX MESA RADV ]
  AppImage Triforce v0.7.1 (506 MB binário unificado triforce + triforce_vk.so)
    ├──► Pipeline de Shaders Síncrono Obrigatório (42.494 pipelines previstos)
    └──► Camada de Renderização Vulkan Híbrida / Experimental:
           ├──► Módulo RenoDX HDR / Tonemapping RGBA16F integrado
           ├──► Injeção de Filtro N64 Classic CRT (Shader sawtooth)
           ├──► Gestão de Memória com Mirrors em Pedaços e Write-back Diff Dinâmico
           ├──► Hardware Mesh Shaders (VK_EXT_mesh_shader) instáveis em drivers RADV
           └──► Decodificação AV1 com Pacing forçado a 240 FPS
=============================================================================================
```

---

## 3. Fatos Confirmados (Evidências Técnicas Extraídas de Logs e Telemetria)

| Item | Fato Confirmado | Evidência Técnica (Logs / Hardware) |
| :--- | :--- | :--- |
| **F01** | **Bypass do Congelamento de Boot** | O engine original congelava por 13 minutos em `vk: start-up: predicted pipelines`. Resolvido via `RX_VK_PREDICT_S=0` (inicialização imediata em 284 ms). |
| **F02** | **Filtro CRT N64 Deformava Imagem** | Imagem apresentava textura marrom envelhecida. Resolvido via `RX_VK_N64=0`. |
| **F03** | **Clock de GPU Adormecido (93 MHz)** | O Triforce tentava escrever em `/sys/class/drm/renderD128/device/power_dpm_force_performance_level` sem permissão de root. Criada regra udev permanente (`99-amdgpu-performance.rules`) e grupo `video`/`gamemode`, permitindo travar o clock em **2.319 a 2.630 MHz** sem sudo. |
| **F04** | **Perda de Foco Bloqueava Controles** | Log: `hid: game window not in front: the controllers do not count until it is in front again`. Resolvido com `controller_in_background=1` e `HOS_INPUT_BACKGROUND=1`. |
| **F05** | **FSR 4 Inoperante no Linux** | Log: `no FSR 4 for this GPU and driver (needs AMD driver 26.10.1 or newer)`. Confirmado que FSR 4 exige driver AMD proprietário de Windows. |
| **F06** | **Cenário 3D Preto em Kokiri Forest** | Screenshot `media_1795472717435.png`: o HUD 2D (minimapa e corações) renderizava, mas a geometria 3D ficava 100% preta. Evidência: `samples the colour target it writes (read undefined where it writes)` e falha de vértices em *hardware mesh shaders*. |
| **F07** | **Gargalo Massivo de VRAM Sync** | Log: `write-back diff: 3003 runs, 1389.3 MB compared... forgetting the written pages took 11.71 ms`. Transferência de 1,4 GB pelo barramento PCIe estourando o tempo do quadro (FPS desabando para 24 FPS). |
| **F08** | **Flicker e Stalls Críticos de 500 ms** | Log da sessão final: `stall: frame 13127: 498.5 ms... the game's fence waits 462.2 ms in 2; slot wait 453.9 ms`. A renderização alternava entre frames pretos e frames de cena em loop, tornando a imagem piscante e injogável. |

---

## 4. Histórico Completo de Tentativas e Falhas no Triforce v0.7.1

### Tentativa 1: Inicialização Direta e Bypass do Freeze de Shaders
* **Problema:** O jogo levava mais de 13 minutos em tela preta antes de exibir qualquer janela.
* **Diagnóstico:** O engine alocava 12 threads para rodar uma rotina interna de `predicted pipelines` de forma síncrona no boot.
* **Ação:** Configurado `RX_VK_PREDICT_S=0` no inicializador.
* **Resultado:** Sucesso no boot inicial; a janela abriu em menos de 1 segundo.

### Tentativa 2: Eliminação do Filtro Retrô CRT N64
* **Problema:** A cena 3D inicial de Link cavalgando Epona apresentava um filtro quadriculado marrom com bordas serrilhadas.
* **Diagnóstico:** A variável interna `RX_VK_N64` estava ativa por padrão, injetando um shader CRT simulador de tubo do Nintendo 64.
* **Ação:** Injetado `export RX_VK_N64=0` e `anti-aliasing=1`.
* **Resultado:** Sucesso; o visual ficou limpo em alta definição.

### Tentativa 3: Estabilização de Clock da GPU (Fim dos 93 MHz em Repouso)
* **Problema:** A GPU ficava a 8% e 93 MHz, pois o engine não conseguia escrever o nível de performance no sysfs (`Permission denied`).
* **Diagnóstico:** `/sys/class/drm/card0/device/power_dpm_force_performance_level` pertencia a `root:root (644)`.
* **Ação:** Criado o script `setup_gpu_performance.sh` que instalou a regra udev `/etc/udev/rules.d/99-amdgpu-performance.rules` (concedendo permissão de escrita ao grupo `video`), adicionou o usuário ao grupo `gamemode` e forçou o nível `high`.
* **Resultado:** Sucesso confirmado; a RX 6750 XT subiu imediatamente para **2.319 MHz** em jogo.

### Tentativa 4: Correção de Captura de Entrada (Gamepad)
* **Problema:** O jogo chegava à tela inicial mas não respondia a nenhum clique no controle 8BitDo.
* **Diagnóstico:** O gerenciador de janelas KWin/X11 não sinalizava o foco imediatamente, e o engine bloqueava a leitura HID quando `game window not in front`.
* **Ação:** Ativado `controller_in_background=1` em `triforce_options.ini` e `export HOS_INPUT_BACKGROUND=1` no lançador.
* **Resultado:** Sucesso; o controle passou a responder na hora, permitindo selecionar o arquivo de save.

### Tentativa 5: Correção da Tela Preta 3D em Kokiri Forest
* **Problema:** Ao entrar no save e carregar Kokiri Forest, o minimapa e os corações apareciam, mas o mundo 3D estava completamente preto (`media_1795472717435.png`).
* **Diagnóstico:** 
  1. A opção `RADV_DEBUG=nodcc` desativava a compressão delta de cores, corrompendo a leitura de alvos de cor.
  2. O módulo RenoDX HDR tentava converter cores para RGBA16F sem suporte pleno no swapchain SDR do driver RADV.
  3. Os *hardware mesh shaders* (`mesh_shaders=0`) falhavam na rasterização de geometrias de mundo aberto no RDNA 2.
* **Ação:** 
  - Removido `RADV_DEBUG=nodcc`.
  - Injetado `RX_VK_RENODX=0`.
  - Definido `mesh_shaders=1` (*Compute Fallback*).
  - Ativado `texture_detail=1` e `opaque_textures_as_bc1=1`.
* **Resultado:** Disparou a compilação completa dos 42.494 pipelines.

### Tentativa 6: Compilação dos 42.494 Pipelines e Teste Final
* **Processo:** O processador executou a compilação paralela completa de todos os pipelines (atingindo mais de 765% de carga de CPU durante ~18 minutos).
* **Comportamento Observado:** Ao carregar o gameplay em Kokiri Forest, a tela começou a **flickar violentamente**, alternando entre telas pretas e flashes da cena do mapa.
* **Diagnóstico Definitivo nos Logs:**
  - O motor registrou esperas extremas de sincronização de GPU: `the game's fence waits 462.2 ms`, `slot wait 453.9 ms`, `frame 13128: 503.1 ms present to present`.
  - O pipeline de swapchain do Triforce v0.7.1 entra em *deadlock* parcial de buffers com o driver RADV ACO ao tentar alternar entre os buffers de cor do jogo e as camadas de pós-processamento, gerando o efeito de tela piscante a 2 FPS.
* **Conclusão:** O código atual do Triforce v0.7.1 possui regressão grave no subsistema de sincronização de buffers Vulkan no Linux.

---

## 5. Comparativo Técnico Aprofundado: Navi (v0.10.1) vs. Triforce (v0.7.1)

| Característica | **Navi (NX2navi v0.10.1 - Navi V2)** | **Triforce (v0.7.1)** | Impacto Prático no Usuário |
| :--- | :--- | :--- | :--- |
| **Estabilidade Geral** | **100% Funcional e Estável** | Instável / Regressão no Linux | Navi joga normalmente; Triforce flicka e congela. |
| **Pipeline de Shaders** | 174.513 shaders pré-compilados em `shader-cache.pack`. | 42.494 pipelines compilados em runtime/boot. | Navi abre sem demoras; Triforce exige compilação massiva. |
| **Renderização 3D** | Rasterização Vulkan limpa e compatível com RDNA 2. | Camada RenoDX + Mesh Shaders instáveis no RADV. | Navi renderiza floresta, luzes e Link; Triforce gera tela preta/flicker. |
| **Consumo de VRAM** | Estabilizado em **7.3 GB** (sem leak). | Dispara para **7.8 a 9.2 GB** com picos em 10+ GB. | Triforce satura o barramento PCIe e gera stutters. |
| **Replay Multithread** | `replay_async = 1` nativo e funcional. | Sincronização síncrona pesada (`memory sync` a 11 ms). | Navi entrega frametime liso; Triforce tem picos de 500 ms. |
| **Controle de Janela** | Gamescope 1440p integrado com isolamento total. | Execução direta sem Gamescope. | Gamescope protege a sessão KDE de travar o desktop. |
| **Compatibilidade Linux** | Projetado e polido para Mesa / Linux. | Foco primário em Windows / Drivers AMD proprietários. | O Triforce tenta usar recursos incompatíveis com o Mesa RADV. |

---

## 6. Causas Descartadas e Hipóteses

### Causas Descartadas:
1. **Defeito ou Limitação de Hardware:** A GPU RX 6750 XT possui 12 GB de VRAM e suporte total a Vulkan 1.4 / RDNA 2; a CPU i5-12400F manteve 60 FPS cravados no Navi V2. O problema é puramente de software no backend do Triforce.
2. **Corrupção de Save:** Os arquivos de save são idênticos em estrutura entre as duas versões (`caption.sav`, `progress.sav`, `option.sav`) e carregaram sem erros de deserialização.
3. **Falta de Dependências do Sistema:** Todas as bibliotecas de sistema (`libdav1d`, `libvulkan`, `libSDL3`, `libzstd`) estão atualizadas e presentes no sistema.

### Hipótese Principal Confirmada:
* O backend Vulkan do Triforce v0.7.1 reestruturou a cadeia de apresentadores de imagem (*swapchain presentation queue*) para acomodar o FSR 4 e novos tonemappers de Windows. Essa reestruturação quebrou o modelo de sincronização assíncrona com o compilador ACO do Mesa RADV, provocando contenção de cercas (*fence contention*) de até 462 ms por quadro.

---

## 7. Decisão Operacional e Próximos Passos

1. **Suspensão Temporária de Testes no Triforce v0.7.1:**  
   Não insistir em correções manuais no código binário do v0.7.1, aguardando que os desenvolvedores upstream lancem a próxima revisão corretiva (v0.7.2 ou superior) com foco em correções para Mesa/Linux.
2. **Ambiente em Uso:**  
   Manter como atalho ativo o **Zelda: Ocarina of Time (Navi V2 - 1440p)** em `/home/marcos/Games/Navi_V2/`, onde a experiência de jogo está fluida e validada.
3. **Revisão no Próximo Mês:**  
   No próximo ciclo, verificar os commits e releases do repositório oficial do Triforce procurando especificamente por:
   - *"fix(vulkan): swapchain fence deadlock on Mesa RADV"*
   - *"fix(render): Linux RDNA2 presentation stutter"*
   - *"fix: headless/SDR tonemapping fallback"*

---

*Documento gerado automaticamente e registrado no repositório de controle de versão.*
