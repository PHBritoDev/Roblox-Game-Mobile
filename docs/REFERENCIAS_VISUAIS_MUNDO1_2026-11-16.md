# Referencias visuais do criador — expansao Mundo 1 (16/11/2026)

Estas diretrizes foram extraidas das quatro imagens enviadas pelo criador nesta conversa. **As imagens nao foram copiadas para o repositorio**; esta ficha registra suas caracteristicas e uso pretendido, evitando depender de um link temporario. Nao copiar fotografias, mapas, assets ou texturas de terceiros.

## Imagem 1 — manha nostálgica
Colagem de fotografias: sol baixo e dourado entre arvores, raios filtrados pelas folhas, grama iluminada com sombras longas e frias, leve haze e brilho natural, ambiente calmo. **Uso no jogo:** nascer do sol e parte inicial da manha; inspiracao para o perfil Dawn Haze. Evitar bloom excessivo e claridade que atrapalhe o caminho.

## Imagens 2 e 3 — por do sol
Campos com capim em silhueta e sol rente ao horizonte; nuvens alaranjadas e rosadas contra ceu lilas/roxo; forte contraste entre o horizonte quente e o primeiro plano sombreado. **Uso no jogo:** perfil Amber Sunset com gradação gradual de cores, respeitando a legibilidade da trilha no celular.

## Imagem 4 — noite de auroras
Ceu escuro violeta com estrelas numerosas e faixa de aurora magenta/roxa acima de bosque em silhueta. **Uso no jogo:** aurora de movimento lento e contido; floresta e caminho nao devem ficar completamente roxos nem perder visibilidade. A foto tem neve, mas **nao introduzir neve no Mundo 1**; aproveitar apenas o ceu e o clima.

## Contrato de expansao
- Crescer em incrementos moderados: expandir terreno/bioma com QA a cada entrega, preservando posicoes do spawn, ponte, rio, lago, caminho e arvore central.
- Nao deixar as bordas vazias: distribuir **arvores texturizadas premium** com especies e silhuetas variadas, estrato baixo, moitas, gramados e flores. Nunca usar arvores genericas como layout primario. Respeitar direitos dos assets e sanitizar scripts/efeitos importados.
- Fauna futura em passos separados: aves no ceu, coelhos em clareiras e grilos audiveis a noite. Preferir modelos/animacoes originais leves. Sons somente apos validar ID, licenca, permissao e audicao.
- Aurora futura: animacao discreta, baseada em material/mesh validado no Roblox; evitar muitos planos transparentes superpostos (overdraw). Nao declarar pronta sem captura real.
- Mobile: limitar objetos e draw calls, reutilizar malhas, streaming consciente, sombras seletivas, LOD/RenderFidelity.Automatic, perfil de energia/particulas com orçamento. Guardar margem de performance e checar visual no Roblox Android.

## Iteracao 1 (PR vinculada)
- Terreno expandido de **680×792** para **760×880 studs** (~24,1% de area), mantendo celulas de 4 studs e solo da regiao existente.
- Ampliar o bosque exterior com mais reservas Forest Pack e grupos pequenos de grama/samambaias sem colisao, nao deslocar trilhas.
- Iluminacao do amanhecer e virada de horario sao responsabilidade da PR #34 do outro agente; nao duplicar seu trabalho nesta PR.
- Nao adicionar fauna/audio/aurora neste mesmo lote: precisam de teste estetico e orcamento separado.

## Criterios de aceite
1. GitHub Rojo, QA estrutural e proxy visual verdes no **mesmo SHA**.
2. Snapshot headless: colisao na trilha, spawn, ponte, reserva de arvores e teto de partes verificados; comparar contagem de partes e tempo de geracao com a versao anterior.
3. Inspecao dos renders proxy (nao screenshots reais); registro de qualquer problema visual.
4. Sem publicacao automatica. Depois de merge validado, o workflow de publicar para Roblox exige acao separada.
5. Rollback: reverter o commit da PR na main, restaurando dimensoes de terreno, sitios de arvore, limites e perfis anteriores; publicacao Roblox, se houver, requer restaurar Place/version independentemente.

Referencias oficiais: https://create.roblox.com/docs/performance-optimization/improve e https://create.roblox.com/docs/environment.
