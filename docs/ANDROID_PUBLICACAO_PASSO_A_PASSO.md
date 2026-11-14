# Android — próximo passo para testar o primeiro mapa Dreamcore

**Situação:** Rojo construiu o primeiro arquivo `.rbxlx` com êxito no GitHub Actions. Isso NÃO comprova que o mapa foi testado no Roblox. O script cria o cenário somente quando o servidor inicia.

## O que já está preparado
- [Código do mapa](../src/server/DreamcoreWorld.server.luau)
- [Build automático](../.github/workflows/build-rojo.yml)
- [Envio manual protegido ao Roblox](../.github/workflows/publicar-teste-roblox.yml)
- **Nenhuma chave foi inserida no repositório e nenhum Place foi publicado.**

## Precisamos de um Place de teste já existente
A API oficial de publicação de Places **atualiza Places existentes**: exige Universe ID e Place ID. Ela não faz automaticamente a configuração inicial de uma nova experiência. O Roblox Studio oficial roda em Windows/macOS; no Android não existe um Studio completo. Antes de contratar Windows remoto, verificar se o criador **já possui uma experiência de Roblox** com um Place de teste que possa ser reutilizado.

## Como localizar seus IDs pelo navegador Android
1. Entre em https://create.roblox.com/dashboard/creations e selecione uma experiência de teste **que seja sua**.
2. Localize o Universe ID na configuração/URL da experiência e Place ID na aba Places, abrindo a configuração do lugar.
3. IDs numéricos não são credenciais secretas. Não compartilhe senha, cookies, tokens, códigos de verificação ou chaves API em chat.

## Preparação da API (somente depois de confirmar Place existente)
1. No Creator Dashboard, crie chave Open Cloud com permissão de **Place Publishing** para a experiência de teste. Use o mínimo de permissões necessário.
2. No GitHub, abra Settings > Secrets and variables > Actions, adicione o secret `ROBLOX_API_KEY`. **Nunca escreva o valor do token em arquivos ou mensagens.**
3. Na aba Actions, abra **Enviar mapa para Roblox (manual)** > Run workflow, informe Universe ID, Place ID e escolha **Saved** primeiro.
4. Se o teste de atualização funcionar, considere **Published** em um Place de teste privado, depois de verificar os dados. O modo Published altera a versão servida por esse Place.
5. Teste no Roblox Android e compartilhe observações/screenshots. A publicação por API não substitui a necessidade de Studio para determinados recursos.

## Importante: ambiente e permissões
O workflow usa `environment: roblox-teste`. O ambiente pode ser configurado em Settings > Environments para requerer aprovação antes de publicar. Se exigir secret por ambiente, configure-o lá; o workflow hoje lê o secret de Actions.
Não configurar chaves de publicação até ter certeza de qual experiência e Place serão afetados.

## Se você não tiver experiência existente
O trabalho continua no GitHub enquanto resolvemos a criação inicial de um Place. Um Windows remoto acessado pelo Android pode ser necessário para a primeira configuração no Studio. Não há custo confirmado abaixo de R$10 nem teste grátis de 30 dias garantido; não contrate sem verificar licença, requisitos, latência e custo total.

## Referências oficiais
- https://create.roblox.com/docs/studio/setup
- https://create.roblox.com/docs/cloud/guides/usage-place-publishing
- https://create.roblox.com/docs/projects/file-based-workflows
