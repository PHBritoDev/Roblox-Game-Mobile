# Plano técnico — construir mapas Dreamcore usando Android (v0.1)
Data: 13/11/2026. Status: abordagem proposta para começar; não há mapa publicado ou testado.

## Decisão técnica
- Engine do jogo final: **Roblox**; scripts em **Luau**.
- Controle de versão: **GitHub** (este repositório).
- Projeto declarativo: **Rojo** para mapear scripts/instâncias e gerar `.rbxlx` (`rojo build -o build.rbxlx`).
- Composição dos mapas: **geração programática no Roblox por Luau**, incluindo terreno via Terrain, estruturas 3D e parâmetros de Lighting/Atmosphere, complementada posteriormente por modelos/meshes/autoria artística no Studio e Blender.
- Testes reais: Roblox Studio (Windows/macOS) + aplicativo Roblox Android após disponibilizar versão de teste.
- Automação futura: GitHub Actions pode construir artefato Rojo e publicar versão de um **Place já existente** usando a API oficial Roblox Open Cloud. Habilitar somente depois de configurar Place, permissões, testes e segredos via GitHub Secrets.
- Não usar Godot/Unity/Three.js como motor do mapa Roblox.

## Limite imprescindível
**Roblox Studio oficial não roda no Android.** GitHub, ChatGPT e Rojo não substituem completamente a ferramenta. Precisamos de acesso pelo Android a **Windows/macOS com Studio** (PC emprestado ou computador remoto autorizado) ao menos para configurar e validar o primeiro projeto, e provavelmente para editar assets/cenas complexas. Não solicitar nem colar credenciais em chats.

## Etapas concretas
1. **Protótipo da primeira área**: estabelecer escala, topografia, atmosfera surreal Dreamcore, paleta, monumentos, landmarks, entrada/saída, caminhos e otimização. Não fixar ainda espécie/nome do Mundo 1 sem aprovação.
2. **Eu escrevo no GitHub**: projeto Rojo, scripts de geração modular em Luau, iluminação, atmosfera, estruturas e documentação.
3. **Gerar arquivo do lugar**: um PC/runner com Rojo faz `rojo build`; o arquivo `.rbxlx` pode ser aberto pelo Studio para gerar/validar a cena. A geração procedimental precisa rodar no contexto adequado do Studio ou do jogo conforme o script; *build* sozinho não prova que a geometria final foi gerada.
4. **Configuração inicial Roblox**: em Windows/macOS abrir Studio, criar uma experiência/Place de teste e instalar ou executar o conteúdo conforme instruções do protótipo; publicar privadamente para testes.
5. **Iterar pelo celular**: jogar no app Roblox Android, registrar screenshots e feedback, revisar código no GitHub e repetir.
6. **Após validação**: automatizar builds e atualização de Places existentes com Open Cloud e GitHub Actions, armazenando API keys exclusivamente em GitHub Secrets. Publicar só após aprovação.

## Primeiro mapa: critérios
- Dreamcore original: espaços familiares porém impossíveis, escala intrigante, cores e iluminação cuidadosamente escolhidas, silêncio/sons ambientais licenciados, geometrias memoráveis.
- Mapa amplo o bastante para exploração interessante, mas dividido em setores para manter desempenho mobile; não começar com um mundo infinito.
- Marcas visuais fáceis de reconhecer, caminhos claros sem perder mistério, história ambiental; sem usar assets protegidos sem licença.
- Efeitos de neblina/luz/partículas moderados, testar FPS e memória em aparelho real.
- Primeira entrega técnica desejável: pequena área jogável com spawn, chão, relevo, 2–3 marcos surrealistas, luz e atmosfera; sem gameplay complexo.

## Dependência a resolver
Saber se existe **acesso a Windows/macOS com Roblox Studio**, mesmo emprestado/remoto. Sem isso ainda podemos produzir código e projeto no GitHub, mas **não podemos prometer edição completa, validação ou publicação** do jogo apenas pelo Android.

## Referências
- Roblox Studio: https://create.roblox.com/docs/studio/setup
- Terrain scripting: https://create.roblox.com/docs/parts/terrain
- Rojo build: https://rojo.space/docs/v7/getting-started/new-game/
- Roblox Open Cloud place publishing: https://create.roblox.com/docs/cloud/guides/usage-place-publishing
