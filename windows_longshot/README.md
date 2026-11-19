# Longshot 3.0 - The Legend of Zelda: Ocarina of Time (Windows Nativo)

Configuração oficial, scripts de automação e perfil de alto desempenho para o emulador/recompilador nativo **Longshot 3.0** (projeto Nintendo Switch 2 Remake para PC Nativo via Vulkan).

Este perfil foi testado, calibrado e validado especificamente no setup:
- **GPU:** AMD Radeon RX 6750 XT (12 GB GDDR6, driver AMD Adrenalin 26.11.2)
- **CPU:** Intel Core i5-12400F (6C / 12T)
- **RAM:** 32 GB DDR4
- **Monitor:** 2560x1440 @ 75 Hz (Renderização nativa 1080p 1:1)
- **SO:** Windows 11 (64-bit)

---

## 📁 Estrutura de Arquivos

- **`jogar_zelda_longshot.bat`**: Script de inicialização rápida com verificação de builds, injeção de prioridade alta e flags Vulkan otimizadas.
- **`longshot_options.ini`**: Perfil calibrado com 1080p nativo, Anti-Lag 2 ativo, contador de FPS leve e mapeamento completo do controle Xbox em português (PT-BR).
- **`longshot.ico`**: Ícone oficial do Hookshot em alta definição (161 KB), com camadas nativas DIB 32-bit (16, 32, 48, 64, 128 px) e PNG (256 px) para o Windows Explorer.
- **`longshot.png`**: Logotipo original em 512x512 com canal alfa 32-bit.
- **`criar_atalho_desktop.ps1`**: Script PowerShell para gerar automaticamente os atalhos de Área de Trabalho (OneDrive e Desktop local) com associação direta ao ícone.
- **`DOCUMENTACAO_TECNICA_WINDOWS_LONGSHOT.md`**: Relatório técnico detalhado com histórico de problemas diagnosticados e correções aplicadas.

---

## 🚀 Como Jogar

1. Execute **`jogar_zelda_longshot.bat`** ou clique duas vezes no atalho **`Zelda Ocarina of Time - Longshot 3.0`** na Área de Trabalho.
2. O script localiza automaticamente a build estável (`LongshotLauncher-data\builds\v3.0.0-rc.3` ou `v3.0.0`), sincroniza o arquivo `longshot_options.ini` e dispara o executável do jogo.
3. Para recriar o atalho com o ícone oficial em qualquer momento, execute pelo PowerShell:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\criar_atalho_desktop.ps1
   ```

---

## 🎮 Controles e Atalhos em Jogo

- **Controle Xbox / XInput:** Detecção nativa automática via SDL3.
  - `A`: Ação / Rolar / Falar
  - `B`: Ataque com Espada
  - `X`: Botão de Itens C-Esquerdo
  - `Y`: Botão de Itens C-Direito
  - `LT (ZL)`: Z-Targeting / Foco de Mira
  - `RT (ZR)`: Escudo
  - `LB (L)` / `RB (R)`: Mapa e C-Baixo
  - `D-Pad`: Seleção de Ocarina, Botas e Itens Especiais
- **Teclado:**
  - `WASD`: Movimentação
  - `Setas do Teclado`: Câmera
  - `F1` / `Insert` / `Esc`: Menu de configurações e ajustes gráficos em tempo real
  - `Ctrl + Shift + O`: Overlay oficial de telemetria do driver AMD Adrenalin

---

## 📊 Métricas de Desempenho Validadas (Kokiri Forest)

- **Taxa de Quadros:** **60.0 FPS** cravados
- **Tempo de GPU:** **0.82 ms** por quadro
- **Draws Perdidos:** **0.0** (`0.0 draws left out`)
- **Compilação de Shaders:** Pré-carregamento ativo com cache acumulado de mais de 1.200 pipelines (`mkw_vk_pipelines.bin`)
- **Uso de Memória RAM:** Estabilizado em ~3,5 GB (sem risco de memory leak ou PCIe thrashing)
