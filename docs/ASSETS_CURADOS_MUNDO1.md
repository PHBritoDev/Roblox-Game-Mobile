# Biblioteca curada — Floresta das Memórias

## Pacote integrado no código (Mundo 1 v5)
- **Synty Nature Pack**, Asset ID `6933438443`, publicado por **@Roblox**.
- Página oficial: https://create.roblox.com/store/asset/6933438443
- Licença: comunicado de parceria Roblox/Synty declara os pacotes gratuitos para qualquer criação na plataforma: https://devforum.roblox.com/t/free-synty-asset-packs-released-in-the-marketplace/1283755/
- Auditoria real na engine em GitHub Actions: https://github.com/PHBritoDev/Roblox-Game-Mobile/actions/runs/43554927240
- Resultado confirmado em memória: **200 MeshParts, 11 Models, 0 Script, 0 LocalScript, 0 ModuleScript**.
- Integração: o jogo chama `InsertService:LoadAsset(6933438443)` uma vez, REMOVE qualquer script antes de usar, seleciona explicitamente apenas 11 elementos de vegetação, árvores, pedras e arco; descarta o resto. Não executa scripts do asset.
- Falha de acesso não impede o mundo original: a floresta autoral continua funcionando.
- Renderizador Blender **não** reconstrói a malha dos MeshParts da mesma forma que o Roblox: representa o volume aproximado. É necessário testar a versão no Roblox para avaliar o modelo de verdade.
- Ainda não publicado no Roblox; código no GitHub, aguarda build/QA e validação visual.

## Candidatos não integrados
- **Forest Pack** por @Roblox: https://create.roblox.com/store/asset/6432306802 — alta qualidade com SurfaceAppearance e foliage cards, mas **contém 13 scripts** e ~153 mil triângulos no pacote; exige inspeção mais rigorosa e orçamento mobile antes de usar.
- Modelos de terceiros livres na Creator Store só após verificar a página, os direitos e inspecionar o conteúdo. Não carregar ativos pagos, nem instalar scripts de origem incerta.

## Regras visuais
- Referências artísticas: exploração nostálgica anime/fantasia tipo Genshin, jogos de fantasia com profundidade e luz quente/fria. Sem copiar mapas, texturas, música ou personagens.
- Assets de alta fidelidade entram para **enquadrar cenas específicas**: a árvore ancestral continua autoral e a trilha não deve ser obstruída.
- Uma mudança só é considerada renderizada se houver captura do Roblox Studio/cliente real. Screenshot de Blender é prévia aproximada.
- Avaliar por aparelho: quantidade de tris, streaming, sombras, textura, FPS e tempo de entrada.

## Áudio
- Direção: água, vento, fauna e textura musical nostálgica, mixados por região/horário; nada de loop de biblioteca indiscriminado.
- Buscar músicas e efeitos na Creator Store ou bibliotecas com licença verificável, escutar e verificar permissão/privacidade antes de atribuir ID ao código. **Nenhuma música foi incluída ainda**.
- Documentação oficial: https://create.roblox.com/docs/audio/assets

## Segurança
- Evitar `require(assetId)` de modelos externos e outras importações dinâmicas sem auditoria.
- https://create.roblox.com/docs/scripting/security/third-party-vulnerabilities
