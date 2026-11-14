# MISSÃO TEMPORÁRIA PARA CODEX — RECONSTRUIR O MUNDO 1 / FLORESTA DAS MEMÓRIAS
> Criador: PHBritoDev. Prioridade ALTA. Ler este arquivo COMPLETO antes de mexer no jogo. **Ao concluir e comprovar os resultados, excluir ESTE arquivo do repositório no PR final.** Não excluir AGENTS.md nem documentos originais.

## 0. Fonte da verdade — LEITURA OBRIGATÓRIA
Ler e seguir, nesta ordem:
1. `AGENTS.md` — prompt principal operacional dos agentes, regras de visual, QA, segurança e publicação.
2. `ROBLOX_GAME_MOBILE_CONTEXTO-1.md` — limitações reais: criador trabalha **somente pelo Android, sem PC próprio**, prefere custo zero; histórico do projeto.
3. `docs/VISAO_HISTORIA_E_MUNDOS.md` — história proposta de sete mundos Brainrot/Dreamcore; não reescrever história, gênero, mecânicas ou personagens sem autorização. A prioridade atual expressa é o cenário do **Mundo 1**.
4. `docs/MUNDO1_FLORESTA_CINEMATOGRAFICA_V2.md` — meta visual da floresta, Árvore da Primeira Memória, trilha S, pôr do sol/noite; tratar descrições antigas de colinas como **superadas pelo pedido mais recente de terreno PLANO**.
5. `docs/ASSETS_CURADOS_MUNDO1.md`, `docs/AGENTE_VISUAL_ROBLOX.md`, `docs/PLANO_TECNICO_MAPAS_DREAMCORE.md` — licenças, limites de PBR e preview, pipeline.
6. `src/server/DreamcoreWorld.server.luau`, `src/client/Welcome.client.luau`, `default.project.json`, `.github/workflows/` e `tools/roblox-qa/`.
Esta tarefa complementa as fontes; NÃO substituir as decisões do criador por conjecturas ou por sugestões antigas que ele rejeitou.

## 1. OBJETIVO DO CRIADOR — NÃO NEGOCIÁVEL
Criar, de verdade, uma **floresta de fantasia nostálgica premium, memorável, imersiva e jogável no ROBLOX ANDROID**, buscando a **qualidade de direção de arte** que o criador associa a *Genshin Impact*, *Ori* e jogos de fantasia visualmente excelentes. **Inspiração por princípios**, NÃO copiar mapas, assets, personagens, shaders, texturas, músicas, arte identificável ou IP alheio.

Direção: clareira e bosque amplo **predominantemente PLANO**, horizonte livre, árvores 3D bonitas e não genéricas, escala orgânica, vegetação rica em múltiplas camadas, solo atraente com transições naturais, caminho navegável, sol dourado filtrado pelas copas, sombras frescas verde-azuladas, atmosfera sonhadora e nostálgica sem neblina excessiva, pôr do sol e noite estrelada, ângulos cinematográficos com landmark **Árvore da Primeira Memória**. *Dreamcore* = familiar e mágico, não conjunto aleatório de blocos fluorescentes. Identidade própria e consistência visual acima de quantidade de partes.

O criador reclamou repetidamente: **“mudou absolutamente nada”, “árvores completamente genéricas”, “chão feio”, “montanhas frias”, “iluminação simples”, “não quero algo feito de qualquer maneira”**. Tratar estes comentários como bugs de aceitação REAIS, não preferência secundária.

## 2. O QUE O JOGADOR VIU / PROBLEMAS REAIS
- Primeira captura Android: somente interface e céu, sem floresta. Causa identificada: escrita em `Terrain.Decoration` / `Terrain.GrassLength` NotScriptable interrompia o gerador. Corrigido em `c89b985`. Precisa continuar havendo teste de inicialização e tratamento de falhas.
- Segunda captura Android: terreno com morros/volumes grandes dominando o enquadramento; trilha irregular e sem sofisticação; árvores pequenas e genéricas, vegetação rala; pouco impacto de iluminação. **Não afirmar que isso está resolvido com base em proxy**.
- A V26 achatou algumas colinas; V27 redesenhou parte do terreno e iluminação; V28 adicionou shifts de cor. **Ainda não existe evidência de aceitação dessas versões pelo cliente real**.
- **FALHA CRÍTICA DE ENTREGA**: último envio para Roblox confirmado era a V25 corrigida, enquanto `main` está na V28 (`125e321601453879e34091d8ff49a4647b642cc1` na criação deste documento). O criador abre o Place Roblox e não vê as alterações recentes! Investigar distinção entre COMMIT, BUILD, PREVIEW, PUBLICAÇÃO e a versão de fato executada antes de prometer que “mudou”. Não publicar produção às cegas.
- `Workspace.StreamingEnabled` pode afetar aparecimento de assets; considerar inicialização/tempo de carregamento e falhas de `InsertService:LoadAsset`, se relevantes; medir em cliente.
- O projeto é gerado NO SERVIDOR: o .rbxlx Rojo não é um mapa pré-cozido; entrar em jogo é necessário para gerar o Terrain e colocar as árvores. Verificar inicialização, spawn firme e geração antes de entregar.

## 3. AÇÕES TÉCNICAS PRIORITÁRIAS — IMPLEMENTAR, NÃO SOMENTE DOCUMENTAR

### A. Reconstrução do terreno / solo (prioridade 1)
- Eliminar TOTALMENTE colinas artificiais, anéis de `Terrain:FillBall` que se projetam como montanhas e elevações frias no cenário principal; manter mapa essencialmente plano de caminhada, com variações muito sutis e deliberadas. Não inventar montanhas “na distância”; usuário disse tirar as montanhas.
- Não trocar montanhas por um enorme bloco monocromático de grama Roblox. Construir linguagem de chão: variedade coerente de materiais `Grass`, `LeafyGrass`, `Ground`, terra aquecida pelo sol, manchas de musgo e áreas de folhas caídas ou equivalentes originais, bordas macias. Cuidado com `FillBall` cobrindo o caminho, criando microdegraus ou buracos. Preferir tapetes de vegetação com malhas 3D leves e licenciadas quando necessário.
- Caminho largo, contínuo e navegável em S, sem “degraus de caixas”, com contornos orgânicos e transições suaves solo/caminho. Usar overlays/folhas/pedrinhas com colisão desabilitada e quantidade limitada. Evitar sobreposição Z-fighting. Medir distância e inclinação.
- Garantir terreno firme desde o spawn até árvore ancestral, ponte, rio, lago, margens. Proteger corredor de movimentação e áreas de combate futuras.

### B. Árvores e composição premium (prioridade 2)
- O sucesso não é “73 modelos instanciados”: revisar escala, silhueta, cor, variedade de espécie, orientação de galhos, repetição, distribuição, raízes no solo, copas entrelaçadas. Formar primeiro plano/médio/fundo. Enquadrar a trilha sem bloquear visibilidade ou colisão.
- Priorizar árvores e folhas 3D com malha/textura decentes, variedade de alturas, bases e troncos naturais, massas de copa bonitas. Não produzir árvores de cilindro + três esferas como solução principal. Uma árvore ancestral única e grandiosa deve ser o ponto focal.
- É autorizado MODELAR ASSETS ORIGINAIS no Blender (headless possível) e exportar/importar via pipeline Roblox quando realmente viável e comprovado, ou USAR modelos de Creator Store/Roblox licenciados e verificados, ou bibliotecas externas apenas com licença que permita integração e distribuição em Roblox. Identificar autor, URL, tipo de licença, permissões, polígonos, PBR, dimensões, scripts removidos e contagem de transparências. **NÃO usar modelos de origem duvidosa, scripts externos, assets copiados do Genshin/Ori ou links não verificados.**
- Base disponível: Forest Pack `6432306802` (por @Roblox; possui scripts no pacote e exige removê-los), Synty Nature Pack `6933438443` (@Roblox, fonte Roblox/Synty). Os modelos podem falhar ao carregar no jogo; verificar `pcall`, saída, fallback aceitável e qualidade percebida. Criar malhas do zero se isso de fato oferecer qualidade superior e importação possível.

### C. ILUMINAÇÃO — prioridade artística máxima do criador
- **Iluminação é a alma do cenário**, não um ajuste cosmético. Planejar fotometria e composição por hora do dia: “Golden Nostalgia” com sol dourado quente penetrando copas/folhagem, luz fria nas sombras sem matar verdes, relação de exposição controlada; crepúsculo lírico azul-violeta legível; noite com estrelas e contraste suave.
- Trabalhar `LightingStyle=Realistic`, `PrioritizeLightingQuality`, `Lighting.ClockTime`, `Brightness`, `Ambient`, `OutdoorAmbient`, `ColorShift_Top/Bottom`, `EnvironmentDiffuseScale`, `Atmosphere`, `Clouds`, `ColorCorrectionEffect`, `SunRaysEffect`, `BloomEffect`, `DepthOfFieldEffect`. Verificar quais props afetam o cliente Android e evitar configurações não editáveis ou incompatíveis.
- Evitar aparência lavada/alaranjada demais, névoa encobrindo árvores e bloom exagerado. Demonstrar iluminação REAL em capturas nos mesmos 3+ ângulos e ao menos dois horários (quando captura real existir).
- Otimizar para Android: sombras de objetos próximos importantes, poucos lights dinâmicos, LOD, transparência e draw calls sob controle. Sem promessas de FPS sem medição.

### D. Colisões / gameplay básico (prioridade 3, deve funcionar)
- Spawn com colisão e apoio adequados; personagens não podem cair no mapa ou ficar enterrados. Troncos relevantes, rochas sólidas, ponte e barreiras possuem colisões CORRETAS quando exigido; folhas, grama, flores e pequenas partículas não bloqueiam deslocamento. Atenção: utilitário `optimizeDecorativeMesh` desativa `CanCollide` em todas as malhas; não desativar colisão de árvores/rochas de navegação indiscriminadamente. Dividir decoração não colisiva de troncos/estruturas físicas ou usar proxies invisíveis baratos, precisamente alinhados.
- Garantir `CanTouch`, `CanQuery` conforme finalidade; evitar tocar/consultar desnecessariamente objetos cosméticos. Testar caminho da clareira ao marco ancestral, margens, ponte e obstáculos.
- Criar testes estruturais assertivos para solo/spawn e navegação/collision proxies, não apenas contar modelos ou parts.

### E. Fluxo de entrega: o criador usa SÓ ANDROID
- O criador NÃO tem PC Windows/macOS próprio; não peça Studio manualmente a cada rodada, nem contas de cobrança novas. Preferência custo zero (até R$10 se realmente necessário e previamente aprovado). Ele quer que os agentes executem os passos sem encerrar a cada microetapa.
- Inspecionar o estado do GitHub antes de alterar; evitar sobrescrever commits de outros agentes. Trabalhar em branch/PR se necessário; após QA e revisão, merge seguro para `main` com SHA/PR explícito.
- Executar `rojo build`, QA estrutural, Open Cloud Luau headless, preview Blender de pelo menos 3 ângulos e revisor visual. Ao falhar, examinar LOGS (503 externo vs bug de código), corrigir e retestar na MESMA execução quando possível.
- **Blender proxy nunca é screenshot do Roblox!** A inspeção não reproduz corretamente `SurfaceAppearance`, alpha cards, água e iluminação da engine. Só aprovar aparência real com screenshot/playtest real do Roblox Studio/cliente conectado. Não alegar FPS Android sem aparelho/telemetria.
- Se não houver Studio/MCP, marcar honestamente “visual real pendente”, manter artefatos, evitar afirmar sucesso estético. Planejar captura fiel em Studio MCP quando houver acesso compatível.
- **Resolver DESALINHAMENTO DO DEPLOY**: um commit no GitHub não atualiza o jogo Android. Confirmar qual Place recebe build e qual versão Roblox foi publicada; deploy de staging/espelho somente em destino conhecido, com autorização e validações suficientes, sem sobrescrever produção ou trabalho valioso. Testar entrada e cenário após publicação; provar via run e versão Roblox, não apenas link de commit.

## 4. CHECKLIST DE ACEITAÇÃO (CRITÉRIOS DE REJEIÇÃO)
- [ ] Sem montanhas grandes nem paredões frios em torno do spawn e da trilha; chão plano e horizonte limpo.
- [ ] Chão visualmente rico, materiais e vegetação em camadas sem aparência de bloco uniforme.
- [ ] Árvores 3D naturais e belas, variedade de silhuetas e densidade cuidada; Árvore da Primeira Memória reconhecível.
- [ ] Iluminação dourada/fria harmoniosa no pôr do sol e noite nostálgica legível.
- [ ] Spawn, caminho, ponte e marcos com colisões e mobilidade corretas; decorativos não bloqueiam.
- [ ] Sem scripts ativos de terceiros, assets com licença verificada e uso Roblox permitido.
- [ ] Build Rojo + QA estrutural + headless + Blender proxy/reviewer analisados; falhas corrigidas e evidências arquivadas.
- [ ] Evidência REAL Roblox Studio/cliente ou declarar explicitamente indisponível; não afirmar aprovação estética sem evidência.
- [ ] Arquivos integrados de modo seguro em `main` após verificações suficientes, sem sobrescrever alterações.
- [ ] Publicação separada, controlada, sem alegação de mudança no Roblox se apenas código mudou.
- [ ] NÃO encerrar com “planejei” quando é possível produzir alterações testáveis; preferir correções concretas e profundas.

## 5. COMO TRABALHAR / DICAS PARA CODEX
1. Antes de tudo, conferir a versão efetiva do jogo no Roblox e a geometria que o servidor gera. Distinguir `Saved` vs `Published` e o Place de teste. Investigar crashes iniciais e `InsertService`.
2. Estabelecer critérios visuais verificáveis e capturas-base, comparando o MESMO enquadramento antes/depois; não usar contagens de instâncias como proxy de qualidade. Registrar lacunas de QA.
3. Fazer uma reconstrução controlada e coerente de terreno, trilha, vegetação e iluminação; evitar centenas de ajustes triviais isolados sem mudança perceptível.
4. Priorizar materiais, silhuetas, escala, linguagem de luz e navegação antes de partículas ou detalhes sem valor perceptivo.
5. Fazer validação em CI e examinar artefatos `scene_qa.json`, `visual_review.json` e imagens proxy. QA aprovado sozinho não é “ficou lindo”.
6. Testar colisões separadamente e proibir regressões de caminho/spawn. Usar máscaras/proxies de colisão eficientes.
7. Documentar assets e licenças de forma concisa e confiável; sem segredos Roblox no código.
8. Entregar PR/commit(s) verificáveis, link de workflow, resultado visual, limitações honestas, e próximo ajuste prioritário. Evitar contato repetitivo com o criador, que estará no celular e às vezes dormindo.
9. **DELEÇÃO TEMPORÁRIA OBRIGATÓRIA:** após implementar e validar o trabalho, remover `docs/TEMP_CODEX_RECONSTRUCAO_FLORESTA_PREMIUM.md` em um commit do PR final (ou da branch segura antes do merge); confirmar no diff que o arquivo foi apagado. Preservar documentação duradoura e `AGENTS.md`. Se trabalho incompleto, deixar issue aberta e não alegar conclusão.

## 6. NÃO CONFUNDIR AMBIÇÃO COM CÓPIA
Genshin/Ori são referências de **composição, direção de luz, densidade visual, cor e legibilidade**, não autorização para copiar assets. Estudar documentação oficial Roblox e referências licenciadas; usar decisões originais. A ambição é um mundo melhor e memorável NO ROBLOX, não prometer equivalência tecnológica/visuais exatos entre engines.

**ENTREGÁVEL:** primeiro mundo jogável, terreno plano, chão orgânico premium, floresta 3D atraente, iluminação cinematográfica, colisões, boa experiência Android, evidências de QA e publicação controlada quando apropriada. Não enviar só um plano.
