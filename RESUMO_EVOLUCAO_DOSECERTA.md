# Resumo de evolução do DoseCerta

Este documento resume as principais entregas feitas no DoseCerta a partir do commit [`3934eed feat(ms-linking): add caregiver dependent linking service`](https://github.com/SamuelSadovnik/DoseCerta/commit/3934eed1dd43547b1520366603b7abe0c984dec2).

O foco geral das mudanças foi transformar o projeto em uma aplicação mais completa para dois cenários:

- uso pessoal, para quem quer controlar os próprios remédios, consultas, estoque e histórico;
- uso com cuidador, para quem acompanha uma pessoa cuidada/dependente e precisa enxergar os mesmos dados de saúde de forma sincronizada.

## 1. Microserviço de vinculação (`ms-linking`)

Foi criado o microserviço responsável por gerenciar o vínculo entre cuidador e pessoa cuidada por código de convite.

Principais entregas:

- Serviço NestJS independente em `ms-linking`.
- Banco próprio com migrations.
- API REST com Swagger.
- HATEOAS nas respostas.
- Guard de API Key para proteger rotas internas.
- Geração de código de ativação.
- Ativação de vínculo por código.
- Regras contra código expirado, código já usado e vínculo duplicado.
- Publicação do evento `LinkEstablished` no RabbitMQ.
- Dockerfile, `.env.example`, `.gitignore` e README próprio.
- Integração com o backend principal para o fluxo de dependentes.

Com isso, o DoseCerta passou a ter um serviço separado só para a responsabilidade de vinculação cuidador/dependente.

## 2. Microserviço de agendamento (`ms-scheduler`)

Foi criado o microserviço responsável por monitorar doses e consultas próximas, publicando eventos no RabbitMQ.

Principais entregas:

- Serviço NestJS independente em `ms-scheduler`.
- Banco próprio com migrations.
- Estrutura de scheduler interno.
- Integração com RabbitMQ.
- Publicação de eventos de dose agendada.
- Controle para evitar publicação duplicada.
- Suporte posterior a lembretes de consulta.
- Dockerfile, `.env.example`, `.gitignore` e README próprio.

Eventos trabalhados:

- `DoseScheduled`
- eventos de lembrete antes do horário da dose
- eventos de consulta próxima

Esse serviço virou o gatilho assíncrono para notificações e lembretes.

## 3. Microserviço de notificações (`ms-notification`)

Foi criado o microserviço responsável por consumir eventos e gerar notificações.

Principais entregas:

- Serviço NestJS independente em `ms-notification`.
- Banco próprio com migrations.
- API REST para registrar dispositivos.
- API REST para consultar histórico de notificações.
- Swagger.
- HATEOAS.
- Guard de API Key.
- Consumidor RabbitMQ.
- Idempotência por `correlationId`.
- Registro de notificações processadas.
- Envio de push mockado/logado para ambiente local.
- Integração com eventos de dose, adiamento, tomada e vínculo estabelecido.

Eventos consumidos:

- `DoseScheduled`
- `DoseTaken`
- `DosePostponed`
- `DoseMissed`
- `LinkEstablished`

No app, também foi criado feedback visual/local de notificação para facilitar os testes sem depender de Firebase.

## 4. Infraestrutura e Docker

Foi expandida a infraestrutura local do projeto para suportar os microserviços.

Principais entregas:

- Atualização do `docker-compose.yml` da raiz.
- Inclusão de RabbitMQ.
- Inclusão de bancos PostgreSQL separados para microserviços.
- Inclusão dos serviços `ms-linking`, `ms-scheduler` e `ms-notification`.
- Ajustes em `.env.example`.
- Ajustes no backend para comunicação interna.
- Adição de chaves internas/API Key.

O projeto passou a subir com backend, microserviços, bancos isolados e broker de mensageria.

## 5. Backend principal

O backend principal recebeu ajustes para conversar melhor com os microserviços e expor dados necessários ao app.

Principais entregas:

- Endpoints internos protegidos por API Key.
- Controller interno para doses.
- Controller interno para consultas.
- Publicação de eventos de dose tomada/adiada.
- Integração com RabbitMQ.
- Melhorias no fluxo de dependentes.
- Melhorias no histórico.
- Melhorias no estoque/tratamentos.
- Suporte a atualização manual de estoque.
- Suporte a encerramento de tratamento.
- Status de consulta mais completos.
- Melhor tratamento de dados por `dependentId`.

Também foram adicionadas rotas para facilitar a consulta de dados por microserviços, sem compartilhar banco diretamente.

## 6. Fluxo cuidador, pessoa cuidada e uso pessoal

Essa foi uma das maiores melhorias no app.

Antes, o fluxo estava confuso:

- cuidador criava dependente;
- app obrigava ou induzia cadastro de medicamento cedo demais;
- dependente ainda não tinha aceitado o código;
- algumas telas pareciam exigir pessoa cuidada mesmo quando o usuário queria usar sozinho;
- depois do logout/login o vínculo nem sempre aparecia atualizado.

Agora o fluxo foi redesenhado:

- Ao criar conta, o usuário escolhe entre:
  - `Minha saúde`, para uso pessoal;
  - `Cuidar de alguém`, para acompanhar outra pessoa.
- Conta de uso pessoal continua podendo usar tudo sozinha.
- Conta pessoal pode receber código e se vincular a um cuidador depois.
- Cuidador pode criar uma pessoa cuidada sem ela precisar ter conta própria.
- O convite por código virou opcional.
- A pessoa cuidada pode existir como perfil gerenciado pelo cuidador.
- Se a pessoa cuidada também usar o app, ela entra com o código e vincula a conta.
- Depois do vínculo, cuidador e dependente passam a enxergar o mesmo perfil de cuidado.

Também foram ajustadas telas de:

- criação de pessoa cuidada;
- sucesso ao adicionar pessoa cuidada;
- listagem de pessoas cuidadas;
- detalhe da pessoa cuidada;
- tela de vínculo no perfil;
- atualização visual de status vinculado/desvinculado.

## 7. Sincronização entre cuidador e dependente

Foi corrigido um problema importante: quando uma conta pessoal vinculada cadastrava dados, alguns registros ficavam como dados próprios da conta e não apareciam para o cuidador.

Agora existe uma regra única de contexto de cuidado:

- Se for cuidador, o app usa a pessoa cuidada selecionada.
- Se for conta pessoal vinculada, o app usa automaticamente o perfil compartilhado com o cuidador.
- Se for conta pessoal sem vínculo, o app continua usando dados próprios.

Isso foi aplicado em:

- Home;
- tratamentos/estoque;
- cadastro de tratamento;
- consultas;
- cadastro de consulta;
- histórico;
- tela de pessoa cuidada.

Resultado esperado:

- dependente cadastra tratamento, cuidador vê;
- cuidador cadastra tratamento, dependente vê;
- dependente toma dose, cuidador vê;
- cuidador cria consulta, dependente vê;
- dependente cria consulta, cuidador vê;
- histórico usa o mesmo conjunto de dados compartilhado.

O fluxo de uso pessoal puro não foi alterado.

## 8. Estoque e tratamentos

A tela de estoque foi repensada para funcionar mais como uma tela de tratamentos.

Principais entregas:

- Renomeação conceitual para tratamentos.
- Separação entre tratamentos ativos e encerrados.
- Edição manual do estoque.
- Reabastecimento de estoque.
- Encerramento de tratamento.
- Ocultação de tratamentos encerrados da lista principal.
- Tratamentos encerrados continuam disponíveis na aba específica.
- Estoque com quantidade zero deixa de poluir a tela principal.
- Atualização de cache após alterações.
- Melhor suporte a cuidador/dependente.

Isso deixou o uso mais coerente: o usuário acompanha tratamentos ativos no dia a dia e consulta o passado no histórico/encerrados.

## 9. Consultas

A tela de consultas recebeu melhorias de fluxo e status.

Principais entregas:

- Cadastro de consulta para uso pessoal ou pessoa cuidada.
- Consulta vinculada ao dependente correto.
- Visualização pelo cuidador e pelo dependente vinculado.
- Ações de status mais claras:
  - confirmar;
  - concluir;
  - cancelar;
  - reagendar.
- Melhor atualização entre sessões.
- Correção para consultas aparecerem nas telas certas.

A tela passou a acompanhar melhor tanto uso pessoal quanto cuidado compartilhado.

## 10. Histórico

A tela de histórico foi reconstruída para ser mais útil.

Principais entregas:

- Histórico em formato de calendário mensal.
- Visualização por dia.
- Detalhe das doses do dia.
- Status visual por data.
- Resumo por tratamento.
- Datas locais corrigidas.
- Melhor suporte a cuidador/dependente.
- Correção de carregamento de doses do dia.
- Histórico usando o mesmo contexto compartilhado quando a conta está vinculada.

Com isso, o histórico deixou de ser apenas uma lista simples e passou a explicar melhor a evolução do tratamento.

## 11. Home e atualização em tempo real local

A Home recebeu melhorias para ficar mais dinâmica durante testes.

Principais entregas:

- Atualização periódica dos dados.
- Atualização mais rápida após dose tomada.
- Exibição melhor da próxima dose.
- Exibição consolidada para cuidador.
- Seletor de pessoa cuidada.
- Correção para trocar entre `Todos` e dependentes atualizar os dados.
- Feedback visual de notificação no app.

Isso reduziu a necessidade de trocar de aba manualmente para ver os dados atualizarem.

## 12. Notificações e eventos de dose

Foi adicionado suporte a notificações e eventos relacionados às doses.

Principais entregas:

- Publicação de eventos quando dose é tomada.
- Publicação de eventos quando dose é adiada.
- Consumo no microserviço de notificação.
- Feedback visual local no app.
- Lembrete antes da dose.
- Eventos de agendamento vindos do `ms-scheduler`.

O Firebase/FCM real foi deixado de fora por decisão de escopo, mas a arquitetura ficou preparada para plugar push real depois.

## 13. Estados vazios e UX

Várias telas estavam com estados vazios desalinhados.

Foi criado um componente compartilhado para o caso de cuidador sem pessoa cuidada cadastrada.

Aplicado em:

- Home;
- Estoque/Tratamentos;
- Histórico;
- Consultas.

Melhorias:

- Mesmo estilo visual em todas as telas.
- Mesmo CTA de adicionar pessoa cuidada.
- Textos mais claros.
- Remoção de botões duplicados.
- Layout mais consistente.

Isso deixou o app mais padronizado e mais fácil de entender.

## 14. Sessões locais para testar duas contas

Como o app estava sendo testado com duas janelas no macOS, foram feitos ajustes para isolar sessões locais.

Principais entregas:

- Separação de dados locais por instância do app.
- Possibilidade de testar cuidador e dependente lado a lado.
- Menos conflito entre tokens/logins em janelas diferentes.
- Melhor fluxo para simular uso real.

Isso ajudou bastante nos testes de sincronização.

## 15. Documentação criada

Foram criados documentos de apoio para análise, teste e evolução do projeto.

Arquivos principais:

- `ANALISE_MELHORIAS_DOSECERTA.md`
- `GUIA_TESTE_MELHORIAS_DOSECERTA.md`
- `GUIA_TESTE_NOVO_FLUXO_CUIDADOR_DEPENDENTE.md`
- `PROMPT_REDESENHO_FLUXO_CUIDADOR_DEPENDENTE.md`

Esses arquivos ajudam a explicar:

- problemas encontrados;
- melhorias propostas;
- novo fluxo de cuidador/dependente;
- como testar as principais funcionalidades.

## 16. Commits principais depois do `ms-linking`

Lista resumida dos commits feitos depois do microserviço de vinculação:

- `8875406 fix(app): refresh linked caregiver state after login`
- `d375e4b chore(ios): add CocoaPods project files`
- `7cec1f3 feat(ms-scheduler): add dose scheduling publisher`
- `c9165c5 feat(ms-notification): add notification consumer service`
- `3fedca9 fix(app): defer dependent selection updates`
- `674f9b5 feat(core): publish dose action events`
- `f165623 feat(app): isolate local sessions by app instance`
- `05c7a47 feat(app): show live notification feedback`
- `a487f37 feat(stock): support linked inventory management`
- `f147ba6 feat(app): manage active stock treatments`
- `c161d2f feat(notifications): send dose reminders before schedule`
- `c13758b feat(history): show daily dose details`
- `469a1c2 fix(app): refresh appointments across sessions`
- `aa41e1c docs: document DoseCerta improvement flows`
- `0bc24e0 feat(app): clarify care context and linking flow`
- `3a6cfd7 feat(treatments): manage stock lifecycle`
- `b7c5b39 feat(appointments): improve appointment status actions`
- `da23d46 feat(history): add treatment summaries and local dates`
- `dfd2eab feat(gateway): expose care workflow endpoints`
- `ad621fe feat(microservices): add appointment reminder events`
- `df42645 feat(app): redesign caregiver onboarding flow`
- `a12bb05 docs: add new care flow test guide`
- `90c5359 feat(app): refine cared person invite flow`
- `f43aa25 style(app): standardize cared person empty states`
- `67e0e9a fix(app): sync linked dependent care data`

## 17. Estado atual do sistema

Hoje o DoseCerta está com:

- três microserviços principais;
- RabbitMQ;
- bancos isolados por serviço;
- app mobile/macOS com fluxo mais claro;
- suporte a uso pessoal;
- suporte a cuidador;
- suporte a pessoa cuidada sem conta própria;
- suporte a pessoa cuidada com conta vinculada;
- tratamentos com estoque e encerramento;
- consultas com status;
- histórico por dia e por tratamento;
- notificações locais/eventos assíncronos;
- melhor sincronização entre cuidador e dependente.

## 18. Próximos pontos possíveis

Ainda podem ser evoluídos depois:

- push real com FCM;
- testes automatizados end-to-end;
- telas administrativas para visualizar eventos;
- tratamento mais formal de status `encerrado` no banco;
- tela de auditoria de notificações;
- melhoria visual fina em responsividade;
- documentação técnica dos contratos RabbitMQ;
- deploy dos microserviços em ambiente real.

## Resumo final

Desde o commit do `ms-linking`, o projeto saiu de um app com backend principal e fluxo de dependentes ainda confuso para uma arquitetura mais completa, com microserviços, mensageria, notificações, histórico mais rico, tratamentos com ciclo de vida, consultas com status e um fluxo mais claro para uso pessoal ou cuidado compartilhado.

O ponto mais importante é que agora o DoseCerta entende melhor a diferença entre:

- pessoa que cuida de si mesma;
- cuidador que gerencia outra pessoa;
- pessoa cuidada que também usa o app;
- perfil compartilhado entre cuidador e dependente.

Isso deixa o produto mais coerente para o usuário final e mais alinhado com a proposta original do projeto.
