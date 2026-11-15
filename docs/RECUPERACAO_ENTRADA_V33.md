# Recuperação da entrada V33

Relato: Roblox preso em “Aguardando um servidor disponível”, antes da interface do jogo. Biblioteca embutida V33 é suspeita, não causa comprovada. O diagnóstico privado/inativo da API pública não explica sozinho a falha da conta proprietária.

Isolamento reversível: default.project.json deixa de incorporar ForestLibrary no bootstrap do Place. A versão integral fica em bundled.project.json e todos os assets permanecem no repositório. O gerador continua usando LoadAsset com tratamento de falhas e floresta autoral; spawn antecipado, cenário e efeitos não foram reescritos. Isso evita desserializar as malhas/dados físicos embutidos antes do início dos scripts.

Rojo e 25 testes locais aprovados; XML de recuperação sem MeshPart embutida. Não é prova de entrada Android. Publicação manual e novo teste de entrada necessários para confirmar/rejeitar a hipótese. Nenhuma autorização anterior de publicação integral foi reutilizada automaticamente.
