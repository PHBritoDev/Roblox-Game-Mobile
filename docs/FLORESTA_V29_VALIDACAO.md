# Floresta das Memórias — reconstrução V29

## Alterações concretas

O piso usa um campo contínuo de voxels a 4 studs com a mesma ocupação em toda a clareira. Grass, LeafyGrass e Ground variam por ruído espacial coerente; trocar material não empilha volumes. A trilha S e os acessos laterais são máscaras do mesmo piso. Rio e lago são depressões do campo, sem montanhas ou anéis elevados. Folhas caídas originais, sem colisão e sem transparências, suavizam as bordas.

A ponte atravessa o rio perpendicularmente, com 64 studs, duas cabeceiras apoiadas e corrimãos. O círculo cerimonial deixa aberta a entrada da trilha. Pedras e árvores respeitam os acessos ao lago e à ponte. Árvores Forest Pack mantêm colisão de suas malhas de tronco; folhagem continua não colisiva. Árvores Synty de malha única usam proxies estreitos; rochas sólidas preservam colisão nativa. A cobertura de gameplay ainda exige Humanoid e cliente real.

As árvores do corredor aproximam-se da trilha com afastamento variável, preservando a abertura central e a árvore ancestral. Os mesmos assets curados continuam em uso: nenhuma nova dependência ou modelo sem licença foi adicionado. Os perfis de luz reduzem a dupla coloração laranja (ColorShift + correção de cor), preservam sombras frias e diminuem névoa. Removidos planos retangulares de bruma junto ao chão. Aparência real ainda não aprovada.

A chegada aguarda conclusão do servidor e solicita streaming da área inicial. Exibe a versão do mundo e a versão Roblox. Falhas do gerador são capturadas com spawn de emergência e estado Failed; falhas dos pacotes têm fallback autoral. O timeout de chegada informa falha sem fingir que carregou.

## Evidências e limites

Build Rojo, auditoria estática e testes de regressão são separados do QA na engine. O snapshot executa o gerador da branch em memória, sem salvar ou publicar. Mede apoio, normais, desníveis e obstáculos em 825 pontos de 12 rotas/faixas; verifica spawn, colisões e ausência de scripts externos. Há execução adicional com ambos os pacotes indisponíveis.

O preview usa 5.776 amostras reais do Terrain, incluindo materiais e água. Continua sendo **Blender proxy, não screenshot Roblox**: malhas, alpha cards, PBR, água e iluminação não são reproduzidos fielmente. As três câmeras são registradas em viewpoints.json. O baseline V28 não continha o Terrain e não serve como comparação fiel de chão/iluminação.

Não há Studio MCP conectado, playtest Android, medição de FPS, polígonos por instância ou aprovação estética. O número de modelos e o reviewer técnico não comprovam qualidade premium.

## Publicação: código e Place são coisas diferentes

Último envio confirmado: [workflow 43629039952](https://github.com/PHBritoDev/Roblox-Game-Mobile/actions/runs/43629039952), commit `d75f0e54b0e27d1d7ee43ca6027f24be5bc9c353`, modo Published, Universe `2660433574`, Place `6947682498`, **versão Roblox 5 / mundo V25**. A consulta headless desta reconstrução confirmou `game.PlaceVersion=5` e `WorldVersion=25` no script armazenado antes de executar V29 em memória.

**V29 não foi publicada no Roblox.** Merge e build não alteram a experiência Android. Não existe destino espelho separado confirmado neste repositório. O workflow de publicação permanece manual; nenhuma solicitação antiga V7/V25 foi reutilizada para publicar esta mudança. A próxima publicação precisa de destino e autorização compatíveis, seguida de entrada e captura real. Saved também não é Published.

Pendências de visual real, Android e publicação: [issue #3](https://github.com/PHBritoDev/Roblox-Game-Mobile/issues/3), mantida aberta. Integração: [PR #2](https://github.com/PHBritoDev/Roblox-Game-Mobile/pull/2).

## Resultados técnicos da execução

- 17 testes de regressão Python: rejeição de buracos, degraus, obstáculos, proxies inválidos, evidência ausente, injeção de falha de assets e retries HTTP somente em GET.
- 825 amostras de apoio/colisão aprovadas com os pacotes disponíveis e outras 825 no fallback. Trilha central medida: 286,13 studs; piso em Y=0, com spawn em Y=0,05 e tabuleiro em Y=0,25.
- Falhas encontradas e corrigidas pelo QA: terreno originalmente em Y=2 por ocupação do voxel; cabeceiras enterradas; árvores/galhos no acesso ao lago; raízes ancestrais no fim da trilha; preparação assíncrona da colisão do Terrain exposta quando os pacotes falham sem yield.
- Prontidão física agora exige quatro sondagens de terreno seco, com timeout explícito. Após um tick de integração das estruturas, o servidor marca Ready. Texto de carregamento fica visível durante a espera e Failed interrompe o timeout.
- [Headless, fallback e preview](https://github.com/PHBritoDev/Roblox-Game-Mobile/actions/runs/43632894637): artefato `PREVIEW-PROXY-nao-e-screenshot-roblox`, incluindo scene.json, scene_qa.json, fallback/scene_qa.json, imagens e visual_review.json. O PR registra a revisão das imagens e os checks finais de main.

## Assets mantidos

Forest Pack `6432306802`, autor/publicador @Roblox: [Creator Store](https://create.roblox.com/store/asset/6432306802/Forest-Pack). Synty Nature Pack `6933438443`, @Roblox/Synty: [Creator Store](https://create.roblox.com/store/asset/6933438443), [permissão oficial para criações Roblox](https://devforum.roblox.com/t/free-synty-asset-packs-released-in-the-marketplace/1283755/). Uso restrito a este projeto Roblox conforme a curadoria existente; nenhuma licença externa é presumida.

Scripts são removidos antes de parentear clones. O snapshot registra dimensões e flags físicas por parte; o QA confirma ausência de LuaSourceContainer no mundo gerado. Forest Pack mantém SurfaceAppearance/folhas alfa originais; Synty mantém suas malhas/texturas. Contagem de triângulos por clone e custo de alpha overdraw ainda não medidos: estes limites continuam na issue #3. Não foram introduzidos novos assets externos.


## Inspeção dos três previews

Renders e reviewer técnico concluídos sem erros; as três câmeras permaneceram nas coordenadas predefinidas. No spawn, a trilha e a variação do solo agora aparecem no preview amostrado. O ângulo de aproximação permanece muito ocluído pelos volumes brancos usados para representar folhas/malhas; não é possível concluir como as folhas alfa realmente se comportam no Roblox. O ângulo alto identifica o landmark, mas também exagera massas de copa. **A arte não está aprovada por estas imagens.** O próximo ajuste visual deve partir de captura real, conforme issue #3.
