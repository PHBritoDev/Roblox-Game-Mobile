# Direcao de arte — referencias do usuario (2026-11-16)

Este documento registra as **intencoes visuais** das quatro imagens compartilhadas na conversa do projeto. Nao inclui/copia imagens de terceiros nem concede licenca para assets. Os arquivos originais continuam no chat do usuario; caso precisem ser incorporados ao repositorio, confirmar licencas primeiro.

- **Imagem 1 (colagem de referencias de nascer do sol/manhã):** atmosfera luminosa e aconchegante; tons de mel, creme e azul pastel; neblina baixa sutil; contraluz natural entre copas e flores. Evitar superexposicao.
- **Imagens 2 e 3 (por do sol/transicao para noite):** dourado, coral, rosa e lavanda no horizonte; sombras azul-esverdeadas; silhuetas de folhagens em camadas; preservar legibilidade do caminho.
- **Imagem 4 (noite):** ceu azul-escuro estrelado, auroras verdes/azuladas suaves **com movimento lento**, nao uma faixa neon fixa ou gigantesca; floresta acolhedora e misteriosa; pouca emissao de luz para Android.

## Divisao entre agentes
- Agente de expansao: terreno/biomas, arvores premium, gramas, flores, coelhos, passaros, grilos e distribuicao espacial; preservar distancia de visao, colisao e performance.
- Agente de iluminacao: perfis amanhecer/poente/noite e transicoes; manter desenho e volumes do mundo do outro agente. A aurora animada precisa de um passe especifico com teste no cliente; **nao afirmar que este commit implementa aurora**.
- Integrador: verificar PRs concorrentes, QA estrutural, Rojo, proxy Blender e validacao real Roblox antes de publicar; nao confundir proxy com gameplay.
