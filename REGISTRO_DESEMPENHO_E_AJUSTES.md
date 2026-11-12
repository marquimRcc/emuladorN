# Registro Técnico: Desempenho, Patches e Ajustes Gráficos
**Jogo:** The Legend of Zelda: Ocarina of Time (Nintendo Switch 2 / Remake)  
**Title ID:** `0400486024DEC000` | **Build ID (main):** `E0F3CCFAF50065AE4EA01EB5AEB13B1A45DA3348`  
**Emulador Principal:** Eglantine v0.1.0-rc3 PGO (`eglantine.AppImage`)  
**Ambiente:** Linux (Regata OS), Vulkan RADV (AMD Radeon RX 6700 XT)  
**Última Atualização:** 12/11/2026  

---

## 1. Diagnóstico do Regresso Visual (Rosto Preto e 10 FPS a 0.5x)

Ao analisar a imagem fornecida pelo usuário, foram identificadas 3 regressões decorrentes de índices de enum incorretos na última alteração do INI:

1. **Rosto do Link Preto e Texturas Corrompidas**:
   - `astc_recompression=1` mapeou para **`Bc1` (DXT1)**. O formato BC1 não suporta canal alpha gradativo (possui apenas 1 bit de alpha). Como o mapa facial do Link e detalhes de madeira usam transparência alfa no ASTC, o formato BC1 destruiu a textura e transformou o rosto em um bloco preto.
   - **Correção**: `astc_recompression=0` (**Uncompressed / Best Quality**). A GPU AMD RX 6700 XT decodifica o ASTC nativamente via Compute Shaders com 100% de fidelidade visual.
2. **Resolução em 0.5x (`Scale: 0.5x`)**:
   - `resolution_setup=1` mapeou para `Res1_2X` (metade da resolução nativa).
   - **Correção**: `resolution_setup=2` (**`Res1X`** = 1.0x nativo).
3. **Queda para 10 FPS e Stuttering de VRAM**:
   - `vram_usage_mode=1` mapeou para `Aggressive`, forçando descarte contínuo de texturas do cache da GPU e gerando 93ms por quadro.
   - **Correção**: `vram_usage_mode=0` (**`Conservative`**).

---

## 2. Configuração Final Consolidada (`config/0400486024DEC000.ini`)

```ini
[Renderer]
# 1. Resolução e Qualidade Visual Perfeitas
resolution_setup\use_global=false
resolution_setup\default=false
resolution_setup=2                  # Res1X (1.0x Nativo)

astc_recompression\use_global=false
astc_recompression\default=false
astc_recompression=0                # Uncompressed (Texturas e Rosto 100% fiéis)

vram_usage_mode\use_global=false
vram_usage_mode\default=false
vram_usage_mode=0                   # Conservative (Sem descarte de texturas)

# 2. Fluidez Total e Cadência Suave
use_asynchronous_shaders\use_global=false
use_asynchronous_shaders\default=false
use_asynchronous_shaders=true       # Shaders assíncronos

use_vsync\use_global=false
use_vsync\default=false
use_vsync=3                         # FifoRelaxed

# 3. Eliminação dos Clarões
gpu_accuracy\use_global=false
gpu_accuracy\default=false
gpu_accuracy=1                      # High (impede overflow de bloom)

fix_bloom_effects\use_global=false
fix_bloom_effects\default=false
fix_bloom_effects=true
```

---

## 3. Launcher

- Launcher [`jogar_zelda.sh`](./jogar_zelda.sh) configurado para rodar `eglantine.AppImage` com auto-rejeição do popup de configurações recomendado (fecha via `Escape`).
