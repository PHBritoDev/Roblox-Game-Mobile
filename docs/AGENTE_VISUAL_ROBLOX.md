# Agente visual Roblox — plano de implantação (14/11/2026)

## Objetivo do criador
Construir e revisar **Mundo 1: floresta Dreamcore cinematográfica** (pôr do sol quente, sombra fria, noite estrelada nostálgica; inspiração de clima visual de fantasia anime original), registrando imagens e vídeos de cada alteração **sem depender do criador para fotografar manualmente**. Orçamento do criador: **gratuito de preferência, máximo R$ 10**, Android apenas.

## Aprendizado reaproveitado do RPG Three.js
O repositório `PHBritoDev/Jogo-2-2.5D` já implementa:
- `.github/workflows/fotografo-3d.yml`: fotógrafo sob demanda com `tools/visual-lab/photographer.cjs`, Playwright + Chromium, capturas e artifact.
- `.github/workflows/laboratorio-visual.yml`: teste WebGL, screenshots, vídeos WebM, conversão FFmpeg para MP4, comparação de imagens, relatórios.
- `AGENTS.md`: padrão de evidência antes de alegar qualidade, sem aprovação fictícia.
Estes workflows rodam porque o RPG é **WebGL/Three.js num navegador**. **Roblox NÃO renderiza dentro de Chromium/WebGL/Playwright**: copiar workflow diretamente não renderiza Roblox.

## Descoberta oficial relevante (2026)
- Roblox Studio MCP server: `https://create.roblox.com/docs/studio/mcp`.
- Com Roblox Studio aberto no Windows/macOS, disponibiliza `screen_capture` (viewport real, câmera escolhida), `start_stop_play`, `character_navigation`, `execute_luau`, `get_console_output`, e subagente `playtest`. O cliente MCP pode comparar screenshots e decidir correções.
- Exige **sessão Studio ativa numa máquina Windows/macOS**, e configuração da conexão MCP no mesmo ambiente. O ChatGPT web/Android conectado ao GitHub **não** acessa sozinho esse MCP local.
- `StudioCaptureService` oferece captura via plugin no Studio.
- Open Cloud Luau Execution: `https://create.roblox.com/docs/cloud/reference/features/luau-execution`. Executa código em modo **headless**, útil para inventário, testes lógicos e logs, **não é viewport 3D nem captura de imagem**.
- `CaptureService` no jogo captura do **cliente** e envolve fluxos de captura do usuário; não fornece sozinho screenshot remota automática do servidor para GitHub.

## A arquitetura que queremos
1. **GitHub / WorldBuilder:** commit do mapa e estilos de iluminação em Luau. Validar sintaxe, estrutura e construir artefato Rojo.
2. **Roblox Open Cloud / Smoke Agent:** com chave e *scope* próprios, executar testes headless para existência de objetos, configurações de Lighting e contagem de instâncias. Não inventar visual.
3. **Studio MCP / Visual QA Agent:** **quando houver máquina compatível com Studio**, abrir Place de teste, entrar em play, chamar `screen_capture` de câmera predefinida em pelo menos 5 posições (spawn, trilha, ponte, lago, ponto alto), em pôr do sol e noite, salvar PNGs e comparar com referências; gravar vídeo com ferramenta de captura de desktop/FFmpeg quando ambiente permitir.
4. **Artifacts:** salvar capturas, vídeos, console e relatório de critérios estéticos. Nunca afirmar que imagens são do Roblox sem serem capturadas da engine.
5. **Aprovação:** melhorar ou rejeitar com base na evidência e em métricas; manter versões recuperáveis.

## Status validado
- Já conseguimos `rojo build` em Linux GitHub Actions, gerar `.rbxlx` e publicar no Place existente por Open Cloud.
- **Não há uma máquina Windows/macOS executando Studio vinculada a este chat ou GitHub**; nenhuma captura de viewport real foi obtida.
- A hospedagem de um Windows compatível com GUI/GPU pode ter custo, e não foi confirmada oferta gratuita com Studio funcional.
- NÃO realizar teste em conta do criador por login remoto inseguro; nunca compartilhar credenciais ou tokens em chat.
- **Não substituir** automaticamente a experiência principal só para tentar capturas.

## Próximo experimento de baixo risco
1. Montar pipeline de teste lógico via Open Cloud Luau Execution, com chave de scope mínimo adicionada em GitHub Actions Secrets — autorização de credenciais depende do criador.
2. Investigar acesso a VM Windows/macOS com GPU e console gráfico dentro de R$ 10 ou teste grátis legítimo (sem cadastro arriscado); verificar termos, autenticação e limites.
3. Configurar Studio MCP e captura de imagens somente após ambiente real validado.
4. Até lá, construir mapa com critérios verificáveis em código e design docs, **sem confundir mockups/referências visuais com screenshots do jogo**.

## Critérios visuais do Mundo 1
- Silhueta de floresta fechada, clareira inicial com profundidade de composição e landmark único (árvore monumental), múltiplas camadas de vegetação.
- Direção de luz quente/fria legível, raios solares atravessando copas, sombras, névoa de volume sugerida de modo leve.
- Versões de clima: Golden Nostalgia (pôr do sol), Cold Twilight, Starry Dream Night.
- FPS e memória testados num celular real quando disponível; orçamento de transparências, sombras, partículas e replicação.
- Referência artística Genshin Impact apenas como qualidade geral, NÃO copiar arte/meshes/texturas.

## Fontes
- https://create.roblox.com/docs/studio/mcp
- https://create.roblox.com/docs/reference/engine/classes/StudioCaptureService
- https://create.roblox.com/docs/cloud/reference/features/luau-execution
- https://create.roblox.com/docs/reference/engine/classes/CaptureService
- https://github.com/PHBritoDev/Jogo-2-2.5D/blob/main/.github/workflows/fotografo-3d.yml
- https://github.com/PHBritoDev/Jogo-2-2.5D/blob/main/.github/workflows/laboratorio-visual.yml
