# Mundo 1 — Floresta das Memórias (v2)

## Direção artística
**Objetivo:** floresta original de fantasia anime com atmosfera nostálgica cinematográfica, densidade real de silhuetas e um ponto focal reconhecível. Referências gerais de linguagem visual: exploração de fantasia de *Genshin Impact*, direção de luz e profundidade por planos dos mundos de fantasia contemporâneos e fotografia de florestas ao entardecer. **Não reproduzir modelos, texturas, mapas, personagens ou músicas de terceiros**.

## Composição concretizada no script
- Trilha em S organizada para guiar a vista do spawn até a **Árvore da Primeira Memória**.
- Árvores laterais de alturas e cores variadas formando primeiro, segundo e terceiro planos.
- Colina natural no limite externo; rio à direita, ponte antiga e pequenas pedras cerimoniais.
- Flores, arbustos e cogumelos sem colisão; vagalumes próximos da árvore sagrada.
- Spawn integrado à vegetação, sem plataforma neon artificial.
- Uso de instâncias simples ancoradas e uma fonte de partículas para limitar o custo mobile.

## Luz / clima — três perfis em rotação
1. **Golden Nostalgia:** luz quente de pôr do sol, sombras azul-acinzentadas, nuvens âmbar, dispersão atmosférica suave.
2. **Cold Twilight:** crepúsculo azulado, contraste com realces delicados, começa a aparição de estrelas.
3. **Starry Dream Night:** céu noturno estrelado, neblina azulada e gradação fria.

Transições suaves em `Lighting`, `Atmosphere`, `Clouds` e correção de cor; `SunRays` e `Bloom` contidos. O ciclo atual é um protótipo artístico, não simulação astronômica; verificar se a passagem de 23h para 17h é visualmente coerente antes de liberar.

## QA / riscos ainda não validados
- **Nenhuma imagem real dessa versão foi capturada** — o Roblox Studio MCP continua sem um ambiente gráfico conectado.
- `rojo build` verifica o pacote; não prova renderização nem FPS no Roblox.
- A geração no servidor **não acontece no teste Open Cloud Luau Execution headless**. Para validar a geometria gerada é necessário iniciar o jogo.
- Validar visibilidade da árvore e ausência de árvores sobre o caminho; conferência de terreno e ponte; limites de FPS/memória e de instâncias num celular Android.
- Validar água e margem; segurança dos passos no terreno e colisão das raízes.
- Confirmar orientação dos galhos, brilho e sombras com capturas reais.
- A versão publicada permanece inalterada até uma publicação manual autorizada.

## QA de aceitação (checklist)
- [ ] Spawn está em terreno firme; não existe queda ou obstáculos.
- [ ] Árvore da Primeira Memória pode ser vista no avanço pela trilha.
- [ ] Trilha apresenta orientação clara e densidade equilibrada.
- [ ] Pôr do sol: luz quente e sombras frias com visibilidade agradável.
- [ ] Crepúsculo: transição suave sem tela lavada.
- [ ] Noite: há estrelas, mas a trilha continua legível.
- [ ] Performance adequada em Android real, sem travamentos importantes.
- [ ] Screenshots do Roblox Studio ou cliente real arquivadas com local e perfil.
- [ ] Vídeo de trajeto e comparação antes/depois arquivados.

## Referências técnicas Roblox
- https://create.roblox.com/docs/environment
- https://create.roblox.com/docs/environment/clouds
- https://create.roblox.com/docs/environment/post-processing-effects
- https://create.roblox.com/docs/onboarding/artists

## Futuro combate
As referências de combate ficam restritas à **fluidez de animação, camera work, telegráficos visuais legíveis, efeitos elementais originais, responsividade e otimização mobile**. Só avançar depois da cena inicial e pipeline de QA visual.
