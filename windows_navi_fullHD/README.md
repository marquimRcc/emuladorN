# The Legend of Zelda: Ocarina of Time (NX2navi Windows FullHD)

Este diretório contém os scripts de inicialização, configurações otimizadas e documentação do port nativo de **The Legend of Zelda: Ocarina of Time** para **Windows 11** utilizando o recompilador estático **NX2navi v0.10.1**.

---

## Destaques da Configuração (FullHD 1080p @ 30 FPS Travado)

- **Resolução:** 1920x1080 (Janela FullHD).
- **Taxa de Quadros:** 30 FPS cravados (tempo de quadro de 33.3 ms sem oscilações).
- **Filtro Gráfico:** AMD FSR 1 com nitidez de 80% e FXAA.
- **Correção de Partículas:** `astc_bc = 0` (elimina blocos cianos nos esporos de Kokiri).
- **Eliminação de Piscadas:** `replay_async = 0` (zero telas pretas).
- **Consumo e Térmica:** GPU a 63 °C e consumo de apenas 52W na RX 6750 XT.

---

## Como Executar

1. **Configuração de Memória Virtual (Execute uma única vez se ainda não tiver feito):**
   - Execute o script `configurar_pagefile.bat` como Administrador para alocar de 16 GB a 32 GB de memória virtual no drive D:, evitando congelamento do driver de vídeo.
2. **Iniciar o Jogo:**
   - Execute `jogar_zelda.bat` ou abra o atalho correspondente na sua Área de Trabalho.
3. **Controles:**
   - Suporte nativo completo a controles Xbox / XInput com mapeamento de botões oficial.
   - Pressione **F10** para alternar a exibição da telemetria de desempenho em tempo real.
   - Pressione **F1** para acessar o menu interno de ajustes gráficos.

---

## Documentação Técnica Completa

Para a análise aprofundada de hardware, comparação com a versão Linux e histórico de telemetria, consulte:
- [DOCUMENTACAO_TECNICA_WINDOWS_FULLHD.md](./DOCUMENTACAO_TECNICA_WINDOWS_FULLHD.md)
