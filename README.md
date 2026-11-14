# Roblox Game-Mobile — protótipo Dreamcore

**Estado:** primeira implementação em código, **não testada no Roblox Studio nem publicada**.

## Objetivo
Testar o primeiro mapa 3D Dreamcore do futuro jogo dos sete mundos, mantendo a escolha da primeira espécie/planeta em aberto.

## O que contém
- `src/server/DreamcoreWorld.server.luau`: gera terreno, colinas, lago, praça de spawn, trilha, monumento, árvores rosa e lilás, ilhas flutuantes, orbes, lua surreal e atmosfera.
- `src/client/Welcome.client.luau`: exibe orientação discreta.
- `default.project.json`: projeto Rojo.
- `docs/`: visão criativa e plano técnico.

## Gerar o arquivo para Roblox Studio
Com Rojo instalado em um ambiente compatível:
```sh
rojo build default.project.json -o DreamcorePrototype.rbxlx
```
Abra o arquivo no Roblox Studio em Windows/macOS e execute **Play**: o mapa procedural é gerado **na inicialização do servidor**, não durante `rojo build`. Se abrir sem executar o jogo, a cena poderá parecer vazia. Use o Studio para validar e publicar um Place de teste. **Não use este script num Place com terreno valioso**: ele executa `Terrain:Clear()`.

## Android
O criador utiliza apenas Android. O código e arquivos podem ser criados e revisados pelo GitHub no navegador, mas a criação inicial e a validação no Studio ainda exigem Windows/macOS, que poderá ser acessado remotamente pelo Android. O aplicativo Roblox Android permite jogar uma experiência já publicada, mas não substitui o Studio.

## Próximo marco
Validar build do Rojo em CI, configurar ambiente remoto para Studio, criar Place privado de teste, rodar no Android e iterar no estilo visual com screenshots reais. Nenhuma publicação automática foi configurada; não compartilhar credenciais Roblox no repositório.
