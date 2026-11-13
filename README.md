# Emulador Nintendo Switch 2 (Eglantine) - The Legend of Zelda: Ocarina of Time Remake

Scripts de automação, patches de desempenho (60 FPS), configurações gráficas e guias técnicos para emulação de **The Legend of Zelda: Ocarina of Time (Nintendo Switch 2 Remake)** no **Linux (Regata OS)** e **Windows**.

---

## 🎮 Informações do Jogo e Emulador

- **Jogo**: The Legend of Zelda: Ocarina of Time (Nintendo Switch 2)
- **Title ID**: `0400486024DEC000`
- **Build ID (main)**: `E0F3CCFAF50065AE4EA01EB5AEB13B1A45DA3348`
- **Emulador**: Eglantine v0.1.0-rc3 PGO (fork de Eden/Yuzu com suporte à API gráfica NVN2 e shaders Ampere)
- **Driver Gráfico Testado**: Vulkan (Mesa RADV 26.x em AMD Radeon RX 6700/6750 XT / Windows Adrenalin)

---

## 📁 Estrutura do Repositório

```text
.
├── abrir_emulador.sh           # Abre a interface gráfica do emulador Eglantine
├── jogar_zelda.sh              # Inicializador otimizado para Linux (SDL, AMD RADV, Docked)
├── instalar_patches.py         # Injetor automático dos patches de 60 FPS e Resolução Máxima
├── config/
│   └── 0400486024DEC000.ini    # Configuração gráfica recomendada (fix de bloom, shaders assíncronos)
├── port_navi/                  # Port nativo estático Linux (NX2navi v0.10.1 - V2 1440p QHD / FSR)
│   ├── DOCUMENTACAO_TECNICA_PORT_NAVI_V2.md # Registro completo do port Linux, benchmarks e correções
│   ├── nx2navi.ini             # Configuração otimizada Linux (FSR 1, Async Replay, Low-End GPU)
│   ├── jogar_navi_v2.sh        # Launcher nativo Gamescope + Feral GameMode (4.0 GHz)
│   ├── monitor_navi_v2.py      # Widget gráfico de compilação em tempo real (Tkinter)
│   ├── restaurar_backup_18fps.sh # Script de rollback automático em 1 clique
│   ├── set_game_icon.py        # Fix de ícone da janela para o KDE Plasma / Wayland
│   └── icon.png                # Ícone oficial da Navi
├── windows_navi_fullHD/        # Port nativo estático Windows 11 (NX2navi v0.10.1 - FullHD 1080p @ 30 FPS)
│   ├── DOCUMENTACAO_TECNICA_WINDOWS_FULLHD.md # Relatório técnico completo de validação (30 FPS, 33.3 ms, 63 °C)
│   ├── nx2navi.ini             # Configuração consolidada (FSR 1 80%, ASTC RGBA8 puro, heap_lazy)
│   ├── jogar_zelda.bat         # Launcher Windows 1080p com variáveis de ambiente e suporte a controle
│   ├── configurar_pagefile.bat # Script com elevação UAC para fix de memória virtual no D:\
│   ├── configurar_pagefile_d.ps1 # Script WMI de paginação (16-32 GB dedicados)
│   ├── romfs-check.json        # Auditoria de integridade do RomFS
│   ├── icon.png                # Ícone em alta resolução
│   └── README.md               # Guia rápido de execução no Windows
├── jogar_zelda.bat             # Script de inicialização rápida para Windows (raiz)
├── preparar_windows.ps1        # Automação completa para configuração no Windows PowerShell
├── REGISTRO_DESEMPENHO_E_AJUSTES.md # Relatório técnico de desempenho e fixes de clarões brancos
├── GUIA_MIGRACAO_WINDOWS.md    # Guia detalhado de migração e configuração no Windows
├── icon.png                    # Ícone em alta resolução do jogo (512x512)
└── README.md
```

---

## 🚀 Como Executar no Linux (Regata OS)

### 1. Pré-requisitos
- Coloque o binário `eglantine.AppImage` (versão v0.1.0-rc3 PGO ou superior) na pasta raiz.
- Coloque a sua ROM do jogo (ex.: `The Legend of Zelda Ocarina of TIme [04004860224DEC000].nup`).

### 2. Configuração Gráfica
Copie o arquivo de configuração para os diretórios do emulador (o script `jogar_zelda.sh` também faz isso automaticamente):
```bash
mkdir -p ~/.config/eglantine/custom/ ~/.config/eden/custom/
cp config/0400486024DEC000.ini ~/.config/eglantine/custom/
cp config/0400486024DEC000.ini ~/.config/eden/custom/
```

### 3. Aplicar Patches de 60 FPS e Resolução Máxima
O script `instalar_patches.py` gera e injeta os arquivos binários IPS32 necessários para desativar o limitador nativo de 20 FPS e impedir a queda de resolução dinâmica (DRS). Compatível com Linux e Windows:
```bash
python3 instalar_patches.py
```

### 4. Jogar
Inicie o jogo diretamente com o script com suporte a controles SDL (8BitDo / Xbox) e perfil de performance:
```bash
chmod +x jogar_zelda.sh
./jogar_zelda.sh
```

---

## 🪟 Como Executar no Windows

1. Consulte o guia passo a passo em [GUIA_MIGRACAO_WINDOWS.md](./GUIA_MIGRACAO_WINDOWS.md).
2. Para automação rápida, abra o PowerShell como usuário e execute:
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   .\preparar_windows.ps1
   ```
3. Inicie o jogo pelo arquivo `jogar_zelda.bat`.

---

## ⚙️ Principais Ajustes Aplicados

- **Correção de Clarões Brancos / Bloom Estourado (AMD RADV)**: Ajustado `gpu_accuracy=1` (Alta Precisão) e `fix_bloom_effects=true` no arquivo INI para evitar saturação excessiva do pós-processamento.
- **Desativação de Frame Generation Interno**: Desativado (`frame_gen=false`) para eliminar judder/tremor na imagem, permitindo taxa de quadros limpa.
- **Modo Docked Forçado**: `use_docked_mode=1` para garantir a resolução e qualidade máxima dos shaders.
- **Idioma**: Configurado para Português do Brasil (`language_index=17`, `region_index=1`).

---

## 🧚 Ports Nativos para PC (NX2navi v0.10.1)

Além da emulação tradicional com Eglantine, o repositório inclui os arquivos e guias técnicos dos ports nativos via recompilação estática com **NX2navi v0.10.1**:

### 1. Windows FullHD 1080p @ 30 FPS Travado ([`windows_navi_fullHD/`](windows_navi_fullHD/))
- **Documentação Completa:** [DOCUMENTACAO_TECNICA_WINDOWS_FULLHD.md](windows_navi_fullHD/DOCUMENTACAO_TECNICA_WINDOWS_FULLHD.md)
- **Resolução:** 1920x1080 (Janela FullHD).
- **Desempenho Validado:** **30.0 FPS cravados** (1% piores: 30 FPS | 0.1% piores: 30 FPS), tempo de quadro perfeitamente plano em **33.3 ms**.
- **Consumo e Térmica:** GPU a frios **63 °C** com apenas **52W** de consumo (AMD Radeon RX 6750 XT).
- **Correções Gráficas:** Zero blocos cianos em Kokiri (`astc_bc = 0`), zero piscadas pretas (`replay_async = 0`) e arquivo de paginação dedicado no disco D: (`configurar_pagefile.bat`).

### 2. Linux 1440p QHD ([`port_navi/`](port_navi/))
- **Documentação Completa:** [DOCUMENTACAO_TECNICA_PORT_NAVI_V2.md](port_navi/DOCUMENTACAO_TECNICA_PORT_NAVI_V2.md)
- **Resolução:** 2560x1440 (QHD) com **AMD FSR 1** e nitidez de 80%.
- **Desempenho Alcançado:** 19 FPS contínuos e estáveis (frametime médio de **51.9 ms**, sem travamentos de shader e sem leak de VRAM).
* **Otimizações Inclusas:** `replay_async = 1` (paralelismo CPU/GPU), `low_end_gpu = 1` (submissões em lote Vulkan) e integração com o **Feral GameMode (`gamemoderun`)**.

---

## ⚠️ Aviso Legal
Este repositório **NÃO contém ROMs, chaves de decodificação (prod.keys) ou binários protegidos por direitos autorais**. Todos os scripts e patches destinam-se exclusivamente para fins de preservação e execução de cópias legalmente adquiridas pelo próprio usuário.
