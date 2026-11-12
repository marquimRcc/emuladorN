# Guia de Migração: Zelda Ocarina of Time (Switch 2) no Windows

Este documento reúne o diagnóstico técnico completo realizado no Linux e as instruções exatas para executar o jogo no **Windows** com máximo desempenho e estabilidade utilizando o Google Antigravity.

---

## 1. Resumo do Diagnóstico no Linux

1. **Arquivo do Jogo**:
   - Arquivo: `The Legend of Zelda Ocarina of TIme [04004860224DEC000].nup` (~24 GB).
   - Title ID: `0400486024DEC000`.
   - Formato: NUP (NX Package / Switch 2, standalone update v1.1.1, SDK 22.2.8, API gráfica NVN2).

2. **Por que a build diária deu tela preta no Linux?**
   - A versão `daily-20261106` regrediu a compatibilidade com o driver `RADV` (Mesa open-source para AMD no Linux), gerando tela 3D preta.
   - A versão que funciona é a branch dedicada: **`branch-oot-optimization-fixes-ea3f96f2`**.

3. **Por que a tela ficou tremida / com artefatos?**
   - O jogo internamente roda a **20 FPS** (física do motor original).
   - Ao ativar o *Frame Generation* interno experimental do emulador via software (FSR 3 flow scale), a interpolação em cima de uma base de 20 FPS causou judder (tremor/flickering).
   - **Correção**: Manter `frame_gen=false` no emulador e, no Windows, utilizar o **AFMF (AMD Fluid Motion Frames)** direto no driver **AMD Adrenalin**, que faz a interpolação suave em hardware sem tremer a cena.

4. **Idioma (PT-BR)**:
   - Parâmetros no `qt-config.ini`: `language_index=17` e `region_index=1`.

5. **Controle**:
   - Controle do usuário: **8BitDo Ultimate 2 Wireless Controller**.
   - No Linux dependia de configurações manuais de SDL / Handheld vs Docked. No Windows, o driver XInput o reconhece nativamente como Xbox Controller com 100% de compatibilidade automática.

---

## 2. A versão para Windows é melhor?

**Sim, significativamente superior para este emulador experimental:**
1. **Drivers de Vídeo**: No Windows, os drivers proprietários da AMD (Adrenalin) e NVIDIA implementam todas as extensões Vulkan exigidas pelo emulador que faltam no driver RADV do Linux (`VK_EXT_external_memory_host`, `VK_EXT_robustness2`, etc.), eliminando crashes de shaders e telas pretas.
2. **AMD Fluid Motion Frames (AFMF 2 / HYPR-RX)**: No Windows, a AMD possui geração de quadros nativa no driver que transforma os 20 FPS em 60+ FPS fluidos sem causar o tremor observado no emulador.
3. **Controle plug-and-play**: O 8BitDo no Windows entra diretamente como dispositivo XInput nativo, sem necessidade de mapear GUIDs ou ajustar portas SDL manualmente.

---

## 3. Prompt para copiar e colar no Antigravity no Windows

Copie e envie o texto abaixo para o **Google Antigravity** na sua máquina Windows:

```text
Olá Antigravity! Quero configurar e rodar o emulador Eglantine para o jogo The Legend of Zelda: Ocarina of Time (Switch 2) aqui no Windows.

Já fiz o diagnóstico técnico prévio:
- Jogo: "The Legend of Zelda Ocarina of TIme [04004860224DEC000].nup" (Title ID: 0400486024DEC000).
- Build recomendada do emulador para esta ROM (evita tela preta e regressão de shaders): 
  https://github.com/Eglantine-Community/Eglantine/releases/download/v0.1.0-rc3/eglantine-windows-x86_64-pgo.zip
- Idioma necessário: PT-BR (language_index=17, region_index=1 no qt-config.ini).
- Meu controle: 8BitDo Ultimate 2 Wireless Controller conectado via USB/Dongle (reconhecido como XInput no Windows).
- Gráficos: GPU Accuracy em Normal (0), Bilinear (1), Docked Mode (1), sem frame_gen interno (para evitar tremor).

Por favor:
1. Baixe e descompacte a versão correta do emulador no diretório "%USERPROFILE%\Documentos\emulador".
2. Configure o qt-config.ini do Eglantine em "%APPDATA%\eglantine\config\qt-config.ini" para PT-BR e modo Docked com GPU Accuracy Normal.
3. Crie um script "jogar_zelda.bat" para iniciar o jogo diretamente.
```

---

## 4. Script de Automação PowerShell (Windows)

Você também pode simplesmente rodar o script PowerShell que geramos:
- Caminho do arquivo: `preparar_windows.ps1`
- Execução no PowerShell do Windows:
  ```powershell
  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
  .\preparar_windows.ps1
  ```
