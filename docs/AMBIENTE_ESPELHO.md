# Ambiente espelho — um código, duas formas de testar (14/11/2026)

## Fonte única da verdade
**`src/server/DreamcoreWorld.server.luau`**, `src/client/Welcome.client.luau` e `default.project.json` são a única fonte de código. NÃO manter uma cópia alternativa do gerador de floresta: as prévias precisam sempre executar o arquivo de produção diretamente.

### Opção A — espelho Roblox REAL (mesma engine, mesmo código)
Pipeline: [`publicar-espelho-roblox.yml`](../.github/workflows/publicar-espelho-roblox.yml)
- Faz `rojo build default.project.json` a partir do mesmo commit do jogo, publica em **outro Universe/Place**, e registra o SHA.
- Bloqueia explicitamente os IDs da experiência principal: Universe `2660433574`, Place `6947682498`.
- **Ainda NÃO existe o outro Place**: é necessário criá-lo pela conta Roblox do criador ou conectar uma integração com permissão de criação. O workflow exige os IDs corretos desse novo destino e autorização `universe-places:write` na chave para ele.
- Mesmo com Place duplicado e jogável, falta uma máquina com Roblox Studio/cliente para fotografar e gravar o cenário real. Publicar no espelho NÃO significa que o agente já consiga ver o jogo.
- NENHUMA alteração ou publicação no jogo principal é disparada automaticamente.

### Opção B — espelho de geometria renderizada em Blender (gratuito, aproximado)
Pipeline: [`visual-proxy-roblox.yml`](../.github/workflows/visual-proxy-roblox.yml)
1. Lê `src/server/DreamcoreWorld.server.luau` do commit atual.
2. Executa em uma sessão Open Cloud Luau Execution usando a engine Roblox em modo headless. O script gera o mapa **em memória**; anexa `export_scene.luau` e retorna uma amostra de instâncias.
3. Reconstrói a geometria selecionada em Blender com conversão de eixos Roblox Y-up → Blender Z-up.
4. Emite `preview_spawn.png`, `preview_approach.png`, `preview_canopy.png` e `preview_montagem.mp4` para o artifact. Sem intervenção do criador no celular.
5. **Não são capturas nativas de Roblox:** `Terrain` é um proxy plano, água aproximada, luz/sombras diferentes, e podem faltar objetos devido à amostragem. Útil para ver escala e composição, NÃO comprova qualidade final da imagem, FPS ou física.

## Visual QA
- Visualizador deve reportar divergência quando a geração é aprovada no Roblox mas a reconstrução tem problema de eixos, amostragem ou câmera; não alterar o mapa real para corrigir bugs do proxy.
- O agente pode analisar as PNGs do artifact e ajustar o próprio pipeline, como foi feito na primeira captura.
- As imagens são evidência de um **modelo aproximado**. Não chamá-las de fotos da engine Roblox.
- Experimento Studio MCP futuro: screenshots **reais** e vídeos do viewport Roblox num ambiente Windows/macOS com interface gráfica.
- Nenhuma conexão de contas ou compra de serviço de nuvem autorizada.

## Fluxo seguro
1. Commit de código único → `QA estrutural` + `Rojo build` + `laboratório visual proxy`.
2. Conferir resultados, corrigir o source ou o renderer de acordo com evidências.
3. Se existir Place de desenvolvimento, publicar **nele** o mesmo commit.
4. Publicar no jogo principal só depois de testes e aprovação; publicação de produção é separada e manual.

## Histórico
- Primeira exportação Roblox: **1.287 BaseParts**, amostra **345** para renderizar.
- Primeiro build Blender falhou por falta de OpenImageDenoiser; corrigido.
- Render seguinte gerou PNGs, mas montagem MP4 falhou por ausência de ffmpeg; corrigido.
- Imagens mostraram solo inclinado porque o proxy usava coordenadas Roblox Y-up como Blender Z-up; corrigido no renderizador.
