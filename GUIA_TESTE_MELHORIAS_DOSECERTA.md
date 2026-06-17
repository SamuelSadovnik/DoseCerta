# Guia de melhorias e testes do DoseCerta

Este documento resume tudo que foi ajustado nesta rodada e traz um roteiro
pratico para testar o app desde o login ate os fluxos principais de uso.

> Observacao: nao foi implementado Firebase/FCM real nesta etapa, por decisao
> do projeto. As notificacoes continuam usando o fluxo local/visual ja
> validado no app e os eventos dos microservicos.

## 1. O que foi feito

### 1.1 Contexto de uso: pessoal, cuidador e pessoa cuidada

Antes, algumas telas ainda ficavam confusas entre:

- usuario de uso pessoal;
- cuidador vendo todos os dependentes;
- cuidador filtrando uma pessoa cuidada especifica;
- dependente usando a propria conta.

Agora o app possui um contexto de visualizacao mais claro:

- `Todos`: cuidador ve informacoes agregadas das pessoas cuidadas.
- Pessoa especifica: cuidador filtra doses, estoque, historico e consultas de
  uma pessoa cuidada.
- Uso pessoal: usuario controla apenas os proprios remedios, sem linguagem de
  dependente/cuidador.

Tambem foram ajustados textos de interface para reduzir confusao:

- "Dependentes" passou a aparecer mais como "Pessoas cuidadas" em pontos de
  fluxo.
- Cadastro de tipo de conta ficou mais claro:
  - "Cuidar de mim"
  - "Cuidar de outra pessoa"
- Tela de detalhe passou a usar "Pessoa cuidada".
- Medicamentos passaram a ser tratados como "Tratamentos" em partes da UX.

### 1.2 Estoque e tratamentos

O estoque foi reorganizado para fazer mais sentido como tratamento ativo:

- A tela de estoque separa tratamentos ativos e encerrados.
- Tratamento com estoque `0` nao precisa mais ficar misturado como se fosse
  tratamento ativo.
- Foi criado status proprio para tratamento:
  - `active`
  - `ended`
- Encerrar tratamento agora e uma acao propria, nao apenas deixar quantidade
  zerada.
- Ao encerrar um tratamento, o backend remove doses futuras pendentes/postergadas
  daquele medicamento.
- A tela permite editar quantidade de estoque e reabastecer.
- O app interpreta o status vindo do backend e separa corretamente os tratamentos.

Arquivos principais envolvidos:

- `backend/core-service/src/medications/medication.entity.ts`
- `backend/core-service/src/medications/medications.service.ts`
- `backend/core-service/src/medications/medications.controller.ts`
- `backend/core-service/src/doses/doses.service.ts`
- `backend/gateway/src/core-proxy/core-proxy.controller.ts`
- `lib/features/stock/...`

### 1.3 Consultas com status mais claro

O fluxo de consulta foi melhorado para permitir mais estados reais:

- confirmar consulta;
- marcar consulta como realizada;
- cancelar consulta;
- reagendar consulta.

Antes, confirmar podia se confundir com concluir. Agora:

- `Confirmar consulta` muda o status para confirmada.
- `Marcar como realizada` conclui a consulta.
- `Cancelar consulta` remove da agenda ativa como cancelada.
- `Reagendar` abre o fluxo de edicao/reagendamento.

O app tambem traduz o status `done` do backend para `completed`, mantendo a
interface consistente.

Arquivos principais envolvidos:

- `backend/core-service/src/appointments/appointments.service.ts`
- `backend/core-service/src/appointments/appointments.controller.ts`
- `backend/gateway/src/core-proxy/core-proxy.controller.ts`
- `lib/features/alerts/presentation/appointment_alert/...`
- `lib/features/appointments/...`

### 1.4 Historico mais completo por tratamento

A tela de historico ganhou uma leitura mais util por tratamento.

Agora, alem do calendario mensal e do detalhe por dia, o historico exibe um
resumo por tratamento no mes:

- nome do medicamento;
- dosagem;
- doses tomadas;
- doses previstas;
- doses perdidas;
- percentual de adesao;
- ultima dose registrada.

Isso ajuda o usuario pessoal e o cuidador a entender se o tratamento esta sendo
seguido, sem depender apenas de olhar dia por dia.

Arquivos principais envolvidos:

- `backend/core-service/src/history/history.service.ts`
- `lib/features/history/domain/entities/history_summary.dart`
- `lib/features/history/data/datasources/history_remote_datasource.dart`
- `lib/features/history/presentation/history_page.dart`

### 1.5 Correcao de fuso horario em doses e historico

Foi corrigido o problema de doses aparecendo no dia errado por causa de UTC.

O backend agora calcula dia e mes usando o offset local configurado:

```env
APP_TIMEZONE_OFFSET_MINUTES=-180
```

Isso evita casos como uma dose de madrugada ser agrupada no dia anterior ou
aparecer com status estranho no historico.

Arquivos principais envolvidos:

- `backend/core-service/src/history/history.service.ts`
- `backend/core-service/src/doses/doses.service.ts`
- `backend/.env.example`
- `backend/docker-compose.yml`

### 1.6 Novo codigo de vinculo expirado

Foi criado fluxo para gerar um novo codigo de vinculo para uma pessoa cuidada.

Na tela de detalhe da pessoa cuidada:

- se ela ainda nao estiver vinculada, aparece o codigo;
- existe o botao `Gerar novo codigo`;
- o app atualiza o codigo na tela sem precisar sair e voltar.

No backend:

- nova rota no core-service:
  - `POST /dependents/:id/code`
- nova rota no gateway:
  - `POST /api/dependents/:id/code`
- a rota bloqueia geracao de novo codigo se a pessoa ja estiver vinculada.

Arquivos principais envolvidos:

- `backend/core-service/src/dependents/dependents.service.ts`
- `backend/core-service/src/dependents/dependents.controller.ts`
- `backend/gateway/src/core-proxy/core-proxy.controller.ts`
- `lib/features/dependents/...`

### 1.7 Lembrete de consulta via microservicos

Foi adicionada estrutura para o `ms-scheduler` publicar evento de lembrete de
consulta e para o `ms-notification` consumir esse evento.

Evento novo:

- `AppointmentReminder`
- routing key: `appointment.reminder`

Variavel nova:

```env
APPOINTMENT_REMINDER_LEAD_MINUTES=60
```

Com isso, o scheduler consegue buscar consultas futuras da API principal e
publicar um evento antes do horario configurado. O notification registra/processa
a notificacao, sem Firebase real nesta etapa.

Arquivos principais envolvidos:

- `backend/core-service/src/appointments/internal-appointments.controller.ts`
- `backend/core-service/src/appointments/appointments.service.ts`
- `ms-scheduler/src/scheduler/scheduler.service.ts`
- `ms-scheduler/src/db/schema.ts`
- `ms-scheduler/src/db/migrations/0002_create_appointment_schedules.sql`
- `ms-notification/src/notifications/notifications.consumer.ts`
- `ms-notification/src/notifications/notifications.service.ts`

### 1.8 Documento de analise

Foi criado tambem:

- `ANALISE_MELHORIAS_DOSECERTA.md`

Esse arquivo tem uma analise maior do projeto, problemas de clareza, sugestoes
de evolucao e ideias para melhorar o fluxo de uso.

## 2. Validacoes ja executadas

Foram executados:

```bash
npm run build
```

em:

- `backend/core-service`
- `backend/gateway`

Tambem foram executados:

```bash
npm run typecheck
```

em:

- `ms-scheduler`
- `ms-notification`

E no app Flutter:

```bash
flutter analyze
```

Resultado:

- backend core-service build OK;
- backend gateway build OK;
- ms-scheduler typecheck OK;
- ms-notification typecheck OK;
- Flutter analyze OK, sem issues.

## 3. Como subir o projeto para testar

### 3.1 Subir Docker

Na raiz do projeto:

```bash
docker compose up -d
```

Se voce estiver usando tambem o compose do backend separado:

```bash
cd backend
docker compose up -d
```

Depois confira se os servicos estao rodando:

```bash
docker ps
```

Servicos esperados no fluxo completo:

- RabbitMQ;
- banco do backend;
- auth-service;
- core-service;
- gateway;
- ms-linking;
- ms-scheduler;
- ms-notification;
- bancos dos microservicos.

### 3.2 Rodar o app macOS

Na raiz do projeto:

```bash
flutter run -d macos
```

Se quiser abrir duas janelas para testar cuidador e dependente ao mesmo tempo,
rode dois comandos em terminais separados:

```bash
flutter run -d macos
```

e em outro terminal:

```bash
flutter run -d macos
```

Se o Flutter reclamar de multiplas instancias, uma alternativa e testar uma conta
por vez fazendo logout/login.

## 4. Contas para teste

Nao existe seed fixo de usuario no repositorio. Entao existem dois caminhos:

### Caminho A: usar as contas que voce ja criou

Use as contas atuais da sua base local, por exemplo as contas de cuidador e
dependente que voce criou durante os testes.

A senha usada nos testes anteriores foi:

```text
123456
```

### Caminho B: criar contas novas

Se a base foi resetada, crie:

1. uma conta de cuidador;
2. uma conta de dependente;
3. opcionalmente, uma conta de uso pessoal.

Sugestao de dados:

```text
Cuidador
email: cuidador.teste@dosecerta.local
senha: 123456
tipo: Cuidar de outra pessoa

Dependente
email: dependente.teste@dosecerta.local
senha: 123456
tipo: Cuidar de mim

Uso pessoal
email: pessoal.teste@dosecerta.local
senha: 123456
tipo: Cuidar de mim
```

Se o email ja existir, use outro com timestamp, por exemplo:

```text
cuidador.teste.001@dosecerta.local
dependente.teste.001@dosecerta.local
pessoal.teste.001@dosecerta.local
```

## 5. Roteiro de teste completo

### 5.1 Teste de login

1. Abra o app macOS.
2. Entre com uma conta existente ou crie uma nova.
3. Confirme que o login abre a Home.
4. Faca logout pelo Perfil.
5. Entre novamente.
6. Resultado esperado:
   - o app nao deve mostrar "sem conexao com o servidor";
   - o contexto anterior nao deve quebrar a tela;
   - usuario pessoal entra em fluxo pessoal;
   - cuidador entra em fluxo de cuidador.

### 5.2 Teste de uso pessoal

Use a conta `pessoal`.

1. Entre no app.
2. Va em `Estoque`.
3. Cadastre um tratamento/medicamento.
4. Volte para `Inicio`.
5. Confira se as doses aparecem na agenda.
6. Marque uma dose como tomada.
7. Va em `Historico`.
8. Toque no dia atual.
9. Confira se a dose aparece como tomada.
10. Veja o `Resumo por tratamento`.

Resultado esperado:

- textos devem falar de "meu estoque", "meu historico" ou equivalente;
- nao deve aparecer linguagem de dependente/cuidador;
- dose tomada deve refletir no historico;
- resumo por tratamento deve mostrar tomadas, previstas, perdidas e adesao.

### 5.3 Teste de cuidador criando pessoa cuidada

Use a conta `cuidador`.

1. Entre no app.
2. Va em `Perfil`.
3. Entre em `Pessoas cuidadas` ou fluxo equivalente.
4. Cadastre uma nova pessoa cuidada.
5. Abra o detalhe dessa pessoa.
6. Veja o codigo de vinculo.

Resultado esperado:

- tela deve usar linguagem de pessoa cuidada;
- codigo deve aparecer;
- se ainda nao estiver vinculada, deve aparecer `Gerar novo codigo`.

### 5.4 Teste de gerar novo codigo de vinculo

Na tela de detalhe da pessoa cuidada:

1. Copie/anote o codigo atual.
2. Toque em `Gerar novo codigo`.
3. Aguarde a mensagem de sucesso.
4. Confira se o codigo mudou na tela.

Resultado esperado:

- app mostra `Novo codigo de vinculo gerado`;
- codigo atualiza sem sair da tela;
- pessoa ja vinculada nao deve permitir gerar novo codigo.

### 5.5 Teste de vinculo cuidador/dependente

Com a conta do cuidador:

1. Gere ou copie o codigo da pessoa cuidada.
2. Faca logout.

Com a conta do dependente:

1. Entre no app.
2. Va para a area de vinculo com responsavel.
3. Digite o codigo.
4. Confirme.

Resultado esperado:

- o vinculo e criado;
- codigo usado nao deve poder ser reutilizado;
- ao sair e entrar de novo no dependente, nao deve aparecer como se ainda
  precisasse vincular;
- cuidador deve conseguir ver a pessoa como vinculada.

### 5.6 Teste de estoque/tratamentos como cuidador

Use a conta de cuidador.

1. Na Home, selecione uma pessoa cuidada especifica.
2. Va em `Estoque`.
3. Cadastre um tratamento para essa pessoa.
4. Confira se aparece em `Ativos`.
5. Abra o tratamento/estoque.
6. Edite a quantidade.
7. Reabasteca adicionando quantidade.
8. Encerre o tratamento.
9. Troque para a aba `Encerrados`.

Resultado esperado:

- tratamento ativo aparece na aba `Ativos`;
- alteracao de estoque nao deve dar erro;
- ao encerrar, tratamento sai dos ativos;
- tratamento encerrado aparece em `Encerrados`;
- doses futuras pendentes daquele tratamento nao devem continuar poluindo a
  agenda.

### 5.7 Teste de estoque/tratamentos como dependente

Use a conta do dependente vinculada.

1. Entre no app como dependente.
2. Va em `Estoque`.
3. Confira os tratamentos que pertencem a ele.
4. Compare com o cuidador filtrando essa mesma pessoa.

Resultado esperado:

- cuidador e dependente devem ver dados coerentes para a mesma pessoa;
- se o cuidador cadastrou um tratamento para Joao, Joao deve ver esse tratamento;
- estoque nao deve aparecer branco/vazio quando ha tratamento ativo.

### 5.8 Teste de doses e atualizacao visual

Com duas janelas, se possivel:

1. Janela A: login como cuidador.
2. Janela B: login como dependente.
3. No cuidador, filtre a pessoa cuidada.
4. No dependente, marque uma dose como tomada.
5. Observe a janela do cuidador.

Resultado esperado:

- o dependente ve a dose como tomada;
- o cuidador tambem recebe atualizacao visual/notificacao local;
- nao deve precisar trocar de aba para atualizar os dados principais.

### 5.9 Teste de consultas

Use cuidador ou uso pessoal.

1. Va em `Consultas`.
2. Crie uma nova consulta.
3. Se estiver como cuidador, selecione uma pessoa cuidada.
4. Abra a consulta.
5. Toque em `Confirmar consulta`.
6. Volte para Consultas e confira o status.
7. Abra de novo.
8. Toque em `Marcar como realizada`.
9. Crie outra consulta.
10. Abra e toque em `Cancelar consulta`.
11. Crie outra consulta e teste `Reagendar`.

Resultado esperado:

- confirmar deixa como confirmada;
- realizada deixa como realizada/concluida;
- cancelada deixa como cancelada;
- reagendar atualiza data/hora;
- dependente deve ver consultas vinculadas a ele;
- cuidador deve ver consultas da pessoa filtrada.

### 5.10 Teste de historico diario

1. Va em `Historico`.
2. Se for cuidador, teste:
   - `Todos`;
   - uma pessoa especifica.
3. Toque em um dia com dose.
4. Confira os detalhes do dia.

Resultado esperado:

- modal abre sem erro;
- doses tomadas aparecem como `Tomada`;
- doses perdidas aparecem como `Perdida`;
- doses futuras pendentes nao devem ser marcadas como perdidas antes da hora;
- nomes das pessoas aparecem quando o cuidador esta em `Todos`.

### 5.11 Teste de resumo por tratamento no historico

1. Va em `Historico`.
2. Escolha o mes atual.
3. Role abaixo do calendario.
4. Veja `Resumo por tratamento`.

Resultado esperado:

- aparece um card por tratamento com doses no mes;
- mostra percentual de adesao;
- mostra tomadas, previstas e perdidas;
- para uso pessoal, mostra apenas tratamentos do proprio usuario;
- para cuidador em `Todos`, agrega os tratamentos visiveis;
- para cuidador filtrado, mostra apenas a pessoa escolhida.

### 5.12 Teste de lembrete de consulta via microservico

Este teste valida a estrutura sem Firebase real.

1. Suba RabbitMQ, core-service, gateway, ms-scheduler e ms-notification.
2. Crie uma consulta para um horario futuro.
3. Configure, se necessario:

```env
APPOINTMENT_REMINDER_LEAD_MINUTES=60
```

4. Aguarde o scheduler sincronizar.
5. Confira logs do `ms-scheduler`.
6. Confira logs do `ms-notification`.

Resultado esperado:

- scheduler identifica consulta futura;
- scheduler publica `AppointmentReminder`;
- notification consome o evento;
- notification registra/processa a notificacao.

## 6. Checklist rapido de aceite

Use este checklist para marcar o que validou:

- [ ] Login funciona.
- [ ] Logout e login novamente nao quebram contexto.
- [ ] Uso pessoal nao mostra linguagem de cuidador/dependente.
- [ ] Cuidador consegue cadastrar pessoa cuidada.
- [ ] Cuidador consegue gerar novo codigo de vinculo.
- [ ] Dependente consegue vincular usando codigo.
- [ ] Codigo usado nao pode ser reutilizado.
- [ ] Estoque aparece corretamente para cuidador.
- [ ] Estoque aparece corretamente para dependente.
- [ ] Editar estoque funciona.
- [ ] Reabastecer estoque funciona.
- [ ] Encerrar tratamento move para encerrados.
- [ ] Doses futuras do tratamento encerrado nao poluem a agenda.
- [ ] Consulta pode ser confirmada.
- [ ] Consulta pode ser marcada como realizada.
- [ ] Consulta pode ser cancelada.
- [ ] Consulta pode ser reagendada.
- [ ] Consulta do dependente aparece para ele.
- [ ] Historico por dia abre sem erro.
- [ ] Dose tomada aparece como tomada no historico.
- [ ] Resumo por tratamento aparece no historico.
- [ ] Cuidador em `Todos` ve dados agregados.
- [ ] Cuidador filtrando pessoa ve dados daquela pessoa.
- [ ] Microservicos seguem build/typecheck OK.

## 7. Comandos uteis

### Build backend core

```bash
cd backend/core-service
npm run build
```

### Build gateway

```bash
cd backend/gateway
npm run build
```

### Typecheck scheduler

```bash
cd ms-scheduler
npm run typecheck
```

### Typecheck notification

```bash
cd ms-notification
npm run typecheck
```

### Analyze Flutter

```bash
flutter analyze
```

### Rodar app macOS

```bash
flutter run -d macos
```

## 8. Observacoes importantes

- Firebase/FCM real ficou fora desta etapa.
- O backend core usa `synchronize: true`, entao a coluna nova de status de
  medicamento e criada automaticamente ao subir o servico.
- Se futuramente o projeto desligar `synchronize`, sera necessario criar uma
  migration formal no core-service.
- Se o banco local for resetado, as contas de teste precisam ser recriadas.
- Se algum dado antigo parecer inconsistente, teste tambem com uma pessoa
  cuidada nova e um tratamento novo, porque dados antigos podem ter sido criados
  antes do status `active/ended`.
