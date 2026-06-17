# Analise e plano de melhorias do DoseCerta

Este documento consolida uma leitura do repositorio atual, dos requisitos do projeto, da ideia original e dos fluxos testados no app. A intencao e deixar claro o que o DoseCerta deve ser para o usuario final e transformar isso em melhorias implementaveis por etapas.

## 1. Resumo executivo

O DoseCerta ja tem uma base forte: cadastro/login, medicamentos, doses, estoque, historico, consultas, dependentes, microservicos de vinculacao, scheduler e notificacoes. O ponto principal que ainda precisa amadurecer nao e so tecnico: e o modelo mental do produto.

Hoje o aplicativo mistura tres situacoes diferentes:

1. Pessoa que cuida apenas dela mesma.
2. Responsavel/cuidador que gerencia dependentes.
3. Dependente que tem conta propria e aceita ser acompanhado por um responsavel.

Esses tres casos existem no codigo, mas ainda nao aparecem com clareza suficiente para o usuario. O resultado e que algumas telas parecem corretas tecnicamente, mas confusas na experiencia: "meu estoque" versus "estoque do dependente", "todos" versus "eu", dependente cadastrado pelo cuidador versus dependente com conta vinculada, consultas que pertencem ao dependente mas aparecem em contextos diferentes, e assim por diante.

A melhoria mais importante e transformar o app em uma experiencia guiada por contexto:

- **Meu cuidado**: remedios, consultas, estoque e historico da propria pessoa.
- **Cuidados de outra pessoa**: remedios, consultas, estoque e historico de um dependente.
- **Minha rede de cuidado**: vinculos entre responsavel e dependente, permissoes, codigos e status.

Com isso, cada tela passa a responder a uma pergunta simples: "Estou vendo informacoes de quem?".

## 2. Fontes analisadas

- Repositorio Flutter/NestJS atual.
- `README.md` e estrutura dos microservicos.
- Documento de requisitos `DoseCerta_Levantamento_Requisitos`.
- Arquivo de ideia do projeto `Ideia-Projeto`.
- Plano de acao em planilha.
- Imagens do modelo de negocios e analise de produto.
- Fluxos ja testados no app: login, cadastro, vinculacao cuidador/dependente, cadastro de medicamento, tomada de dose, notificacao visual, estoque, consultas e historico.

## 3. Produto em uma frase

O DoseCerta e um aplicativo para organizar tratamentos, doses, estoque, consultas e alertas de saude, tanto para quem cuida de si mesmo quanto para quem acompanha a rotina de outra pessoa.

Essa frase precisa guiar o produto inteiro. Hoje o app ainda parece, em alguns pontos, um app de "dependentes" com modo pessoal acoplado. O ideal e o contrario: ele deve ser um app de **rotina de cuidado**, onde o cuidado pode ser proprio ou compartilhado.

## 4. Personas principais

### 4.1 Pessoa em uso pessoal

Esta pessoa cria uma conta para controlar os proprios medicamentos.

Ela precisa:

- Cadastrar um tratamento.
- Receber lembretes de dose.
- Marcar dose como tomada, adiar ou registrar que esqueceu.
- Ver estoque restante.
- Editar estoque quando comprou mais remedio.
- Encerrar tratamento quando acabou.
- Ver historico por dia.
- Cadastrar consultas.
- Receber lembretes de consultas.

O app deve falar com ela como "voce".

Exemplos:

- "Seus medicamentos de hoje"
- "Seu estoque"
- "Suas consultas"
- "Seu historico"

### 4.2 Responsavel/cuidador

Esta pessoa cria uma conta para acompanhar outras pessoas.

Ela precisa:

- Cadastrar dependentes.
- Gerar codigo de vinculacao.
- Cadastrar medicamentos e consultas para dependentes.
- Ver rapidamente quem precisa de atencao hoje.
- Receber aviso quando o dependente tomou, adiou ou nao tomou a dose.
- Ver historico por dependente.
- Editar estoque dos tratamentos dos dependentes.
- Saber se o dependente ainda nao aceitou o vinculo.

O app deve falar com ela como alguem que gerencia uma lista de pessoas.

Exemplos:

- "Cuidados de hoje"
- "Visualizando Joao"
- "Todos os dependentes"
- "Samuel ainda nao vinculou a conta"

### 4.3 Dependente com conta propria

Esta pessoa usa o app para receber e confirmar os cuidados criados pelo responsavel.

Ela precisa:

- Entrar na propria conta.
- Inserir codigo recebido do responsavel.
- Ver seus remedios e consultas.
- Receber notificacoes.
- Marcar doses como tomadas.
- Saber que o responsavel sera avisado.
- Conseguir desfazer o vinculo se necessario.

Importante: um dependente com conta propria ainda pode usar o app para si mesmo. Ele nao deve ficar preso apenas ao que o cuidador cadastrou.

## 5. Problema central de modelo mental

Hoje existem dois conceitos diferentes usando nomes parecidos:

- **Dependente cadastrado**: registro criado pelo cuidador. Pode existir sem conta propria.
- **Usuario dependente vinculado**: pessoa real que tem conta e aceitou um codigo.

Isso precisa ficar explicito no produto.

Sugestao de linguagem:

- Trocar "Dependentes" por **Pessoas cuidadas** nas telas do cuidador.
- Trocar "Responsavel" por **Minha rede de cuidado** ou **Responsavel vinculado** no perfil do dependente.
- Mostrar status claros:
  - "Aguardando aceite"
  - "Vinculo ativo"
  - "Codigo expirado"
  - "Sem conta vinculada"

## 6. Fluxo ideal para o usuario

### 6.1 Cadastro

Tela: "Como voce quer usar o DoseCerta?"

Opcoes recomendadas:

1. **Cuidar de mim**
   - Para quem vai controlar os proprios remedios e consultas.
2. **Cuidar de outra pessoa**
   - Para responsaveis, familiares e cuidadores.
3. **Entrar com codigo de responsavel**
   - Pode aparecer depois do cadastro/login de uso pessoal, nao necessariamente como tipo de conta separado.

Hoje o app tem "Uso Pessoal" e "Responsavel". Isso funciona, mas falta explicar que uma conta pessoal tambem pode aceitar um responsavel depois.

### 6.2 Uso pessoal

Fluxo simples:

1. Usuario entra.
2. Home mostra as doses de hoje.
3. Usuario cadastra medicamento/tratamento.
4. App gera doses.
5. App envia lembrete antes e no horario.
6. Usuario marca como tomada/adiada.
7. Estoque diminui.
8. Historico mostra o dia corretamente.
9. Quando tratamento acaba, ele sai da lista ativa e fica no historico.

Telas principais:

- Inicio
- Tratamentos
- Historico
- Consultas
- Perfil

### 6.3 Cuidador sem dependente ainda

Fluxo recomendado:

1. Cuidador entra.
2. Home mostra estado vazio: "Voce ainda nao acompanha ninguem".
3. Botao principal: "Adicionar pessoa cuidada".
4. Cuidador cria nome, relacao e dados basicos.
5. App gera codigo de vinculacao.
6. Cuidador pode cadastrar remedios mesmo antes do dependente aceitar.
7. Status fica "Aguardando aceite".

Isso resolve o caso comum: o cuidador quer organizar tudo antes de o dependente instalar o app.

### 6.4 Dependente aceitando codigo

Fluxo recomendado:

1. Dependente cria conta ou entra.
2. Perfil mostra bloco "Responsavel vinculado".
3. Ele toca em "Inserir codigo".
4. Digita o codigo.
5. App mostra confirmacao:
   - "Maria passara a acompanhar seus medicamentos, consultas e historico de doses."
6. Dependente confirma.
7. Cuidador recebe evento `LinkEstablished`.
8. Ambos passam a ver os mesmos tratamentos e consultas daquele registro.

Ponto importante: o app precisa mostrar com clareza o que sera compartilhado.

### 6.5 Cuidador usando o app no dia a dia

O seletor de contexto deve deixar claro:

- **Todos**: painel consolidado dos dependentes.
- **Joao**: apenas dados do Joao.
- **Samuel**: apenas dados do Samuel.

Hoje existe comentario no codigo dizendo que `null` significa "Eu", mas a UI usa "Todos". Essa divergencia e perigosa. Para cuidador, `null` deve significar "Todos os acompanhados" em telas agregadas. Se o cuidador tambem tiver remedios proprios, precisa existir uma opcao separada chamada **Eu**.

Modelo ideal:

- Todos
- Eu
- Joao
- Samuel

Se o cuidador nao usa o app para si mesmo, a opcao "Eu" pode ficar escondida ate ele cadastrar um tratamento proprio.

## 7. Melhorias prioritarias de produto

### P0 - Corrigir o modelo de contexto

Problema:

O app precisa responder sempre "dados de quem estou vendo?". Isso ainda aparece espalhado entre providers, query params e textos.

Melhoria:

Criar um `CareContext` unico no app:

```text
CareContext.self
CareContext.allDependents
CareContext.dependent(id)
```

Esse contexto deve alimentar:

- Home
- Tratamentos/estoque
- Historico
- Consultas
- Perfil quando fizer sentido

Criterio de aceite:

- Usuario pessoal nao ve seletor de dependentes.
- Cuidador com dependentes ve "Todos" e cada dependente.
- Cuidador com tratamento proprio tambem ve "Eu".
- Ao trocar contexto, todas as telas buscam dados do mesmo contexto.
- Textos mudam conforme contexto: "Meu estoque", "Estoque de Joao", "Todos os estoques".

### P0 - Renomear Estoque para Tratamentos

Problema:

"Estoque" sozinho passa a ideia de uma prateleira infinita de remedios. Mas o usuario pensa em tratamento: "Estou tomando paracetamol por 5 dias".

Melhoria:

Transformar a tela em **Tratamentos** ou **Tratamentos e estoque**.

Cada card deve mostrar:

- Nome do remedio.
- Dosagem.
- Frequencia.
- Periodo do tratamento.
- Proxima dose.
- Quantidade restante.
- Status: ativo, baixo estoque, encerrado.

Acoes no card:

- Editar estoque.
- Reabastecer.
- Editar tratamento.
- Encerrar tratamento.
- Ver historico desse tratamento.

Criterio de aceite:

- Medicamento com `currentQuantity = 0` nao polui a lista principal.
- Tratamento encerrado vai para uma aba/filtro "Encerrados".
- Historico continua preservando doses antigas.
- Usuario pessoal e cuidador usam a mesma logica.

### P0 - Padronizar dependente cadastrado versus dependente vinculado

Problema:

Um cuidador pode criar "Joao" antes de Joao ter conta. Depois Joao cria conta e vincula. Hoje isso existe, mas nao fica claro para o usuario.

Melhoria:

Na tela de pessoas cuidadas, cada pessoa deve ter:

- Nome.
- Relacao.
- Status do vinculo.
- Codigo atual, se ainda pendente.
- Data de expiracao.
- Botao para gerar novo codigo.
- Botao para remover/desvincular.

Texto sugerido:

- "Aguardando Joao inserir o codigo"
- "Joao vinculado"
- "Codigo expirado. Gere um novo codigo."

Criterio de aceite:

- Codigo usado nao aparece como disponivel.
- Codigo expirado nao ativa vinculo.
- Vinculo duplicado nao e criado.
- Dependente logado ve o responsavel como ativo depois de logout/login.

### P0 - Corrigir datas por fuso horario local

Problema:

O historico e algumas consultas usam ranges UTC. Em horarios perto da meia-noite, uma dose pode cair no dia errado para o usuario no Brasil.

Melhoria:

Armazenar e consultar datas considerando o fuso do usuario. Para MVP, usar `America/Sao_Paulo` de forma consistente no backend e no app.

Criterio de aceite:

- Dose de 00:55 aparece no dia correto.
- Historico por dia bate com a Home.
- Consultas mostram a mesma data/hora para cuidador e dependente.

### P0 - Garantir paridade entre API principal e gateway

Problema:

O app chama o gateway. Quando uma rota nova e criada no core-service, ela tambem precisa existir no gateway. Isso ja causou bugs em estoque, consultas e historico.

Melhoria:

Criar testes de contrato simples:

- Todas as rotas usadas pelo app existem no gateway.
- Gateway repassa `dependentId`, `date`, `month` e body corretamente.
- Erros do core-service chegam com mensagem amigavel.

Criterio de aceite:

- `flutter analyze` sem erro.
- Teste backend passa para rotas de medications, appointments, history, dependents.
- Nenhuma feature nova entra sem rota no gateway.

## 8. Melhorias importantes de notificacao

### P1 - Push real no mobile

Hoje o projeto tem notificacao visual e microservico com provider mock/FCM, mas para celular real precisa fechar o ciclo:

- Solicitar permissao de notificacao no app.
- Registrar token FCM no `ms-notification`.
- Atualizar token quando mudar.
- Mostrar notificacao local se app estiver em foreground.
- Abrir a tela correta ao tocar na notificacao.

Criterio de aceite:

- Dependente recebe aviso 5 minutos antes da dose.
- Dependente recebe aviso no horario.
- Cuidador recebe aviso quando dependente toma, adia ou perde dose.
- Notificacao nao duplica se o evento chegar duas vezes.

### P1 - Lembrete de consultas

Requisito original fala de consultas, mas os microservicos atuais focam em dose.

Melhoria:

Adicionar evento:

```json
{
  "eventType": "AppointmentReminder",
  "version": "1.0",
  "producer": "ms-scheduler",
  "data": {
    "appointmentId": "uuid",
    "userId": "uuid",
    "dependentId": "uuid | null",
    "doctorName": "Ana Luiza",
    "specialty": "Clinico",
    "scheduledAt": "2026-06-18T14:50:00Z",
    "remindBeforeMinutes": 60
  }
}
```

Criterio de aceite:

- Usuario pessoal recebe lembrete de consulta.
- Dependente vinculado recebe lembrete da consulta dele.
- Cuidador recebe lembrete de consulta dos dependentes, se habilitado.

### P1 - Preferencias de notificacao por pessoa

O perfil ja tem uma tela de preferencias, mas ela ainda parece local.

Melhoria:

Salvar preferencias no backend:

- Doses.
- Estoque baixo.
- Consultas.
- Avisos de cuidador.
- Horario silencioso.

Isso evita notificar demais.

## 9. Melhorias de consultas

### P1 - Consultas precisam pertencer claramente a alguem

Problema:

Na tela do cuidador, uma consulta aparece com o nome do dependente. Na tela do dependente, ela tambem deve aparecer como "minha consulta". Isso ja foi ajustado em parte, mas precisa virar regra de produto.

Melhoria:

Ao criar consulta, o app deve pedir:

- Para mim.
- Para Joao.
- Para Samuel.

Depois disso, todas as telas usam esse dono.

Criterio de aceite:

- Cuidador ve consultas de todos os dependentes em "Todos".
- Cuidador ve apenas Joao quando seleciona Joao.
- Joao logado ve a consulta criada para Joao.
- Usuario pessoal ve apenas suas consultas.

### P1 - Status de consulta mais claro

Hoje existem status como scheduled, confirmed, done/rescheduled. O produto deve padronizar:

- Agendada.
- Confirmada.
- Reagendada.
- Concluida.
- Cancelada.

Acoes:

- Confirmar.
- Reagendar.
- Cancelar.
- Marcar como concluida.

## 10. Melhorias de historico

### P1 - Historico como relatorio de cuidado

A tela de calendario por dia esta no caminho certo. A proxima melhoria e transformar o historico em algo util para medico/cuidador.

Melhorias:

- Filtro por pessoa.
- Filtro por medicamento.
- Filtro por periodo.
- Indicador de adesao: percentual de doses tomadas.
- Lista de doses esquecidas.
- Exportar relatorio simples em PDF no futuro.

Para uso pessoal:

- "Voce tomou 18 de 20 doses este mes."

Para cuidador:

- "Joao tomou 18 de 20 doses este mes."

## 11. Melhorias de emergencia

O requisito original cita botao de emergencia. Hoje existem contatos de emergencia no perfil, mas o fluxo completo ainda precisa ficar mais visivel.

Melhoria:

Criar uma acao clara:

- Botao "Emergencia" no perfil ou home.
- Tela de confirmacao.
- Lista de contatos.
- Acao de ligar/enviar mensagem.
- Evento para cuidador se houver vinculo.

Criterio de aceite:

- Usuario pessoal consegue acionar contato.
- Dependente consegue avisar responsavel.
- Cuidador ve alerta destacado.

## 12. Melhorias tecnicas por area

### 12.1 App Flutter

Pontos bons:

- Estrutura por feature.
- Riverpod organizado.
- Tema consistente.
- App ja suporta macOS para teste rapido.
- Providers de cache e invalidacao ja existem.

Melhorias:

- Criar `CareContext` central.
- Reduzir `Timer.periodic` na Home e usar eventos/notificacoes/invalidation mais direcionada quando possivel.
- Padronizar empty states por persona.
- Criar testes de widget para fluxos principais.
- Criar fixtures reais para uso pessoal, cuidador e dependente vinculado.
- Melhorar textos da UI para explicar "quem esta sendo cuidado".

### 12.2 Backend principal

Pontos bons:

- Separacao gateway/auth/core.
- Rotas principais implementadas.
- Permissao por `dependentId` existe em varios servicos.
- Eventos de dose tomada/adiada ja sao publicados.

Melhorias:

- Criar testes de permissao para dependente/caregiver/personal.
- Padronizar status de consulta.
- Tratar fuso horario explicitamente.
- Criar endpoint de contexto do usuario: quem sou eu, quem cuido, quem me cuida.
- Formalizar "dono do tratamento" e "pessoa cuidada".

### 12.3 Microservicos

Pontos bons:

- `ms-linking` resolve vinculos e publica evento.
- `ms-scheduler` publica dose no horario e lembrete antes.
- `ms-notification` consome eventos e registra historico.
- Bancos separados existem.

Melhorias:

- Adicionar eventos de consulta.
- Limpar/sincronizar doses removidas ou tomadas no `ms-scheduler`, para evitar lembrete antigo.
- Criar healthchecks funcionais para RabbitMQ e banco.
- Criar testes de idempotencia por `correlationId`.
- Documentar topologia RabbitMQ em um arquivo de arquitetura.

### 12.4 Seguranca e LGPD

Melhorias necessarias:

- Termo de consentimento quando dependente aceita cuidador.
- Tela explicando dados compartilhados.
- Exportar dados pessoais no futuro.
- Excluir conta/dados.
- Revogar vinculo.
- Nao expor stack trace em producao.
- Separar API keys reais de exemplos.
- Revisar whitelist de IP se for apresentar como requisito de microservicos.

## 13. Backlog recomendado por prioridade

### Fase 1 - Clareza do fluxo

1. Criar documento de modelo de dominio do cuidado.
2. Refatorar textos de cadastro/onboarding.
3. Criar `CareContext` no app.
4. Padronizar seletor: Todos, Eu, dependentes.
5. Ajustar titulos das telas conforme contexto.
6. Melhorar tela de pessoas cuidadas/status de vinculo.

### Fase 2 - Tratamentos e estoque

1. Renomear tela para Tratamentos.
2. Mostrar tratamentos ativos.
3. Criar filtro/aba de encerrados.
4. Permitir editar estoque, reabastecer e encerrar.
5. Criar alerta de estoque baixo.
6. Garantir comportamento identico para uso pessoal e dependente.

### Fase 3 - Notificacoes completas

1. Fechar registro de device token FCM.
2. Implementar push real.
3. Criar lembrete de consulta.
4. Criar preferencias persistidas.
5. Abrir tela correta ao tocar na notificacao.

### Fase 4 - Historico como relatorio

1. Melhorar filtros.
2. Mostrar adesao por tratamento.
3. Mostrar doses esquecidas.
4. Exportar relatorio.
5. Preparar visao para consulta medica.

### Fase 5 - Seguranca, LGPD e acabamento

1. Consentimento de vinculo.
2. Revogacao de vinculo.
3. Excluir conta.
4. Auditoria basica.
5. Testes de permissao.
6. Documentacao final para banca.

## 14. Promptzao para implementar as melhorias depois

Use este prompt quando for iniciar a proxima etapa de desenvolvimento.

```text
Voce esta no repositorio DoseCerta.

Objetivo: melhorar a clareza do fluxo de uso pessoal, cuidador e dependente, mantendo o que ja funciona.

Antes de codar:
1. Leia ANALISE_MELHORIAS_DOSECERTA.md.
2. Leia README.md.
3. Inspecione:
   - lib/core/providers
   - lib/shared/widgets/dependent_context_selector.dart
   - lib/features/home
   - lib/features/stock
   - lib/features/appointments
   - lib/features/history
   - lib/features/dependents
   - backend/core-service/src/dependents
   - backend/core-service/src/medications
   - backend/core-service/src/appointments
   - backend/core-service/src/history

Implemente em etapas pequenas, com commits separados:

Etapa 1 - Modelo de contexto
- Criar um modelo unico de contexto de cuidado no app:
  - self
  - allDependents
  - dependent(id)
- Substituir usos ambiguos de selectedDependentId null.
- Garantir que cuidador consiga diferenciar Todos, Eu e cada dependente.
- Usuario pessoal nao deve ver seletor de dependentes.

Etapa 2 - Textos e fluxo de cadastro
- Melhorar copy da tela de tipo de conta.
- Explicar que Uso Pessoal pode ser usado sozinho ou com responsavel vinculado.
- Explicar que Responsavel serve para acompanhar outras pessoas.
- Ajustar textos das telas conforme contexto atual.

Etapa 3 - Pessoas cuidadas e vinculo
- Melhorar tela de dependentes/pessoas cuidadas.
- Mostrar status: aguardando aceite, vinculo ativo, codigo expirado.
- Permitir gerar novo codigo quando expirado.
- Mostrar para dependente qual responsavel esta vinculado.
- Explicar quais dados sao compartilhados.

Etapa 4 - Tratamentos e estoque
- Renomear a experiencia de Estoque para Tratamentos.
- Mostrar apenas tratamentos ativos por padrao.
- Medicamento com estoque zero deve sair da lista principal.
- Criar area/filtro de encerrados.
- Permitir editar estoque, reabastecer e encerrar tratamento.
- Garantir que uso pessoal, cuidador e dependente vinculado funcionem.

Etapa 5 - Consultas e historico
- Garantir que toda consulta tenha dono claro: eu ou dependente.
- Garantir que dependente vinculado veja consultas criadas para ele.
- Corrigir fuso horario no historico por dia.
- Historico deve bater com a Home.

Etapa 6 - Notificacoes
- Fechar notificacao real ou mock visual consistente.
- Enviar lembrete 5 minutos antes da dose.
- Criar evento de lembrete de consulta.
- Respeitar preferencias de notificacao.

Obrigatorio:
- Nao quebrar fluxos ja testados.
- Pensar sempre em uso pessoal e cuidador/dependente.
- Rodar flutter analyze.
- Quando alterar backend, rodar testes/build relevantes.
- Fazer commits pequenos e descritivos.
```

## 15. Cenarios de teste que precisam existir

### Uso pessoal

1. Criar conta pessoal.
2. Cadastrar tratamento.
3. Ver dose na Home.
4. Receber lembrete.
5. Marcar dose como tomada.
6. Ver estoque diminuir.
7. Editar estoque.
8. Encerrar tratamento.
9. Ver historico do dia.
10. Criar consulta e ver na tela de consultas.

### Cuidador com dependente sem conta

1. Criar conta de cuidador.
2. Adicionar pessoa cuidada.
3. Gerar codigo.
4. Cadastrar tratamento para essa pessoa.
5. Ver em "Todos".
6. Ver ao selecionar a pessoa.
7. Cadastrar consulta para essa pessoa.
8. Ver historico separado.

### Dependente vinculado

1. Criar conta pessoal do dependente.
2. Inserir codigo do cuidador.
3. Ver responsavel vinculado no perfil.
4. Ver medicamento criado pelo cuidador.
5. Tomar dose.
6. Cuidador recebe aviso.
7. Dependente ve historico correto.
8. Cuidador ve historico correto.
9. Dependente ve consulta criada para ele.

### Cuidador que tambem usa para si

1. Criar conta de cuidador.
2. Cadastrar tratamento proprio.
3. Cadastrar dependente.
4. Seletor mostra "Todos", "Eu" e dependentes.
5. "Eu" mostra dados proprios.
6. "Todos" mostra consolidado dos dependentes e, se decidido pelo produto, pode incluir ou nao o cuidador. Essa regra precisa estar explicita.

## 16. Decisoes de produto pendentes

Estas decisoes precisam ser tomadas antes de novas grandes alteracoes:

1. Cuidador em "Todos" deve incluir os remedios dele mesmo ou apenas dependentes?
2. Dependente vinculado pode editar/remover tratamento criado pelo cuidador?
3. Cuidador pode ver todos os dados do dependente ou apenas dados compartilhados?
4. Consulta criada pelo cuidador pode ser editada pelo dependente?
5. Tratamento com estoque zero deve ser encerrado automaticamente ou pedir confirmacao?
6. Notificacao de dose perdida deve disparar depois de quantos minutos?
7. Qual sera o fuso horario oficial do MVP?
8. Premium/freemium entra no MVP ou fica apenas como proposta de negocio?

## 17. Minha recomendacao pratica

A proxima melhor etapa nao e adicionar mais tela solta. E consolidar o conceito de **contexto de cuidado**.

Se isso ficar claro, o resto encaixa:

- Home sabe de quem sao as doses.
- Tratamentos sabem de quem e o estoque.
- Consultas sabem para quem foram marcadas.
- Historico sabe qual pessoa esta sendo analisada.
- Notificacoes sabem quem recebe e quem deve ser avisado.
- O usuario entende o app sem precisar adivinhar.

Ordem recomendada para desenvolvimento:

1. `feat(app): add care context model`
2. `refactor(app): align caregiver and personal copy`
3. `feat(dependents): improve cared people linking status`
4. `feat(stock): rename inventory to treatments`
5. `fix(history): use local care dates consistently`
6. `feat(notifications): add appointment reminders`

Essa ordem reduz retrabalho e deixa o produto mais facil de explicar na banca.
