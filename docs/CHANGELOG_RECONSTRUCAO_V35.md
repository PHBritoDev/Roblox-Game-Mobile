# Registro de Reconstrucao e Validacao — Mundo 1 (V35)

## 1. Correcao Definitiva do Carregamento Infinito e Bootstrap Android
- **Piso Fisico Instantaneo (`PisoSegurancaBootstrap`)**: Instanciado no tick `0` junto com `Nascimento Dreamcore` antes do `task.spawn` do gerador volumétrico. Garante suporte fisico imediato para jogadores que entram em servidores recém-alocados antes da conclusao do `Terrain:WriteVoxels`.
- **Desacoplamento de Deserializacao**: Mantido `default.project.json` livre de deserializacao pesada no bootstrap e `mobile-premium.project.json` com a biblioteca curada e enxuta (`ForestLibraryMobile.rbxmx`, 11 templates / 20 MeshParts auditados por SHA256).
- **Fallback Organico Automatico**: Caso `InsertService` falhe ou exceda o tempo no servidor, todos os sitios de arvores recebem imediatamente as arvores 3D autorais multi-camadas sem travar a entrada do jogador.

## 2. Reconstrucao da Floresta e Expansao do Mundo 1
- **Barco de Madeira nas Margens (`Lago do Reflexo`)**: Marco visual autoral inspirado na referencia de por do sol (`X = -69.5, Z = -138.5`), com casco em tabuas, proas em cunha, bancos e remo repousado entre os juncos.
- **Mirante das Estrelas (Santuario Noroeste — `X = -188, Z = -312`)**: Ruinas circulares de xisto com cristais estelares emissores para exploracao noturna sob a aurora.
- **Clareira do Orvalho Dourado (Bosque Leste — `X = 218, Z = -195`)**: Clareira aberta com troncos caidos cobertos por musgo e vegetacao rasteira.
- **Lajes Antigas da Trilha (`TrailSteppingStones`)**: 28 lajes naturais de ardósia assentadas por Raycast ao longo da trilha em S, enriquecendo a leitura visual do caminho sem interferir na colisao do personagem.

## 3. Atmosfera, Ciclo de Tempo e Movimentacao Ambiental
- **Quatro Perfis Cinematograficos**: `First Light Meadow` (amanhecer dourado/mel com neblina baixa), `Golden Nostalgia` (entardecer ambar/coral), `Cold Twilight` (crepusculo azul-violeta) e `Starry Dream Night` (noite com 3.000 estrelas e vagalumes).
- **Aurora Boreal Nativa (`Aurora.client.luau`)**: Cortinas boreais animadas a 7 Hz exclusivamente durante a noite.
- **Vento na Vegetacao e Perfil Sonoro (`AmbientWindAndSound.client.luau`)**: Oscilacao senoidal leve (8 Hz, raio de 70 studs, teto de 28 partes) nos juncos e samambaias proximas ao jogador, com transicao automatica de estado diurno/noturno (`NightCricketsActive`).

## 4. Validacoes Executadas
- `python3 tools/roblox-qa/audit.py`: **APROVADO** (todos os checks estruturais e sanitizador de assets verdes).
- `python3 tools/roblox-qa/audit_bundled_assets.py`: **APROVADO** (24 templates verificados por SHA256, zero scripts externos).
- `python3 -m unittest discover -s tools/roblox-qa -p 'test_*.py'`: **113 testes APROVADOS (100% OK)**.
- `python3 -m unittest discover -s tests/qa -p 'test_*.py'`: **36 testes APROVADOS (100% OK)**.
