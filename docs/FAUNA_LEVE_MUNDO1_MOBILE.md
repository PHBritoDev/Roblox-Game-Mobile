# Fauna ambiental leve: correcoes e borboletas dos prados

## Contexto
A floresta ja continha tres coelhos e tres passaros, além de aurora local. Este lote complementa a expansao sem editar gerador principal e sem competir com a PR #38 (samambaias premium).

## Correcoes
- Coelhos só aparecem em solo firme seco e dentro da area gerada; evitam lago, rio, ponte, caminhos e limites. Isso previne animais submersos, na trilha e no vazio. A varredura por raycast usa apenas Terrain e só ocorre periodicamente.
- Passaros voam de manha/à tarde e deixam de aparecer durante a noite; transicao nao modifica gameplay.
- Coelhos e passaros com modelos inicialmente fora de Workspace, eliminando breve pilha no ponto (0,0,0) antes de ForestState=Ready.

## Nova vida dos prados
- Quatro borboletas estilizadas originais: cinco Partes ancoradas por modelo (20 total), animadas so no cliente a ate ~11 Hz, sem rede, colisoes, sombras, texturas externas ou scripts importados.
- Só aparecem entre 6h18 e 17h42 de ClockTime, quando a floresta esta Ready, perto do jogador (raio maximo 105 studs), em solo firme seco. Ocultas sem destruir/recriar partes para reduzir alocacoes.
- Não cria nenhum Som: grilos noturnos ainda dependem de um asset de audio autorizado e realmente escutado; nao copiar fonogramas da internet.

## QA/limites
- Unitarios de habitabilidade e budget em tests/qa.
- Verificar Roblox Studio/Android real antes de aprovar estetica dos modelos. Blender proxy nao mostra wildlife local nem aurora.
- Precisa de medicao de FPS e memória em celular, sem alegar resultado aqui.
- Se o terreno mudar, revalidar os limites e a geometria protegida em `safeRabbitHabitat` e `validGround`.

## Rollback
Reverter os commits da PR: remove borboletas e restaura logica anterior dos coelhos/passáros; nenhuma mudanca de terreno, rede, PlayerData ou publicacao Roblox. Nunca publicar automaticamente.

## Referencia oficial
- https://create.roblox.com/docs/performance-optimization/improve (reduzir trabalho de eventos de frame)
- https://create.roblox.com/docs/workspace/streaming (carregar mundo grande sem obrigar todos objetos no cliente)
