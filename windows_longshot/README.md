# Longshot - The Legend of Zelda: Ocarina of Time (Windows 1080p)

Configuração pronta e otimizada para o emulador/recompilador nativo **Longshot** (sucessor do Hookshot), adaptando todas as recomendações de desempenho testadas na GPU AMD Radeon RX 6750 XT e Core i5-12400F.

## 📁 Arquivos Inclusos

- **`longshot_options.ini`**: Configuração com resolução FullHD 1080p, FSR 3.1 80%, VRAM limitada a 6.2 GB, frame pacing ativo e controles Xbox em português do Brasil.
- **`jogar_zelda_longshot.bat`**: Script de inicialização rápida com variáveis de ambiente Vulkan e captura de joystick.
- **`DOCUMENTACAO_TECNICA_WINDOWS_LONGSHOT.md`**: Relatório técnico com comparação direta dos parâmetros e histórico dos commits.

## 🚀 Como Jogar

1. Execute **`jogar_zelda_longshot.bat`** ou use o atalho na Área de Trabalho (**`Longshot - Zelda Ocarina of Time`**).
2. O jogo iniciará diretamente pelo binário nativo compilado com o cache gráfico Vulkan de 1,49 GB (`mkw_vk_pipelines.bin`).
3. As configurações de `longshot_options.ini` são aplicadas automaticamente (FullHD 1080p, FSR 3.1 80%, teto de VRAM seguro e controles Xbox em português).

---

## 🎮 Atalhos em Jogo

- **`F1` / `Insert` / `Esc`:** Abre o menu de configurações e ajustes gráficos em tempo real.
- **`Q` / `E`:** Navega entre as abas do menu (`Gráficos`, `Áudio`, `Jogo`, `Controles`, `Debug`).
- **Aba `Jogo` $\to$ `Contador de FPS`:** Alterna entre `FPS`, `Tempo de quadro`, `Gráfico` e `Desenvolvedor` (telemetria completa).
- **`Ctrl + Shift + O`:** Overlay oficial de temperatura, clock e Watts do **AMD Adrenalin**.

---

## 📊 Desempenho Validado em Jogo (Kokiri Forest)

- **Taxa de Quadros:** **47 FPS** contínuos (1% Low: **31 FPS**)
- **Frametime:** **25.8 ms** com cadência plana e estável
- **Compilação de Shaders:** **0 stuttering** (25.344 pipelines pré-compilados em cache)
- **VRAM:** **8.9 GB / 10.6 GB** (Texturas a 2.7 GB sem risco de PCIe thrashing)
