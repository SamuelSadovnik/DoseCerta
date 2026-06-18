# Plano de melhorias: emergência, informações médicas e contatos importantes

Este documento propõe melhorias para transformar a área de **Informações adicionais**, **Contatos de emergência** e **Botão de emergência** em um diferencial real do DoseCerta.

O foco é atender dois fluxos:

- pessoa que usa o app sozinha para cuidar da própria saúde;
- cuidador/responsável acompanhando uma pessoa cuidada/dependente.

## 1. Estado atual encontrado no projeto

Hoje o app já possui uma boa base:

- Tela de **Informações adicionais** no Perfil.
- Tela de **Contatos de emergência** no Perfil.
- Salvamento no backend via `updateProfile`.
- Fallback em cache local quando o backend está indisponível.
- Campos atuais de informações adicionais:
  - alergias;
  - doenças/condições;
  - tipo sanguíneo;
  - observações médicas.
- Campos atuais de contato de emergência:
  - nome;
  - telefone;
  - relação.
- Botão visual de **Emergência** em telas de feedback de dose/consulta.
- Botão hoje mostra principalmente a intenção de “Chamar responsável”, mas ainda não tem um fluxo completo de emergência.

No backend, os dados existem no `auth-service`:

- `additionalInfo` como JSON;
- `emergencyContacts` como JSON;
- retorno desses dados no perfil público do usuário.

## 2. Problema principal

Hoje essas funcionalidades existem, mas ainda parecem “configurações soltas”.

Para virar diferencial do app, elas precisam responder perguntas reais do usuário:

- Se eu passar mal, quem o app chama?
- Se eu não puder responder, quais informações médicas aparecem rapidamente?
- Se sou cuidador, consigo ver dados importantes da pessoa que cuido?
- Se sou dependente, consigo chamar meu responsável em um toque?
- Se uso sozinho, consigo configurar contatos prioritários?
- Se estou sem internet, ainda consigo acessar dados críticos?

## 3. Objetivo da melhoria

Transformar o DoseCerta em um app que não apenas lembra remédios, mas também ajuda em situações de risco.

Objetivos:

- deixar dados médicos essenciais fáceis de cadastrar;
- deixar contatos de emergência acionáveis;
- criar um fluxo claro para o botão de emergência;
- diferenciar o comportamento entre uso pessoal e cuidado compartilhado;
- permitir que cuidador veja dados relevantes da pessoa cuidada;
- registrar eventos de emergência no histórico;
- notificar responsáveis quando houver emergência;
- manter dados críticos disponíveis mesmo offline.

## 4. Novo conceito: Cartão de Saúde

Sugestão: renomear ou complementar **Informações adicionais** para **Cartão de Saúde**.

Esse nome é mais claro para o usuário.

O Cartão de Saúde seria um resumo rápido com:

- alergias;
- condições de saúde;
- tipo sanguíneo;
- medicamentos de uso contínuo;
- observações importantes;
- médico principal;
- plano de saúde;
- número da carteirinha;
- hospital preferencial;
- restrições alimentares;
- necessidades especiais;
- contato principal de emergência.

Esse cartão pode aparecer:

- no Perfil;
- dentro da tela de Pessoa cuidada;
- no fluxo de emergência;
- em uma tela rápida antes de ligar para alguém;
- em modo offline.

## 5. Melhorias para uso pessoal

Fluxo: pessoa usa o app sozinha e quer controlar a própria saúde.

### 5.1. Perfil mais orientado à segurança

Na tela de Perfil, a seção `Conta` poderia virar algo como:

- Meu Cartão de Saúde
- Meus Contatos de Emergência
- Preferências de Emergência

Isso ajuda o usuário a entender que não é só “informação extra”.

### 5.2. Cartão de Saúde com completude

Criar um indicador de preenchimento:

```text
Cartão de Saúde 60% completo
Complete alergias, contatos e tipo sanguíneo para emergências.
```

Campos recomendados:

- Tipo sanguíneo.
- Alergias.
- Condições diagnosticadas.
- Medicamentos contínuos.
- Observações médicas.
- Médico de referência.
- Plano de saúde.
- Hospital preferencial.

### 5.3. Contato principal de emergência

Hoje todos os contatos são iguais. Melhorar para:

- contato principal;
- contato secundário;
- médico;
- familiar;
- vizinho;
- cuidador;
- outro.

Cada contato poderia ter:

- nome;
- telefone;
- relação;
- prioridade;
- pode receber notificações;
- pode ser chamado por ligação;
- pode receber mensagem padrão.

### 5.4. Botão de emergência para uso pessoal

Quando a pessoa usa sozinha, o botão não deve dizer “Chamar responsável”.

Texto melhor:

```text
Emergência
Ligar para contato principal
```

Ao tocar, abrir uma tela intermediária:

- Ligar para contato principal.
- Enviar aviso para contatos.
- Ver Cartão de Saúde.
- Chamar emergência pública.

No Brasil, o app poderia sugerir:

- SAMU `192`;
- Bombeiros `193`;
- Polícia `190`.

Importante: o app não deve ligar automaticamente sem confirmação, para evitar toque acidental.

### 5.5. Mensagem rápida de emergência

Permitir enviar uma mensagem pronta:

```text
Preciso de ajuda. Este é um alerta de emergência enviado pelo DoseCerta.
Meu cartão de saúde contém informações importantes.
```

Futuro:

- incluir localização;
- incluir últimas doses tomadas;
- incluir contato do médico;
- incluir resumo do Cartão de Saúde.

### 5.6. Acesso offline

Dados críticos precisam ficar disponíveis offline:

- Cartão de Saúde;
- contatos de emergência;
- telefone principal;
- última sincronização.

O app já usa cache local em perfil. A melhoria seria deixar isso explícito e confiável.

## 6. Melhorias para cuidador/dependente

Fluxo: cuidador acompanha uma ou mais pessoas cuidadas.

### 6.1. Cartão de Saúde por pessoa cuidada

Hoje as informações adicionais pertencem ao usuário logado. Para cuidador, isso precisa existir também por pessoa cuidada.

Exemplo:

- Cuidador Samuel cuida de João.
- João tem alergia a dipirona.
- Essa informação precisa estar no perfil de João, não no perfil do cuidador.

Sugestão:

- adicionar `healthInfo` no modelo de `Dependent`;
- adicionar `emergencyContacts` também por `Dependent`;
- permitir que o cuidador edite esses dados;
- permitir que o dependente vinculado visualize/atualize, se permitido.

### 6.2. Permissões simples

Quando a pessoa cuidada tem conta vinculada, pode existir uma permissão:

```text
Quem pode editar meu Cartão de Saúde?
```

Opções:

- somente eu;
- eu e meu responsável;
- somente meu responsável.

Para o projeto atual, uma versão simples já resolve:

- cuidador pode editar pessoa cuidada que ele criou;
- dependente vinculado pode visualizar;
- dependente pode sugerir/atualizar dados próprios.

### 6.3. Tela de Pessoa Cuidada mais forte

Na tela de detalhe da pessoa cuidada, adicionar blocos:

- Cartão de Saúde.
- Contatos de emergência.
- Responsável principal.
- Última atualização dos dados.
- Botão de emergência.

Exemplo:

```text
João
Conta vinculada

Cartão de Saúde
Alergias: Dipirona
Condições: Hipertensão
Tipo sanguíneo: O+

Contatos de emergência
Maria - Mãe - (11) 99999-9999

[Editar cartão] [Chamar contato]
```

### 6.4. Botão de emergência para dependente vinculado

Quando o dependente toca em emergência:

1. App abre confirmação rápida.
2. Mostra opções:
   - Chamar responsável;
   - Chamar contato de emergência;
   - Chamar SAMU;
   - Ver Cartão de Saúde.
3. Se escolher chamar responsável:
   - liga para o telefone do responsável, se existir;
   - publica evento de emergência;
   - gera notificação para o cuidador.

Texto melhor:

```text
Emergência
Chamar responsável ou contato principal
```

### 6.5. Botão de emergência para cuidador

Quando o cuidador está vendo uma pessoa cuidada, o botão de emergência deve ter outro sentido:

- ligar para a pessoa cuidada;
- ligar para contato de emergência da pessoa cuidada;
- abrir Cartão de Saúde;
- registrar ocorrência.

Exemplo:

```text
Emergência de João
Ligar para João
Ligar para contato principal
Ver Cartão de Saúde
Registrar ocorrência
```

### 6.6. Registro de ocorrência

Toda emergência acionada pode virar um item no histórico.

Campos:

- quem acionou;
- para quem foi;
- data/hora;
- tipo:
  - ligação para responsável;
  - ligação para contato;
  - chamada pública;
  - alerta enviado;
- observação opcional;
- status:
  - iniciado;
  - contato realizado;
  - sem resposta;
  - resolvido.

Isso é um diferencial forte para cuidador.

## 7. Melhorias no backend

Hoje `additionalInfo` e `emergencyContacts` ficam no usuário. Isso atende uso pessoal, mas não atende bem pessoa cuidada gerenciada.

Sugestão de evolução:

### 7.1. Para usuário

Manter:

- `User.additionalInfo`;
- `User.emergencyContacts`.

Uso:

- pessoa usando sozinha;
- dependente com conta própria;
- cuidador configurando os próprios dados.

### 7.2. Para pessoa cuidada

Adicionar no domínio de `Dependent`:

```ts
healthInfo?: {
  allergies?: string;
  conditions?: string;
  bloodType?: string;
  medicationsNotes?: string;
  healthInsurance?: string;
  insuranceNumber?: string;
  preferredHospital?: string;
  doctorName?: string;
  doctorPhone?: string;
  notes?: string;
};

emergencyContacts?: Array<{
  id?: string;
  name: string;
  phone: string;
  relation?: string;
  priority?: number;
  canNotify?: boolean;
}>;
```

### 7.3. Endpoints sugeridos

Para usuário logado:

```http
GET /api/users/me/health-card
PUT /api/users/me/health-card
GET /api/users/me/emergency-contacts
POST /api/users/me/emergency-contacts
PATCH /api/users/me/emergency-contacts/:id
DELETE /api/users/me/emergency-contacts/:id
```

Para pessoa cuidada:

```http
GET /api/dependents/:id/health-card
PUT /api/dependents/:id/health-card
GET /api/dependents/:id/emergency-contacts
POST /api/dependents/:id/emergency-contacts
PATCH /api/dependents/:id/emergency-contacts/:contactId
DELETE /api/dependents/:id/emergency-contacts/:contactId
```

Para emergência:

```http
POST /api/emergency/events
GET /api/emergency/events?dependentId=
PATCH /api/emergency/events/:id/resolve
```

## 8. Eventos RabbitMQ sugeridos

Para integrar com `ms-notification`, criar eventos:

### 8.1. `EmergencyTriggered`

```json
{
  "eventType": "EmergencyTriggered",
  "version": "1.0",
  "timestamp": "2026-06-18T14:00:00Z",
  "correlationId": "uuid",
  "producer": "core-service",
  "data": {
    "eventId": "uuid",
    "triggeredByUserId": "uuid",
    "dependentId": "uuid | null",
    "caregiverId": "uuid | null",
    "targetUserId": "uuid | null",
    "type": "call_caregiver | call_contact | public_emergency | alert_only",
    "message": "Preciso de ajuda",
    "phone": "+5511999999999"
  }
}
```

### 8.2. `EmergencyResolved`

```json
{
  "eventType": "EmergencyResolved",
  "version": "1.0",
  "timestamp": "2026-06-18T14:10:00Z",
  "correlationId": "uuid",
  "producer": "core-service",
  "data": {
    "eventId": "uuid",
    "resolvedByUserId": "uuid",
    "dependentId": "uuid | null",
    "resolutionNote": "Responsável entrou em contato"
  }
}
```

## 9. Melhorias no app mobile

### 9.1. Renomear telas

Atual:

- Informações adicionais
- Contatos de emergência

Sugestão:

- Cartão de Saúde
- Rede de Emergência

Ou manter nomes atuais, mas mudar a apresentação:

```text
Cartão de Saúde
Informações importantes para atendimento.

Contatos de emergência
Pessoas que podem ser chamadas em situações urgentes.
```

### 9.2. Nova Home do perfil

No Perfil, mostrar resumo:

```text
Segurança
Cartão de Saúde: 3 de 6 campos preenchidos
Contatos de emergência: 2 cadastrados
Botão de emergência: contato principal definido
```

### 9.3. Tela de emergência

Criar uma tela dedicada:

```text
Emergência
Escolha uma ação

[Ligar para responsável]
[Ligar para contato principal]
[Chamar SAMU 192]
[Ver Cartão de Saúde]
```

Para evitar acidente:

- toque no botão abre a tela;
- chamada exige segundo toque;
- opcionalmente, segurar por 2 segundos para disparar alerta.

### 9.4. Botão contextual

O botão de emergência deve mudar conforme o contexto:

Uso pessoal:

```text
Emergência
Chamar contato principal
```

Dependente vinculado:

```text
Emergência
Chamar responsável
```

Cuidador visualizando dependente:

```text
Emergência de João
Ver contatos e dados médicos
```

Cuidador em visão geral:

```text
Emergência
Escolha a pessoa cuidada
```

## 10. Diferença clara entre dados próprios e dados compartilhados

É importante manter a regra já usada no app:

- uso pessoal sem vínculo: dados pertencem ao usuário;
- dependente vinculado: dados pertencem ao perfil compartilhado;
- cuidador: dados pertencem à pessoa cuidada selecionada;
- cuidador em `Todos`: precisa escolher uma pessoa antes de editar dados médicos.

Isso evita confusão parecida com a que já aconteceu em tratamentos/consultas.

## 11. Sugestão de fluxo completo

### 11.1. Pessoa usando sozinha

1. Usuário cria conta em `Minha saúde`.
2. Entra no Perfil.
3. Acessa `Cartão de Saúde`.
4. Preenche alergias, tipo sanguíneo, condições e observações.
5. Acessa `Rede de Emergência`.
6. Cadastra contatos.
7. Define contato principal.
8. Se tocar em emergência:
   - app mostra contato principal;
   - oferece ligar;
   - oferece SAMU;
   - mostra Cartão de Saúde.

### 11.2. Cuidador criando pessoa cuidada sem conta

1. Cuidador cria pessoa cuidada.
2. Entra no detalhe da pessoa.
3. Preenche Cartão de Saúde da pessoa.
4. Cadastra contatos de emergência da pessoa.
5. Pode cadastrar tratamentos/consultas.
6. Se houver emergência, cuidador tem acesso rápido aos dados.

### 11.3. Pessoa cuidada com conta vinculada

1. Cuidador cria pessoa cuidada.
2. Pessoa cuidada cria conta em `Minha saúde`.
3. Pessoa cuidada usa código para vincular.
4. Cartão de Saúde passa a ser compartilhado.
5. Dependente pode acionar emergência para chamar responsável.
6. Responsável recebe notificação/evento.
7. Evento fica registrado no histórico.

## 12. MVP recomendado

Para não crescer demais, eu faria em etapas.

### Etapa 1: melhorar UX sem mexer pesado no banco

- Renomear/reestruturar visualmente as telas.
- Melhorar campos do Cartão de Saúde do usuário.
- Melhorar contatos com prioridade.
- Ajustar texto do botão de emergência conforme contexto.
- Criar tela intermediária de emergência.
- Fazer botão ligar para contato real usando `url_launcher`.
- Melhorar empty states dessas telas.

### Etapa 2: dados médicos por pessoa cuidada

- Adicionar `healthInfo` e `emergencyContacts` em `Dependent`.
- Criar endpoints no backend.
- Criar telas para editar dados da pessoa cuidada.
- Integrar tela de detalhe da pessoa cuidada.
- Sincronizar dependente vinculado e cuidador.

### Etapa 3: evento real de emergência

- Criar `EmergencyEvent` no backend.
- Publicar `EmergencyTriggered`.
- Consumir no `ms-notification`.
- Mostrar notificação visual para cuidador.
- Salvar no histórico.

### Etapa 4: diferenciais avançados

- Enviar localização.
- Mostrar últimas doses tomadas.
- Exportar Cartão de Saúde em PDF.
- QR Code de emergência.
- Modo tela bloqueada/fácil acesso.
- Compartilhamento temporário com médico.

## 13. Ideias de diferencial para apresentação

Essas ideias deixam o projeto mais forte para banca/professor/colegas:

### 13.1. Cartão de Saúde com QR Code

Gerar um QR Code que abre uma página/local view com:

- nome;
- alergias;
- tipo sanguíneo;
- contatos de emergência;
- medicamentos atuais.

Pode ser apresentado como:

> Em caso de emergência, outra pessoa pode escanear o QR Code e acessar informações essenciais.

### 13.2. Botão SOS inteligente

Um botão que:

- identifica se o usuário é dependente vinculado;
- prioriza responsável;
- se não houver responsável, prioriza contato principal;
- se não houver contato, sugere SAMU;
- registra o evento.

### 13.3. Linha do tempo de emergência

No histórico:

```text
18/06 - 14:32
Emergência acionada por João
Contato: Maria
Status: responsável avisado
```

### 13.4. Check de segurança

Uma tela que mostra:

```text
Seu perfil está pronto para emergências?
[x] Tipo sanguíneo
[x] Alergias
[ ] Contato principal
[ ] Plano de saúde
```

### 13.5. Compartilhamento com médico

Botão:

```text
Compartilhar resumo de saúde
```

Gera um texto ou PDF com:

- tratamentos ativos;
- histórico recente;
- alergias;
- condições;
- consultas futuras.

## 14. Riscos e cuidados

Como envolve saúde, alguns cuidados são importantes:

- Não prometer diagnóstico.
- Não substituir serviço de emergência real.
- Confirmar antes de ligar.
- Deixar claro que dados dependem do preenchimento do usuário.
- Evitar expor dados sensíveis sem autenticação.
- Proteger endpoints com autorização correta.
- Em QR Code público, mostrar apenas dados autorizados.

## 15. Recomendação final

A melhor melhoria agora seria começar pelo **MVP de Emergência**:

1. Transformar Informações adicionais em Cartão de Saúde.
2. Melhorar Contatos de emergência com prioridade.
3. Criar tela intermediária do botão Emergência.
4. Fazer o botão ligar para o contato correto.
5. Adaptar textos por contexto:
   - uso pessoal;
   - dependente vinculado;
   - cuidador visualizando dependente.
6. Depois evoluir para dados médicos por pessoa cuidada.

Essa sequência entrega valor rápido, melhora a usabilidade e cria um diferencial claro para o DoseCerta.
