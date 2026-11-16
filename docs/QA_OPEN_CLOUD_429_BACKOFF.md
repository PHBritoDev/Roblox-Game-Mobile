# Resiliência do laboratório Roblox Open Cloud (16/11/2026)

## Problema comprovado
Os workflows de visual proxy em PRs de mapa/fauna falharam em certas chamadas de sessão Luau por **HTTP 429** do Roblox, enquanto QA estrutural e Rojo passaram. Isso indica limitação da API, não necessariamente bug de geometria. Várias PRs podem compartilhar os mesmos limites da chave/proprietário.

## Correção
- Em **POST** de tarefas Luau, repetir **somente após resposta HTTP 429**. Nunca repetir POST após timeout ou 500/502/503/504, pois uma tarefa poderia ter sido criada.
- Respeitar `Retry-After` positivo e finito; se não existir, usar backoff 10, 20, 40 segundos; máximo de quatro tentativas, cada espera limitada a 90 segundos.
- Em **GET**, preservar retries de erros transitórios já existentes, com espera e limite.
- Continuar redigindo o token em mensagens de erro.
- Unit tests com HTTP simulado: 429, múltiplos 429, 502 em POST sem retry, GET com 502, header inválido e redaction.

## Limites
Não aumenta a cota da API nem confirma que o pipeline completará. Sob saturação prolongada a execução continuará falhando e deve permanecer vermelha; não encobrir CI. Revisar uso de scripts/jobs concorrentes antes de tentar novamente.

## Rollback
Reverter o commit da alteração de `snapshot_scene.py` e o teste associado. Nenhum mapa, arquivo de Place ou publicação Roblox foi modificado.

Documentação oficial: https://create.roblox.com/docs/cloud/reference/rate-limits
