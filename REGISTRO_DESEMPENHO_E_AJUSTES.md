# Registro Técnico: Desempenho, Patches e Ajustes Gráficos
**Jogo:** The Legend of Zelda: Ocarina of Time (Nintendo Switch 2 / Remake)  
**Title ID:** `0400486024DEC000` | **Build ID (main):** `E0F3CCFAF50065AE4EA01EB5AEB13B1A45DA3348`  
**Emulador:** Eglantine v0.1.0-rc3 PGO (Eden/Yuzu fork)  
**Ambiente:** Linux (Regata OS), Vulkan RADV (AMD Radeon RX 6700 XT)  
**Data:** 09/11/2026  

---

## 1. Fatos Confirmados (Evidências de Teste)

1. **Fluidez restaurada com sucesso**:
   - Mesmo em trechos onde o hardware entrega framerates inferiores a 60 FPS, a fluidez do jogo permaneceu excelente e consistente.
   - O sintoma anterior de queda forçada e travamento a 20 FPS (slow-motion causado pelo *double/triple buffering* nativo do motor da Nintendo) foi completamente eliminado.
2. **Patches da Comunidade Aplicados**:
   - **`FPS_Unlock`**: Gancho dinâmico no motor (`main + 0x6E6CC4`) que desvia para a rotina de interpolação no padding (`main + 0x3C46200`). Ajusta a escala de tempo de 10 a 120+ FPS com base no timer do hardware (`cntpct_el0` / `cntfrq_el0`) e filtro de suavização temporal.
   - **`Max_Resolution`**: Salto condicional em `main + 0x805BD0`, impedindo o *Dynamic Resolution Scaling* de rebaixar a resolução interna para 480p/384p sob carga de GPU.

---

## 2. Diagnóstico: Clarões e Flashes Brancos na Tela

### Causa Raiz
No motor gráfico utilizado (compartilhado com *Tears of the Kingdom*, bibliotecas `sead`, `agl`, `gsys` e `Phive`), os clarões/flashes repentinos em drivers AMD RADV ocorrem por dois fatores principais:

1. **Explosão de Bloom / HDR com GPU Accuracy em "Normal" (0)**:
   - Em precisão normal (`gpu_accuracy=0`), coordenadas de luz de alta intensidade, reflexos ou valores infinitos/NaN em buffers de iluminação pós-processada não sofrem *clamping* estrito. Quando a câmera aponta para fontes de luz (sol, tochas, reflexo de água), o filtro de bloom estoura e gera um clarão que cobre parte ou o total da tela.
2. **Opção `fix_bloom_effects` desativada**:
   - A configuração específica de tratamento e escalonamento de shaders de bloom estava herdando `false` do perfil global.

### Correções Aplicadas nos Arquivos de Configuração
Arquivos ajustados:
- `~/.config/eglantine/custom/0400486024DEC000.ini`
- `~/.config/eden/custom/0400486024DEC000.ini`

Parâmetros alterados:
```ini
[Renderer]
# 1. Eleva a precisão do pipeline gráfico para clamping matemático rigoroso em float/HDR
gpu_accuracy\use_global=false
gpu_accuracy\default=false
gpu_accuracy=1

# 2. Ativa explicitamente a correção de filtros de bloom pós-processamento
fix_bloom_effects\use_global=false
fix_bloom_effects\default=false
fix_bloom_effects=true
```

---

## 3. Próximos Passos e Observações

- **Teste visual**: Na próxima inicialização do jogo via [`jogar_zelda.sh`](./jogar_zelda.sh), verificar se os clarões diminuíram ou cessaram nos ambientes com luz intensa.
- **Compilação de Shaders**: Caso reste algum piscar isolado nos primeiros segundos de uma área inédita, é decorrente da compilação inicial de shaders Vulkan (normaliza após o cache em disco ser preenchido).
