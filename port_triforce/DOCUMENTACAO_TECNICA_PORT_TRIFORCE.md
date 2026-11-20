# Documentação Técnica: Port Triforce v0.5.2 (Triforce Project - Linux Nativo)
**Projeto:** The Legend of Zelda: Ocarina of Time (Switch 2 → PC Linux Nativo)  
**Ambiente de Execução:** Regata OS (Linux x86_64 / KDE Plasma / X11 / Gamescope), Intel Core i5-12400F (6C/12T), AMD Radeon RX 6750 XT (12 GB VRAM / Mesa RADV Navi 22 / ACO)  
**Data da Atualização:** 19 de Novembro de 2026  
**Status:** Atualizado para Triforce v0.5.2 (Build incremental finalizado em 2m53s sem falhas). Full HD 1080p nativo com upscale FSR no Gamescope, novo launcher com benchmark automático ("Find my best settings"), suporte a mods e gerenciamento de saves.

---

## 1. Histórico de Versões e Evolução

| Versão | Data | Principais Características e Status |
| :--- | :---: | :--- |
| **v0.4.0** | 18/11/2026 | Primeiro release unificado pós-fusão NX2navi. Apresentava queda para 20 FPS e engasgos na folhagem devido a quebras de render pass e threads auxiliares ativas. |
| **v0.5.0** | 18/11/2026 | Occlusion culling ativado por padrão (+3-5% FPS), desativação de *replay helper threads* e *robust buffers*, correção do render pass da grama/folhagem, compressão de texturas BC1 e novo in-game HUD de performance. |
| **v0.5.2** | 19/11/2026 | **Versão Atual Ativa.** Novo launcher visual imersivo, ferramenta de benchmark automático **"Find my best settings"** (teste de 2 min em 4 áreas), 8 workers paralelos para compilação de shaders em AMD RX 6000, eliminação de black flashes e modo co-op online (Squadala!). |

---

## 2. Arquitetura e Atualização Incremental (v0.4.0 → v0.5.2)

A atualização para a v0.5.2 utilizou o mecanismo `--update` com reutilização total do cache de objetos (`~/.cache/triforce-build/objcache/`), reduzindo o tempo de compilação de **32 minutos** para apenas **2 minutos e 53 segundos**:

```
[ Atualização Incremental CLI v0.5.2 ]
         │
         ├──► RomFS (26.2 GB) ────────────────► 100% Preservado via links originais (0 bytes extras)
         │
         ├──► ExeFS (.triforce_exefs) ────────► Inalterado
         │
         ├──► Cache de Objetos (objcache) ────► 137 objetos C reutilizados instantaneamente
         │
         ├──► Lifter C + Clang ───────────────► Apenas arquivos modificados recompilados (51s)
         │
         ├──► Binário Final Linkado ──────────► /home/marcos/Games/Triforce/bin/triforce (509 MB)
         │
         └──► Shaders Vulkan ─────────────────► triforce_shaders.bin preservado e revalidado
```

---

## 3. Otimizações Específicas para o Hardware (i5-12400F + RX 6750 XT 12 GB)

1. **Correção de Folhagem e Grama (Fim dos 20 FPS na Floresta):**
   * As chamadas de geometria para grama e folhas deixaram de interromper o *render pass* do Vulkan, eliminando o gargalo massivo de trocas de estado.
2. **Desativação das Replay Helper Threads:**
   * Libera ciclos vitais da CPU (6 núcleos físicos / 12 threads), eliminando engasgos de mais de 40 ms e estabilizando os *1% lows* (+33%) e *0.1% lows* (+70%).
3. **Occlusion Culling & Compressão BC1:**
   * Geometria não visível é descartada antes do rasterizador da RX 6750 XT (10–12% menos draw calls).
   * Texturas opacas em formato BC1 aliviam o barramento PCIe e o consumo de VRAM.
4. **Shaders Otimizados para AMD RDNA 2 (RX 6000):**
   * Preparação de shaders distribuída entre 8 workers simultâneos.

---

## 4. Recursos do Novo Launcher Oficial & Benchmark

* **Benchmark "Find my best settings":**
  * Localizado em **Settings** no novo launcher.
  * Executa um sobrevoo cinematográfico autônomo de 2 minutos por Hyrule Field, Castle Town Market, Kokiri Forest e Lake Hylia.
  * Analisa métricas em tempo real e calcula os valores ideais de resolução, upscaling e filtros para a máquina.
* **Gestão Integrada de Saves:**
  * Exibe os 6 slots com miniaturas geradas em tempo real a partir dos saves.
  * Suporta importação e exportação segura com backup automático contra corrupção.
* **Navegador de Mods GameBanana:**
  * Permite instalar modificações e pacotes de melhorias gráficas ou de jogabilidade sem sair do ecossistema do jogo.

---

## 5. Como Executar

### 1. Jogo Direto (Modo Gamescope 1080p -> 1440p FSR com MangoHud)
```bash
/home/marcos/Games/Triforce/jogar_triforce.sh
```
*Disponível também pelo atalho na Área de trabalho:* `Zelda: Ocarina of Time (Triforce v0.5.2)`.

### 2. Novo Launcher Oficial Triforce (Saves, Mods e Benchmark)
```bash
/home/marcos/Games/Triforce/triforce
```
*Disponível também pelo atalho na Área de trabalho:* `Triforce Launcher (v0.5.2)`.

### 3. Modo Direto (Sem Gamescope / Janela KDE Plasma)
```bash
/home/marcos/Games/Triforce/jogar_triforce.sh --direct
```

---

## 6. Diretriz Operacional de Atualização (Política "Chegar e Jogar")

* **Compilação 100% Antecipada em Background:** Em todas as futuras atualizações e builds (seja Triforce, NX2navi ou ports derivados), **NUNCA** utilizar `--no-prepare-shaders` ou adiar etapas para a primeira execução do usuário.
* **Aquecimento e Pré-Preparação de Shaders:** O processo automatizado em segundo plano deve realizar o ciclo completo de preparação dos pipelines Vulkan e programas gráficos antes de notificar o usuário ou liberar o atalho.
* **Objetivo de UX:** O usuário não deve aguardar compilação em primeiro plano ao abrir o jogo; o ambiente deve ser entregue 100% fluido e pronto para jogar imediatamente.

