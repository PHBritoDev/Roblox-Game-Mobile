# Fauna ambiente V1 — cliente Android

Implementacao original em `src/client/Wildlife.client.luau`, separada do gerador do mapa para nao conflitar com os agentes de expansao.

- Tres coelhos com formas 3D originais e tres passaros pequenos com asas animadas; sem meshes ou scripts de terceiros.
- Maximo de 20 atualizacoes/s, sem fisica, sem sombras, sem consultas de toque, sem rede e sem audio sem licenca.
- Coelhos usam Raycast no Terrain e ignoram agua. Ambos os grupos so aparecem com `ForestState=Ready`; visual local nao altera progressao nem persistencia.
- Habitat ancorado na area do jogador e reposicionado apenas quando ele se afasta; evita fauna "grudada" na camera.
- **Visual ainda precisa ser observado no Roblox/Android.** Essas formas sao fauna ambiente discreta, nao substituem modelos 3D premium aprovados pelo criador.

Proximo passe: aves em bando com formacoes mais naturais; modelos de animais com licenca Roblox quando inspecionados; sons de grilos somente com ID/licenca validos e mix condicionado a noite.
