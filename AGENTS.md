# Regras dos agentes — Roblox Game Mobile

## O que o criador exige
- Dois desenvolvedores em parceria; melhorar o jogo de forma proativa, sem ficar pedindo testes manuais a cada alteração.
- Floresta do Mundo 1: atmosfera nostálgica cinematográfica, sombras frias + sol quente, pôr do sol e noite estrelada, composição natural; referências gerais Genshin Impact e jogos de fantasia, **não copiar assets ou músicas**.
- Mobile/Android, custo zero de preferência e sem contas de cobrança novas.
- **Responder em português, de forma curta.** Não encerrar uma rodada apenas dizendo que o teste ainda está rodando quando puder conferir resultados e corrigir o problema na mesma sessão.

## Ciclo obrigatório a cada alteração de mapa/renderizador
1. Editar `src/server/DreamcoreWorld.server.luau` (fonte única). Não manter espelhos de código conflitantes.
2. Conferir os workflows: `build-rojo.yml`, `qa-roblox.yml`, `visual-proxy-roblox.yml`. O push em `main` dispara automaticamente; não há despacho obrigatório.
3. Verificar conclusão e logs GitHub Actions; se falhar, **investigar e corrigir antes de marcar como concluído**. Evitar sequências de commits que cancelam a renderização anterior continuamente.
4. Baixar artifact `PREVIEW-PROXY-nao-e-screenshot-roblox` (se possível), revisar os três ângulos e `contato_3_angulos.png`, `visual_review.json` e `scene_qa.json`.
5. Registrar o que melhorou e o que permanece ruim. Fazer nova correção e novo ciclo se necessário, sem pedir foto do criador.
6. **Nunca afirmar que o Blender é captura do Roblox**; seu chão, materiais, luz, MeshParts e água são aproximados, não fiéis.
7. Somente afirmar aprovação estética após inspeção de imagens reais e teste num cliente/Studio. O agente automático detecta defeitos técnicos e dá alertas, não substitui avaliação artística humana.
8. **Não publicar no Roblox automaticamente.** A publicação do jogo principal permanece em workflow manual separado. A cópia espelho precisa de Universe/Place separado antes de ativação.

## QA de geometria
`tools/roblox-qa/scene_quality.py` verifica integridade do snapshot, contagens e interseção das árvores na trilha.
`tools/roblox-qa/review_visual.py` verifica os 3 renders PNG, diversidade mínima de imagem e câmera, brilho, gera contato e relatórios. **Alertas de estética não aprovam a arte.**
`tools/roblox-qa/snapshot_scene.py` executa o próprio gerador na engine Roblox headless e extrai geometria sem salvar ou publicar o Place.
`tools/roblox-qa/render_scene.py` reconstrói previsualização Blender, não captura o cliente Roblox.

## Audios e assets
Assets Roblox Creator Store/royalty-free apenas com licença/autor identificado e após inspeção do conteúdo; evitar scripts arbitrários de terceiros. Synty Nature Pack @Roblox integrado com seleção limitada, testado em Open Cloud.
Não inserir música qualquer. Só integrar áudio cuja licença e ID da Creator Store estejam verificados. Som espacial por área, mix suave e silêncio significativo onde necessário.

## Segurança e honestidade
- Nunca publicar chaves Roblox, não imprimir secrets nem logs com credenciais.
- Evitar serviços pagos, mudanças de conta ou compras sem autorização.
- Não inventar screenshot, FPS, sucesso de compilação ou conclusão de workflow.
- Captura real via Roblox Studio MCP precisa de máquina compatível conectada; ainda não disponível.
