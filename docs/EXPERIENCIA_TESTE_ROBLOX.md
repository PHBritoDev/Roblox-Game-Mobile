# Experiência Roblox identificada pelo criador

**Data:** 13/11/2026  
**Situação:** IDs fornecidos pelo criador. Nenhuma versão de mapa foi enviada à Roblox pela automação.

- Nome visto no Creator Dashboard: `siebeud's Place`
- Universe ID: `2660433574`
- Place ID: `6947682498`
- Página de gerenciamento: https://create.roblox.com/dashboard/creations/experiences/2660433574/overview
- URL do lugar: https://www.roblox.com/games/6947682498/

## Decisões de segurança

1. O Place **já tem um mapa existente**; NÃO substituir nem publicar sem confirmação explícita do criador. A automação atual está configurada para execução **manual**, não para envios automáticos a Roblox.
2. Antes de atualizar, criar/verificar uma versão de recuperação do mapa atual. Salvar uma versão nova com `Saved` primeiro, e só escolher `Published` quando aprovado. Mesmo `Saved` altera a versão salva, portanto preservar o estado anterior.
3. A chave da Open Cloud deve ter apenas `universe-places` / `Write` para a experiência indicada, não dar acesso a todos os jogos.
4. Guardar a chave como `ROBLOX_API_KEY` exclusivamente nos **GitHub Actions secrets** (ou secrets do ambiente protegido). Nunca compartilhar tokens, cookies, senhas ou 2FA em mensagens ou arquivos públicos.
5. Workflow preparado: `.github/workflows/publicar-teste-roblox.yml`. Em execução manual, informar os IDs acima e começar pelo modo `Saved`.
6. O `DreamcoreWorld.server.luau` usa `Workspace.Terrain:Clear()` e gera um cenário **durante a execução do servidor**. Isto apagará o terreno anterior *quando o protótipo for executado*, se utilizado naquele Place. Não usar no jogo de produção sem isolamento ou backup.
7. Build via Rojo não significa teste dentro do Roblox. Após envio e publicação segura, executar no app Android e conferir resultados.

## Referências oficiais
- https://create.roblox.com/docs/cloud/guides/usage-place-publishing
- https://create.roblox.com/docs/cloud/auth/api-keys

## Próximo passo
Configurar chave segura no Roblox Creator Dashboard e no repositório GitHub, sem compartilhar a chave no chat; antes do primeiro envio, o criador deve decidir se autoriza substituir este Place ou se devemos preparar outro Place de testes.
