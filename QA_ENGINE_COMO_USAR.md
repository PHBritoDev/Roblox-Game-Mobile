# QA na engine Roblox via Open Cloud — Android

## O que foi implementado
Workflow manual: `.github/workflows/qa-engine-roblox.yml`
- Executa `tools/roblox-qa/engine_probe.luau` na **engine Roblox headless** usando Open Cloud.
- Lê a estrutura do Place publicado, verifica existência do gerador e dos recursos de Lighting.
- Arquiva `artifacts/engine/resultado.json` no GitHub Actions.
- Não publica, não grava, não muda o mapa, não acessa DataStore e **não registra fotos/vídeos**.

## Permissão extra necessária
A chave `ROBLOX_API_KEY`, já guardada no GitHub, precisa ter também a autorização de **Luau Execution Session Write** para este Universe, além de `universe-places Write` (usada na publicação). No painel do Roblox, procure um sistema de execução de Luau/"Luau execution session"; os nomes das operações podem variar com a interface. Se a chave não puder ser editada, crie outra com os dois escopos e atualize o Secret no GitHub. **Jamais cole a chave no chat.**

## Como iniciar pelo Android
1. No GitHub Actions, abra `QA de engine Roblox (headless)`.
2. Toque em `Run workflow` e escolha `main`.
3. O resultado aparecerá na etapa "Testar estrutura existente no Place Roblox". Se ocorrer `403 Scope not authorized`, confira a permissão extra na chave.
4. Baixe o artifact `qa-engine-result` quando houver resultado.

## Limitações que não vamos ocultar
- A Luau Execution API **não inicia scripts de servidor/local automaticamente nem simula física**. Assim, o mundo criado pelo gerador durante uma partida não aparece na leitura da estrutura do Place.
- O relatório NÃO comprova a qualidade visual, o cenário gerado ou o FPS.
- A captura de tela real só virá com Roblox Studio MCP e uma máquina compatível acessível ao agente (Windows/macOS), ou outro ambiente gráfico de Roblox verificado.
- O workflow é manual: não autoriza uso ou instalação de novas máquinas/serviços pagos.

## Referências
- https://create.roblox.com/docs/cloud/reference/features/luau-execution
- https://github.com/Roblox/place-ci-cd-demo
- https://create.roblox.com/docs/onboarding/developers
