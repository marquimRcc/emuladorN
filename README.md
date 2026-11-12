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
├── jogar_zelda.bat             # Script de inicialização rápida para Windows
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
Copie o arquivo de configuração para o diretório do emulador:
```bash
mkdir -p ~/.config/eglantine/custom/
cp config/0400486024DEC000.ini ~/.config/eglantine/custom/
```

### 3. Aplicar Patches de 60 FPS
O script `instalar_patches.py` aplica os ganchos de código em memória para desativar o limitador nativo de 20 FPS da Nintendo e impedir a queda de resolução dinâmica (DRS):
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

## ⚠️ Aviso Legal
Este repositório **NÃO contém ROMs, chaves de decodificação (prod.keys) ou binários protegidos por direitos autorais**. Todos os scripts e patches destinam-se exclusivamente para fins de preservação e execução de cópias legalmente adquiridas pelo próprio usuário.
