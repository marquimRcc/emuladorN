# Registro Técnico: Desempenho, Patches e Ajustes Gráficos
**Jogo:** The Legend of Zelda: Ocarina of Time (Nintendo Switch 2 / Remake)  
**Title ID:** `0400486024DEC000` | **Build ID (main):** `E0F3CCFAF50065AE4EA01EB5AEB13B1A45DA3348`  
**Emulador Principal:** Eglantine v0.1.0-rc3 PGO (`eglantine.AppImage`)  
**Ambiente:** Linux (Regata OS), Vulkan RADV (AMD Radeon RX 6700 XT)  
**Última Atualização:** 12/11/2026 (Diagnóstico e Correção de Fluidez)  

---

## 1. Causa Raiz da Fluidez "Travada" nos Últimos Testes

Ao analisar minuciosamente os logs de execução de 12/11 às 19:30, foi identificada a causa exata pela qual o jogo continuava travando:

1. **O script estava executando o Lichii (`lichii-v160-pgo.AppImage`)**:
   - No commit `53cdd01`, o launcher `jogar_zelda.sh` havia sido configurado para priorizar o Lichii v160 caso o arquivo existisse.
   - O usuário estava, sem perceber, testando o Lichii e não o Eglantine.
2. **Engasgo Grave do Lichii v160 no Vulkan**:
   - O log do Lichii registrou: `1400.0 ms of draws held for unbuilt pipelines` (1,4 segundo de congelamento de tela a cada 10 segundos).
   - O recurso novo do Lichii `native_async_draws: Wait` e `native_pipeline_wait_ms: 8` congela a renderização para sincronizar draws.
   - O Lichii também tentou aplicar seus próprios patches embutidos de Dynamic FPS e entrou em conflito com os patches do usuário (`Skipping FPS Unlock: already patched`).
3. **Onde a fluidez sempre funcionou com perfeição**:
   - Foi no **Eglantine v0.1.0-rc3 PGO (`eglantine.AppImage`)**.

---

## 2. Ações Tomadas para Restauração Total da Fluidez

1. **Reversão do Launcher para o Eglantine**:
   - [`jogar_zelda.sh`](./jogar_zelda.sh) agora prioriza `eglantine.AppImage` como emulador principal.
2. **Perfil Gráfico Perfeito (`config/0400486024DEC000.ini`)**:
   - **Zero Clarões**: `gpu_accuracy=1` (High) + `fix_bloom_effects=true`.
   - **Zero Micro-travamentos**: `use_asynchronous_shaders=true` (compilação assíncrona).
   - **Suavidade Contínua**: `use_vsync=3` (`FifoRelaxed`).
   - **Renderização Nativa e Memória Leve**:
     - `resolution_setup=1` (`Res1X` nativo direto para a swapchain).
     - `vram_usage_mode=1` (`Conservative`).
     - `astc_recompression=1` (`Bc3` para placas AMD).
     - `use_reactive_flushing=true`.
3. **Bloqueio do Popup Destrutivo**:
   - O auto-confirmador do `jogar_zelda.sh` envia `Escape` para o popup "Recommended settings", impedindo que o Eglantine rebaixe a precisão da GPU para `Low` em tempo de execução.

---

## 3. Como Jogar

Execute diretamente o atalho na Área de Trabalho:
- [`Zelda: Ocarina of Time (Switch 2)`](file:///home/marcos/Área%20de%20trabalho/Zelda_Ocarina_of_Time.desktop) (chama `jogar_zelda.sh`).
