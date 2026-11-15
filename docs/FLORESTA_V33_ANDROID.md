# Floresta V33 — reconstrução e entrega Android

## Diagnóstico e correções

Baseline de rejeição: relato/captura Android da V32 com árvores esféricas, clareira vazia, luz plana e rio ciano. A imagem original não está anexada nesta sessão; não se inventou comparação de screenshots. A main posterior já havia trocado algumas copas por cunhas, mas mantinha esferas nos salgueiros e ancestral. O Cylinder autoral usava tamanho Y sem orientar o eixo longitudinal X; corrigido com segmentos alinhados entre dois pontos.

A proteção V32 capturava falhas de integração e continuava sem repor os sites reservados. V33 descarta clones parciais do pacote afetado e repõe cada site ausente. O QA injeta erro após a primeira clonagem bem-sucedida, além de simular falha dos dois downloads. Contadores de sites, origem dos assets, sucesso de carga/integração, MeshIds vazios e folhagem esférica acompanham o snapshot. O erro original de LoadingSynty no Android não tem stack trace disponível aqui; sua causa exata não foi presumida a partir do sucesso headless.

O CI anterior falhava porque o exporter amostrava só 1.488 de 2.947 partes do fallback. Agora exporta a geometria completa, com teto explícito de 6.500 partes (orçamento técnico provisório, não certificação de FPS). O renderer representa WedgePart e eixo X dos cilindros e evita operações Blender de cena por objeto, que atrasavam a inspeção. As malhas externas continuam aproximadas.

## Biblioteca incluída no Place

`assets/ForestLibrary.rbxmx` contém 24 templates / 37 MeshParts curados dos pacotes oficiais. O build Rojo inclui a biblioteca em ServerStorage. O gerador clona esses templates primeiro, evitando InsertService na inicialização normal. IDs de malha/textura ainda dependem da entrega de conteúdo e permissões do Roblox: incluir instâncias no Place não torna texturas offline nem prova sua aparência no Android.

Fontes: Forest Pack [6432306802](https://create.roblox.com/store/asset/6432306802/Forest-Pack), publicado por @Roblox; Synty Nature Pack [6933438443](https://create.roblox.com/store/asset/6933438443), @Roblox/Synty, com [permissão oficial de uso em criações Roblox](https://devforum.roblox.com/t/free-synty-asset-packs-released-in-the-marketplace/1283755/). São os mesmos assets aprovados na curadoria do projeto. Uso desta biblioteca restrito à integração Roblox; não se atribui licença CC0 ou permissão para distribuir em outras engines.

Os arquivos oficiais foram obtidos pelo endpoint público assetdelivery, sem cookies ou compra. `bake_forest.lua`, executado com rbxmk 0.9.1 e `--desc-latest`, seleciona os templates usados e mantém somente Folder/Model/MeshPart/SurfaceAppearance. Nenhum Script, LocalScript, ModuleScript, emissor ou outro componente ativo é incluído. MeshId, textura, SurfaceAppearance, tamanho original e dados físicos serializados são preservados. `forest-manifest.json` fixa SHA256 do XML e IDs/dimensões por template; auditoria rejeita alteração ou código externo. A reprodução exige os dois .rbxm originais descomprimidos e nova revisão do manifesto; não há atualização automática dos pacotes.

## Mudanças visuais autorais

Base independente dos downloads: três silhuetas de árvores com troncos afilados/inclinados, raízes e ramos, massas foliares lanceoladas sem esferas; salgueiros pendentes e ancestral ramificada. Samambaias e capins em grupos nas margens da trilha, juncos e seixos no rio, bosque distante em profundidade. Folhagem opaca evita transparência adicional. Limites físicos recuados protegem as bordas do Terrain. O chão continua plano; solo e água têm contraste menor, com sombras mais frias no perfil dourado. Não foram adicionados assets Genshin/Ori nem áudio.

Spawn, ponte e corredores preservados. Ready exige apoio físico nas quatro sondagens finais. O cliente não promete recuperação automática nem esconde falha/carregamento após dez segundos. Uma amostra dos MeshIds recebidos pelo cliente tem diagnóstico de fetch em atributos locais do Player; não é telemetria remota nem prova estética, e não cobre conteúdo que chegar por streaming depois.

## Limites de evidência

O build é validado como arquivo, incluindo a biblioteca sem scripts. Open Cloud não abre arbitrariamente um .rbxlx local sem salvar um Place. Para exercitar o caminho Bundled em memória, o QA monta uma fixture dos mesmos modelos oficiais e confere IDs e dimensões contra o manifesto antes de gerar o mundo. Isso **não é um playtest do arquivo empacotado**. Fallback e erro de integração são medidos separadamente.

Previews Blender em três ângulos são gerados tanto com assets quanto sem assets. As formas autorais são representadas; PBR, folhas alfa, água e iluminação Roblox não são fiéis. Captura real, orçamento de triângulos/overdraw, alinhamento percebido e FPS Android continuam pendentes na issue #3. Sem aprovação estética premium.

V33 não foi publicada automaticamente. Autorizações antigas V29–V32 não foram reutilizadas. Merge não altera o jogo Android; publicação exige o fluxo manual autorizado e teste de entrada posterior. Resultados e links dos checks desta rodada ficam no PR correspondente.

## Continuação da integração

As correções concorrentes da main (metadados de exportação e rotas duplicadas) foram integradas. Mantida exportação completa da V33. Cycles abortava durante construção de BVH; Workbench foi preservado como proxy exclusivamente geométrico. O teste seguinte revelou libEGL ausente no runner (exit 134): adicionados Mesa/EGL, Xvfb e renderização por software, sem requerer GPU paga. Workbench não avalia os perfis de iluminação Roblox.
