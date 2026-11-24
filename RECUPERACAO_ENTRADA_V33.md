# Diagnóstico: servidor preso antes de abrir o jogo (V33)

## Evidência e limite
A publicação integral do Place de teste `6947682498` foi confirmada como versão Roblox 13 no [workflow de publicação](https://github.com/PHBritoDev/Roblox-Game-Mobile/actions/runs/43672416847). A versão diagnóstica leve anterior foi publicada como versão 12 no [workflow](https://github.com/PHBritoDev/Roblox-Game-Mobile/actions/runs/43671932971). HTTP 200 apenas comprova que a Roblox aceitou o arquivo, **não** que um servidor conseguiu iniciar ou que o cliente Android entrou.

O relato “Aguardando um servidor disponível / tentando novamente” ocorre na fase de alocação/inicialização, antes da interface do jogo. A biblioteca embutida, o Terrain e a própria infraestrutura Roblox são hipóteses, não causas confirmadas; os testes Open Cloud Luau Execution não comprovam uma entrada real e podem ficar em PROCESSING.

## Mitigação reversível nesta branch
- `default.project.json`: o Place inicial não serializa a biblioteca 3D no `ServerStorage`, reduzindo a carga de desserialização **antes** da execução dos scripts.
- `bundled.project.json`: mantém a variante integral com o `assets/ForestLibrary.rbxmx` original, sem alteração de modelos nem licença.
- `src/server/DreamcoreWorld.server.luau`: permanece intacto; segue carregando Synty Nature e Forest Pack via `InsertService:LoadAsset`, removendo scripts de terceiros e com fallback autoral se a Roblox recusar download/permissões.
- A árvore ancestral, os locais, colisões, iluminação, VFX, trilhas e todos os outros assets existentes são preservados no código. A disponibilidade efetiva das malhas no cliente depende das permissões e da entrega de conteúdo Roblox.
- O pipeline Rojo deve construir ambas as variantes e rejeitar bootstrap com MeshParts e variante integral sem meshes.

## Critérios de aceitação para publicação
1. QA, Rojo leve + integral e auditoria de assets aprovados.
2. Publicação controlada, mantendo rollback para versão Roblox anterior.
3. **Teste real** no cliente/Studio: entrar em servidor novo, confirmar spawn, geração, MeshParts, navegação, luz e consumo no Android. Sem isso, não declarar que o erro foi eliminado.

Referências: https://create.roblox.com/docs/performance-optimization/improve e https://create.roblox.com/docs/workspace/streaming
