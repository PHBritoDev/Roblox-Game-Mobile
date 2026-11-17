# Regras dos agentes — Roblox Game Mobile

## O que o criador exige
- Dois desenvolvedores em parceria; melhorar o jogo de forma proativa, sem ficar pedindo testes manuais a cada alteração.
- Floresta do Mundo 1: atmosfera nostálgica cinematográfica, sombras frias + sol quente, pôr do sol e noite estrelada, composição natural; referências gerais Genshin Impact e jogos de fantasia, **não copiar assets ou músicas**.
- Mobile/Android, custo zero de preferência e sem contas de cobrança novas.
- **Responder em português, de forma curta.** Não encerrar uma rodada apenas dizendo que o teste ainda está rodando quando puder conferir resultados e corrigir o problema na mesma sessão.

## Cadência de execução: entregas substanciais por rodada
- **Não concluir a rodada depois de um ajuste pequeno quando ainda houver trabalho concreto e seguro possível.** O criador quer evolução perceptível; combinar correções, vegetação, atmosfera, vida ambiental e QA em um lote coerente, não apenas planejamento ou um comentário de status.
- Antes de começar, inspecionar `main`, PRs e workflows recentes; respeitar a branch do outro agente. Priorizar mudanças reais com commits e testes. Agrupar mudanças do mesmo subsistema em uma PR substancial; separar PRs por responsabilidade quando houver concorrência ou rollback independente.
- Continuar a trabalhar após um primeiro commit: escrever testes, revisar artefatos disponíveis, resolver regressões, conferir custos mobile, procurar o próximo problema independente e reconciliar PRs com segurança. **Não encerrar somente porque um workflow ficou pendente**; não saturar a API com retries em sequência.
- O tamanho do lote deve ser **expressivo, mas conservador para estabilidade**. A floresta deve crescer em blocos moderados com várias camadas de vegetação e pontos de interesse; evitar expansão vazia ou dezenas de objetos sem propósito. Não introduzir árvores genéricas na cena principal.
- Direção atual do usuário: manhã dourada nostálgica, poente coral/laranja/roxo, noite estrelada com aurora animada sutil; gramados, flores, aves, coelhos, grilos quando houver som licenciado. Detalhes: `docs/REFERENCIAS_VISUAIS_MUNDO1_2026-11-16.md`. **Não alterar a skin** nesta fase.
- Testar sempre o que mudou. Só mesclar PR **fora de draft**, sem conflito, com checks necessários concluídos e verdes, risco/rollback revisados e evidência suficiente; se falhar, corrigir ou registrar bloqueio. CI verde não equivale a FPS/visual real de Roblox.
- Pode haver várias melhorias por rodada, mas **não ampliar o escopo sem limites**: preservar entrada no servidor, colisões, spawn, streaming e o trabalho já aprovado. Publicação Roblox continua manual e protegida.
- No chat, registrar somente resultados verificáveis e bloqueios excepcionais, em poucas linhas; não alegar evolução que ficou apenas no plano.

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


## Protocolo de entrega contínua e desbloqueio de PRs (diretriz do criador — 17/11/2026)
**Objetivo prioritário: fazer as melhorias chegarem ao jogo, não acumular dezenas de PRs paradas.** A floresta ainda está visualmente genérica. Aproveitar o trabalho existente com velocidade **sem trocar estabilidade por quantidade de merges**.

### Agente principal — Evoluir jogo Roblox
- No início de cada rodada, consultar o backlog de PRs abertas e seus comentários de revisão. **Corrigir e consolidar PRs existentes antes de abrir outra PR do mesmo subsistema.** Evitar sequências de PRs concorrentes para o mesmo `DreamcoreWorld.server.luau`.
- Não deixar PR em draft indefinidamente: terminar implementação, adicionar testes/evidências e marcar **Ready for review** quando os critérios estiverem satisfeitos. Draft só se ainda houver trabalho objetivo, com checklist e responsável no corpo da PR.
- Corrigir primeiro os defeitos documentados pelo integrador; quando duas PRs se sobrepõem, consolidar numa branch própria, indicar PRs substituídas e preservar o melhor das duas. **Não apagar melhorias para fazer CI passar.**
- Priorizar lotes que produzam transformação perceptível: silhuetas de árvores naturais, cobertura do solo, flores, pontos de interesse, iluminação e fauna leve; proteger spawn, trilhas, pontes, streaming, colisões e entrada rápida. Fazer regressões de fallback e orçamento de Parts.
- Entregar na PR: HEAD SHA; resumo de mudanças; tabela de checks completos; contagem de Parts e QA de navegação; inspeção de artefatos proxy (três ângulos + relatórios); riscos; plano de rollback; aviso explícito do que não foi testado no Roblox/Android. Solicitar revisão visual real quando a aprovação estética depender dela.

### Agente integrador — Bugs e Melhorias
- Revisar **em lote** PRs do principal, priorizar desbloquear 2–5 entregas coerentes por rodada, atualizar branches próprias quando necessário; não modificar a branch do outro agente. Fazer correções independentes ou pedir patches precisos ao autor.
- Não usar `draft` como desculpa para imobilidade: explicar por comentário exatamente o que falta, ajudar a concluir a PR e, **somente depois que estiver apta**, marcá-la Ready e integrar. PR sem conflito e verde ainda pode estar insegura; observar revisões, dependências, assets, fallback e UI mobile.
- Em alterações concorrentes no arquivo gerador único, definir ordem de integração; após cada merge atualizar a base das PRs dependentes e exigir novos checks no SHA atualizado. Evitar aceitar simultaneamente branches antigas que sobrescrevam ou revertam avanços.
- Para cada merge elegível: comprovar checks essenciais verdes e concluídos, evidências de QA/visual suficientes ao escopo, segurança, orçamento e rollback; mesclar, confirmar novo SHA da `main` e acompanhar validação pós-merge. Registrar com clareza falhas e bloqueios reais.
- **Indicador de produtividade**: total integrado com segurança, correções resolvidas, regressões evitadas e melhoria real do jogo — não o número de PRs abertas ou comentários.

### Publicação e teste no Android
- O criador **autoriza publicar no jogo principal após um lote validado**, para testar no Android. Isso **não** autoriza pular CI, revelar segredos, pagar por serviços ou publicar código com erro conhecido.
- Publicação continua **operação separada e explícita** pelo workflow manual protegido; não ocorre automaticamente por merge. Se o mecanismo de disparo manual autorizado estiver disponível, usá-lo **após** integrar e verificar a `main` e registrar Place/versão sem divulgar credenciais. Se não estiver disponível, informar o bloqueio exato e oferecer o caminho manual, **sem afirmar que o Roblox foi atualizado**.
- Nunca confundir proxy Blender com imagem de Roblox, nem afirmar FPS Android sem teste real. Plano de rollback da `main` e da versão publicada antes do envio.
