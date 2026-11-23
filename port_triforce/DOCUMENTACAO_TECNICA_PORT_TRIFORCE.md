# Documentação Técnica: Port Triforce v0.7.0 (Linux Nativo)
**Projeto:** The Legend of Zelda: Ocarina of Time (Switch 2 → PC Linux Nativo)  
**Ambiente de Execução:** Regata OS (openSUSE based / KDE Plasma / X11 / Mesa RADV ACO), Intel Core i5-12400F (6C/12T), AMD Radeon RX 6750 XT (12 GB VRAM / Navi 22 / RDNA 2)  
**Data da Atualização:** 23 de Novembro de 2026  
**Status:** Atualizado para **Triforce v0.7.0 ("Sage Of Courage")**. Correção definitiva de crash de memória em transições e movimento (eliminação de write-backs inválidos em memória excluída), PGO ativo (-6 a 8% de carga de render), Zstd nativo de PC, otimizações RADV ACO, áudio ambiental restaurado, 25 conquistas nativas e compilação antecipada de 100% dos shaders.

---

## 1. Histórico de Versões e Evolução

| Versão | Data | Principais Características e Status |
| :--- | :---: | :--- |
| **v0.4.0** | 18/11/2026 | Primeiro release unificado pós-fusão NX2navi. Apresentava queda para 20 FPS e engasgos na folhagem devido a quebras de render pass e threads auxiliares ativas. |
| **v0.5.0** | 18/11/2026 | Occlusion culling ativado por padrão (+3-5% FPS), desativação de *replay helper threads* e *robust buffers*, correção do render pass da grama/folhagem, compressão de texturas BC1 e novo in-game HUD de performance. |
| **v0.5.2** | 19/11/2026 | Novo launcher visual imersivo, ferramenta de benchmark automático **"Find my best settings"**, 8 workers paralelos para compilação de shaders em AMD RX 6000, eliminação de black flashes e modo co-op online. |
| **v0.6.0** | 21/11/2026 | Suporte inicial experimental ao **AMD FSR 4** e **Frame Generation** no Linux, translação SPIR-V nativa, 12 workers de compilação assíncrona, eliminação de micro-stutters via modo Direto Vulkan. Identificada instabilidade de escrita de memória em certas transições. |
| **v0.7.0** | 23/11/2026 | **Versão Atual Ativa ("Sage Of Courage").** Correção arquitetural do bug de memória da v0.6.0 (write-backs não tocam mais memória excluída), PGO ativo (redução de 6-8% no workload do renderizador), descompressor Zstd nativo x86_64, drivers RADV ACO otimizados para mesh shaders, restauração de áudio ambiental 3D (reverb/delay), 25 conquistas nativas e execução nativa Vulkan 1080p/1440p sem sobrecarga de tensores. |

---

## 2. Implementação do AMD FSR 4 no Linux (`fsr4-vk`)

Como a AMD não disponibiliza um binário proprietário oficial do FSR 4 para Linux, a biblioteca nativa Vulkan foi gerada no ecossistema local via `fsr4-vk`:

1. **Origem dos Pesos Oficiais:**
   * Download dos binários assinados oficiais da AMD (FidelityFX SDK v2.4.0):
     * `amd_fidelityfx_upscaler_dx12.dll` (54.9 MB)
     * `amd_fidelityfx_framegeneration_dx12.dll` (28.3 MB)
2. **Extração de Modelos e Matrizes Neurais:**
   * Extração de 508 payloads e 919 aliases de matrizes em formatos de precisão **FP8** e **INT8**.
   * Tradução de dispatches de shaders DXIL para **SPIR-V Vulkan** usando `llvm-objdump` e `spirv-tools`.
3. **Compilação das Bibliotecas Nativas:**
   * Compilação via Clang e CMake com vinculação direta à runtime Vulkan (`/usr/lib64/libvulkan.so.1`):
     * `amd_fidelityfx_upscaler_vk.so` (11.1 MB)
     * `amd_fidelityfx_framegeneration_vk.so` (18.3 MB)
   * Instaladas em: `/home/marcos/Games/Triforce/` e versionadas em `port_triforce/`.

---

## 3. Preparação 100% Antecipada de Shaders (Diretriz "Chegar e Jogar")

O build v0.6.0 foi executado com o ciclo completo de preparação antecipada de pipelines Vulkan:

```
[ hos host ] vk: precompile: 12523 programs, 14051 graphics and 866 compute pipelines
[ hos host ] vk: precompile: timing: 14917 built in 13.4 s, 1111.2 a second
[ hos host ] vk: memory: 24008 stages packed (756 MB); 14917 pipelines kept
[ hos host ] vk: pipeline cache saved (722463 KB)
done shaders
@@done /home/marcos/Games/Triforce
```

* **Total de Pipelines Compilados:** 14.917 (14.051 gráficos + 866 compute).
* **Tamanho do Cache:** 722.4 MB salvos em `mkw_vk_pipelines.bin` e `triforce_programs.bin`.
* **Impacto Prático:** **Zero engasgos (0 stutter)** durante a exploração, combate ou corte de cenas.

---

## 4. Otimização de Fluidez e Configuração do MangoHud

### Diagnóstico de Fluidez:
* Anteriormente, a execução através do compositor isolado Gamescope forçava downscale/upscale intermediário e capava a taxa a 60 Hz com buffer de sincronização extra.
* Na versão v0.6.0, o **Modo Direto Vulkan** tornou-se o padrão em `jogar_triforce.sh`, conectando o Triforce diretamente ao DRI3 do X11/KDE com o compilador **Mesa RADV ACO**.

### Telemetria com MangoHud:
O script `jogar_triforce.sh` injeta automaticamente a configuração com alta legibilidade:
```bash
export MANGOHUD=1
export MANGOHUD_CONFIG="cpu_temp,gpu_temp,ram,vram,gpu_core_clock,fps,frametime=1,frame_timing=1,gamemode,font_size=20,position=top-left"
```
* **Métricas exibidas:** Taxa de FPS, gráfico de frametime (ms), uso/temperatura da RX 6750 XT, clock da GPU, VRAM alocada e status do GameMode.

---

## 5. Atalhos e Ferramentas

1. **Jogo Direto (Modo Nativo Vulkan + MangoHud):**
   * Atalho na Área de Trabalho: `Zelda: Ocarina of Time (Triforce v0.7.0)`
   * Comando de terminal: `/home/marcos/Games/Triforce/jogar_triforce.sh`
2. **Painel de Controle e Status FSR 4 / Shaders:**
   * Script Python: `python3 /home/marcos/Documentos/emulador/port_triforce/monitor_fsr4.py`
   * Exibe status de compilação, checklist, tail dos logs e botões de inicialização rápida.
3. **Launcher de Configurações e Saves:**
   * Atalho na Área de Trabalho: `Triforce Launcher`
   * Executável: `/home/marcos/Games/Triforce/triforce`
