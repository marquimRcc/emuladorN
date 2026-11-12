# Registro Técnico: Desempenho, Patches e Ajustes Gráficos
**Jogo:** The Legend of Zelda: Ocarina of Time (Nintendo Switch 2 / Remake)  
**Title ID:** `0400486024DEC000` | **Build ID (main):** `E0F3CCFAF50065AE4EA01EB5AEB13B1A45DA3348`  
**Emuladores:** Eglantine v0.1.0-rc3 PGO / Lichii build 160 PGO  
**Ambiente:** Linux (Regata OS), Vulkan RADV (AMD Radeon RX 6700 XT)  
**Última Atualização:** 12/11/2026  

---

## 1. Fatos Confirmados (Evidências em Teste Real)

1. **Clarões Eliminados com Sucesso (12/11/2026)**:
   - O usuário testou e confirmou: **os clarões e flashes brancos sumiram completamente**.
   - Causa real dos clarões: O popup de configurações recomendadas ou a flag `gpu_accuracy\default=true` forçava `gpu_accuracy=0` (Low). Em precisão Low (FP16), buffers de HDR e Bloom estouravam para $+\infty$, cobrindo a tela de branco ofuscante.
   - Solução definitiva: `gpu_accuracy=1` (High), `fix_bloom_effects=true` e bloqueio de popups que rebaixavam a precisão.

2. **Como a Fluidez foi Originalmente Resolvida**:
   - **Patch IPS32 `FPS_Unlock`**: Gancho dinâmico no motor (`main + 0x6E6CC4`) desviando para rotina de interpolação em `main + 0x3C46200`. Acoplado ao timer nativo ARM64 (`cntpct_el0` / `cntfrq_el0`), desvinculou o jogo da trava rígida de 20 FPS da Nintendo, permitindo framerates fluidos e dinâmicos (10 a 120 FPS).
   - **Compilação Assíncrona de Shaders (`use_asynchronous_shaders: true`)**: Permitiu que novos pipelines gráficos Vulkan fossem gerados em segundo plano, sem pausar a thread principal de renderização.
   - **Apresentação de Quadros Relaxada (`use_vsync: FifoRelaxed` / modo 3)**: Eliminou o efeito de queda súbita para 30 FPS (*double buffer lock*) caso um quadro atrase frações de milissegundo.

---

## 2. Diagnóstico: Por que a Fluidez Tinha Sumido no Último Teste?

Durante a tentativa anterior de corrigir os clarões (commit `0b6d27c`), duas configurações afetaram diretamente a cadência de quadros:

1. **Desativação dos Shaders Assíncronos (`use_asynchronous_shaders: false`)**:
   - Ao forçar a compilação síncrona, a thread de renderização da GPU passa a congelar (*hitch / micro-stutter*) toda vez que encontra um novo shader, textura ou efeito que ainda não estava gravado em cache.
2. **VSync Travado em `Fifo` Rígido (modo 2)**:
   - Com `use_vsync\use_global=true`, o emulador operava no modo VSync tradicional (FIFO estrito a 60 Hz). Como o emulador oscila de acordo com a carga da cena, o VSync estrito gera solavancos perceptíveis (*judder*).

---

## 3. Solução Unificada: Fluidez Máxima + Zero Clarões

Os clarões eram causados unicamente pelo estouro matemático de precisão (`gpu_accuracy: Low`), e **não** pela compilação assíncrona em si quando a precisão está alta.

Portanto, o perfil otimizado em `config/0400486024DEC000.ini` reúne:

```ini
[Renderer]
# 1. Impede qualquer clarão ou estouro de bloom (Alta precisão matemática)
gpu_accuracy\use_global=false
gpu_accuracy\default=false
gpu_accuracy=1
fix_bloom_effects\use_global=false
fix_bloom_effects\default=false
fix_bloom_effects=true

# 2. Restaura a fluidez total sem micro-travamentos (Compilação assíncrona)
use_asynchronous_shaders\use_global=false
use_asynchronous_shaders\default=false
use_asynchronous_shaders=true

# 3. Elimina engasgos de double-buffering e solavancos de quadros (VSync Relaxado)
use_vsync\use_global=false
use_vsync\default=false
use_vsync=3
```

---

## 4. Inicialização e Atalho

- **Atalho da Área de Trabalho**: [`Zelda: Ocarina of Time (Switch 2)`](file:///home/marcos/Área%20de%20trabalho/Zelda_Ocarina_of_Time.desktop) aponta para [`jogar_zelda.sh`](./jogar_zelda.sh).
- O script sincroniza automaticamente o perfil acima para os emuladores (`lichii`, `eglantine`, `eden`) antes de inicializar o jogo.
