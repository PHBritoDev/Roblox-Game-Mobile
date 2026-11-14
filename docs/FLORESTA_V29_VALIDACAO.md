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

As evidências finais e a pendência de visual real serão vinculadas no PR e na issue de acompanhamento.
