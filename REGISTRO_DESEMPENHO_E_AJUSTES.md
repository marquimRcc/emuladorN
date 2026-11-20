# Registro Técnico: Desempenho, Patches e Ajustes Gráficos
**Jogo:** The Legend of Zelda: Ocarina of Time (Nintendo Switch 2 / Remake)  
**Title ID:** `0400486024DEC000` | **Build ID (main):** `E0F3CCFAF50065AE4EA01EB5AEB13B1A45DA3348`  
**Branch de Teste Atual:** `test/eglantine-daily-20261120`  
**Emulador em Teste:** Eglantine Daily 20/11/2026 PGO (`eglantine-daily-20261120-pgo.AppImage`)  
**Ambiente:** Linux (Regata OS), Vulkan RADV (AMD Radeon RX 6700 XT)  
**Última Atualização:** 20/11/2026  

---

## 1. Isolamento do Ambiente de Teste

Conforme solicitado, mantivemos separação total:
1. **No Git**:
   - Branch dedicada: [`test/eglantine-daily-20261120`](https://github.com/marquimRcc/emuladorN/tree/test/eglantine-daily-20261120), completamente isolada da `main`.
2. **Na Pasta Local**:
   - Arquivo do emulador baixado como binário independente: `eglantine-daily-20261120-pgo.AppImage`.
   - Os builds anteriores (`eglantine-v0.1.0-rc3-pgo.AppImage`, `lichii-v160-pgo.AppImage`) permanecem intactos e intocados para qualquer necessidade de retorno instantâneo.
   - Launcher [`jogar_zelda.sh`](./jogar_zelda.sh) configurado para priorizar o build de 20/11 nesta branch.

---

## 2. Destaques do Novo Build (`daily-20261120`)

1. **Branch de Performance 60 FPS (`perf/oot-60-fps-cope`)**:
   - Reformulação do sincronismo de quadros: não segura mais núcleos da CPU do host em espera ativa de fences, liberando o processador para cadência fluida a 60 FPS.
2. **Otimizações para AMD Radeon (Commit `b54d1f06`)**:
   - Correção de gargalos de textura e swizzle no pipeline Vulkan (RADV) para GPUs AMD Navi 22.
3. **Popup Redesenhado (PR #837 / #800)**:
   - Não sobrepõe mais configurações agressivamente em runtime.
4. **FFmpeg Embutido (PR #856)**:
   - Decodificação nativa de vídeos e áudio empacotada no AppImage.

---

## 3. Configuração Ativa (`config/0400486024DEC000.ini`)

```ini
[Renderer]
# Qualidade visual e texturas perfeitas (sem rosto preto)
astc_recompression=0        # Uncompressed (qualidade máxima original)
resolution_setup=2          # Res1X (1.0x nativo)
vram_usage_mode=0           # Conservative

# Fluidez máxima e entrega contínua
use_asynchronous_shaders=true
use_vsync=3                 # FifoRelaxed
use_reactive_flushing=true

# Eliminação garantida de clarões
gpu_accuracy=1              # High
fix_bloom_effects=true
```

---

## 4. Inicialização

- **Atalho da Área de Trabalho**: [`Zelda: Ocarina of Time (Switch 2)`](file:///home/marcos/Área%20de%20trabalho/Zelda_Ocarina_of_Time.desktop) aponta para `jogar_zelda.sh`, que nesta branch executa automaticamente o novo `eglantine-daily-20261120-pgo.AppImage`.
