# PROMPT TEMPORÁRIO PARA O CODEX — RECONSTRUÇÃO VISUAL DE VERDADE DA FLORESTA DREAMCORE
**Projeto:** PHBritoDev/Roblox-Game-Mobile · **branch de integração:** main
**Obrigação:** implementar, testar e revisar; quando terminar, remover ESTE documento temporário no PR/commit final. Não remover AGENTS.md nem a documentação permanente.

## Contexto obrigatório
Leia antes de agir:
- `AGENTS.md`
- `ROBLOX_GAME_MOBILE_CONTEXTO-1.md`
- `docs/VISAO_HISTORIA_E_MUNDOS.md`
- `docs/MUNDO1_FLORESTA_CINEMATOGRAFICA_V2.md`
- `docs/ASSETS_CURADOS_MUNDO1.md`
- `docs/AGENTE_VISUAL_ROBLOX.md`
- `docs/FLORESTA_V29_VALIDACAO.md`
- `src/server/DreamcoreWorld.server.luau`, `src/client/Welcome.client.luau`, `default.project.json`, workflows e QA.

## Situação real relatada e comprovada pelo criador
O jogo está publicado na versão do Mundo V32, mas a **captura real do Android** revelou uma floresta visualmente muito pobre:
- árvores de troncos retangulares e copas de esferas verdes, claramente placeholders;
- terreno muito amplo, aberto e quase vazio, com manchas artificiais de grama/terra;
- poucos arbustos, plantas, flores, folhas e detalhes;
- iluminação plana, sem luz dourada atravessando copas ou sombras emocionais;
- rio parecendo faixa azul sem margens bonitas;
- plataforma plana com borda/horizonte visivelmente abrupto;
- ausência da densidade e profundidade típicas de uma floresta mágica;
- aparência geral de protótipo, longe de uma floresta premium.

Também houve falhas observadas no Android em `ForestState=Failed`, incluindo a etapa `LoadingSynty`. A V32 envolveu o trecho Synty e Forest Pack com tratamento de erro, mas **evitar crash não é o mesmo que garantir assets bonitos carregados**. A captura mais recente confirma que o fallback geométrico é insuficiente. Examine a situação do repositório e a versão efetivamente publicada antes de concluir a causa; não presuma que InsertService realmente funcionou no cliente.

**Prioridade máxima:** deixar a melhora VISIBLEMENTE GRANDE no Roblox real e garantir que, mesmo sem pacotes externos, a floresta não pareça um conjunto de cilindros com bolas. Alterar só cor, brilho ou número de partes não atende ao objetivo.

## Objetivo do criador
Criar o **Mundo 1 — Floresta das Memórias**, um mapa original e jogável para **Roblox Android**, com atmosfera Dreamcore/fantasia nostálgica de padrão artístico premium.

**Referências obrigatórias de princípios de direção artística:** `Genshin Impact`, `Ori` e outros jogos de fantasia visualmente excelentes: composição, cor, silhueta, camadas de floresta, ambientação, iluminação quente/fria, profundidade e beleza natural. **Não copiar nenhuma textura, mapa, mesh, personagem, áudio, marca, shader protegido ou asset dos jogos referenciados.** Inspiração não significa que a engine Roblox reproduza exatamente a qualidade técnica desses jogos.

O criador quer:
- terreno **predominantemente PLANO**, sem montanhas frias, paredões, grandes elevações ou blocos vazios;
- solo lindo, orgânico, bem distribuído com grama, musgo, terra, folhas e transições naturais, sem repetição agressiva nem buracos;
- árvores **3D verdadeiramente belas**, variedade de espécies e silhuetas naturais, galhos, troncos e copas convincentes, densidade planejada;
- floresta nostálgica, acolhedora, mágica, cinematográfica e memorável;
- luz solar dourada filtrada pelas folhas, sombras frias azul/verde, contrastes elegantes, neblina e pós-processamento moderados;
- trilha clara, árvore ancestral impactante, rio e ponte integrados ao bioma;
- colisões certas e experiência estável no Android, com boa performance;
- entrega de alterações reais, não somente planos e afirmações de “melhorou”.

## A. Diagnóstico ANTES de redesenhar
1. Auditar `InsertService:LoadAsset(6933438443)` (Synty) e `InsertService:LoadAsset(6432306802)` (Forest Pack), permissões de uso, caminhos/nome dos templates, tipos reais MeshPart/Model, falhas após o `pcall`, cloning, MeshId/TextureID/SurfaceAppearance, render/streaming e disponibilidade no Place publicado. Capturar avisos claros, flags de sucesso e quantidades efetivamente carregadas. Não contar simples `pcall` como sucesso artístico.
2. Distinguir visual de: (a) código gerador executado em Open Cloud headless; (b) asset realmente integrado ao Place/cliente; (c) fallback procedural; (d) cliente Android real. O proxy Blender não reconstrói corretamente malhas, folhas alfa, texturas PBR, sombras/atmosfera. Não inventar fotos de Roblox.
3. Inspecionar `src/server/DreamcoreWorld.server.luau` com atenção às funções `branchTree`, `plantOrReserve`, aos padrões de fallback e à falta de detalhes no primeiro plano. Verificar se falha de asset elimina a maior parte das árvores planejadas.
4. Preferir **assets de alta qualidade INCLUÍDOS NO ARQUIVO DO PLACE/PROJETO** (quando viável e licenciados), em vez de depender de `InsertService:LoadAsset` em toda inicialização. Avaliar pipeline de importação/conversão segura, propriedade/uso na Creator Store, permissões e Rojo. Não prometer soluções impossíveis ou links não testados.
5. Documentar diagnóstico com evidência técnica verificável; se for necessário separar causa de streaming/permissão/runtime, escrever um teste apropriado.

## B. Reconstruir árvores e vegetação (prioridade visual central)
- Abandonar árvores principais com `Part` tronco + copas de `Ball` como estética final. Em falha de modelos, criar um **fallback autoral realmente elaborado** por meshs licenciadas/salvas no projeto ou geometria composta de qualidade convincente, não 3 esferas por árvore.
- É autorizado criar meshes 3D originais em Blender e integrá-las ao Roblox, ou selecionar modelos prontos de Creator Store (ex.: Forest Pack @Roblox `6432306802`, Synty Nature Pack @Roblox `6933438443`) ou de fontes externas **com licença verificada permitindo uso no Roblox**. Verificar autoria, licença, carga, dependências e polígonos. Remover scripts de terceiros dos modelos antes da integração.
- Trabalhar proporção, espécies diversas, variações de galhos/copa, rotação, composição em grupos, contato da raiz com solo, foreground/midground/background, folhagem translucente onde viável e sombras seletivas. Não lotar indiscriminadamente a cena nem obstruir o caminho.
- Criar vegetação rasteira de qualidade: grupos de samambaias, tufos de grama, folhas caídas, musgo, pequenas flores, troncos caídos, pedras integradas; distribuição com lógica ecológica e visual, controlando transparência e draw calls em Android.
- A **Árvore da Primeira Memória** precisa ser um landmark único e grandioso, legível desde a aproximação pela trilha.

## C. Terreno, caminho, rio e horizonte
- Manter piso estável e essencialmente plano, sem reintroduzir anéis de montanhas ou colinas gigantes. Evitar `FillBall` que cria degraus e paredes.
- Melhorar a superfície: materiais e variações por ruído coerente, contraste natural, silhueta de bordas, detalhes distribuídos na escala do jogador, integração do solo com troncos, folhas e trilha, sem aspecto de manchas retangulares ou um campo vazio.
- Trilha em S orgânica: margens suaves, contorno legível, área caminhável clara, sem `Z-fighting` e sem pedras bloqueando o corredor.
- Rio deve ter leito, margens trabalhadas, pedras/plantas ribeirinhas, percurso natural e água legível; não ser uma faixa ciano artificial. Ponte estável, travessia com colisão adequada e acessos desobstruídos.
- Tratar o horizonte com grupos de árvores, névoa de distância equilibrada e composição, sem ocultar borda artificial com montanhas proibidas. Trabalhar limites do mundo com cuidado de gameplay.

## D. Iluminação — PRIORIDADE MÁXIMA DO CRIADOR
- Rever `LightingStyle=Realistic`, `PrioritizeLightingQuality`, `ClockTime`, `Brightness`, `Ambient`, `OutdoorAmbient`, `ColorShift_Top`, `ColorShift_Bottom`, `EnvironmentDiffuseScale`, `Atmosphere`, `Clouds`, `ColorCorrectionEffect`, `Bloom`, `SunRays`, `DepthOfField`. Confirmar quais propriedades são seguras em scripts e quais devem ficar em `default.project.json`.
- Criar relação intencional de sol quente e sombras azul-esverdeadas, luz rasante atravessando copas com sombras reais quando viável, profundidade e plano focal. Evitar lavado, cinza, excesso de bloom/laranja, ausência de contraste e neblina que engole as árvores.
- Projetar Golden Nostalgia, Cold Twilight e Starry Dream Night com visibilidade e transições suaves. Mostrar diferença nítida no cenário; calibrar com o terreno e as novas árvores, não só números arbitrários.

## E. Colisões, estabilidade, Android
- Garantir personagem não cai, spawn estável e solo caminhável; colisão sólida nos troncos/rochas/ponte e vegetação pequena não-colisiva. Validar os acessos ao lago, ao santuário e à ponte.
- LOD/render fidelity, quantidade de MeshParts/triângulos, overdraw das folhas alfa, sombras e partículas compatíveis com Android; não dizer FPS sem medir.
- O mapa **nunca pode ficar quebrado por falha em modelo externo**. `ForestState=Ready` somente quando as partes essenciais estão disponíveis, `Failed` com causa rastreável. Evitar ficar reiniciando geração ou mostrando texto enganoso.
- Dar preferência a carregamento rápido e previsível. Não executar scripts de terceiros, não carregar assets inseguros, não vazar credenciais.

## F. Execução obrigatória e critérios de aceitação
1. Verificar HEAD, branches, PRs e commits concorrentes para não sobrescrever agentes.
2. Implementar mudanças **substanciais de cenário**, com estética significativamente diferente na câmera do jogador, e não apenas microajustes. O código e assets devem efetivamente chegar ao jogo.
3. Rodar e inspecionar `rojo build`, auditoria e testes unitários, QA estrutural, execução headless e fallback sem assets, preview Blender em três ângulos, revisão visual e relatórios. Se falhar, ler logs, corrigir e retestar na mesma execução sempre que viável.
4. Tratar a **captura real do criador** (árvores de bolas, solo vazio, rio ciano, iluminação plana) como baseline de rejeição. Gerar evidência comparável, sem dizer que o proxy é foto do Roblox.
5. Validar estabilidade do sistema após alterações; sempre que possível obter captura real por Roblox Studio MCP/cliente conectado. Caso não exista, **não afirmar aprovação estética premium**, registrar como pendência.
6. Integrar em `main` com merge seguro após testes; publicar somente no Place de teste correto, após evidência e autorização aplicável, sem sobrescrever produção cegamente. Commit/merge por si só não atualizam a versão Roblox Android.
7. Arquivar evidências permanentes no GitHub e **EXCLUIR ESTE ARQUIVO TEMPORÁRIO** `docs/TEMP_CODEX_REFAZER_FLORESTA_VISUAL_ANDROID.md` ao concluir a implementação e validações. A exclusão deve estar no PR/commit final.

### Falhas que REPROVAM a entrega
- Árvores do caminho ainda parecendo cilindros com bolas.
- Floresta vazia e campo aberto sem profundidade nem vegetação baixa.
- Solo com visual artificial e rio parecido com fita azul.
- Iluminação plana sem atmosfera nostálgica.
- Modelos premium que só aparecem no headless, mas não no cliente real.
- Colisões inválidas ou falhas de inicialização.
- Resposta “melhorado” ou “QA passou” sem implementação perceptível e provas honestas.

### Orientação de eficiência / comunicação
**Economize tokens ao extremo. Não faça narração, relatórios conversacionais de progresso, nem resumo final ao criador.** Use contexto e operações de forma eficiente; concentre energia em código/arte, testes e commits. Não sacrificar qualidade, segurança ou verificações. Se for necessário registrar resultados, use PR/checks/documentos permanentes em vez de falar no chat. Ao concluir, **remova o briefing temporário**.

**Entregável:** uma floresta 3D de fantasia original, nostálgica e muito mais bonita NO ROBLOX ANDROID, com árvores premium realmente carregadas, terreno e rio bem acabados, luz cinematográfica, navegação e estabilidade verificadas. Não entregue apenas um plano.
