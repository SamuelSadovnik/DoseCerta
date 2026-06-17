# Prompt: Redesenhar fluxo de cuidador, pessoa cuidada e uso pessoal no DoseCerta

## 1. Problema atual

O fluxo atual do DoseCerta funciona tecnicamente, mas ainda esta confuso para o
usuario final.

Hoje acontece algo assim:

1. Usuario cria conta como cuidador.
2. App oferece cadastrar uma pessoa cuidada.
3. Usuario cadastra a pessoa.
4. App cai na tela de `Pessoas cuidadas`.
5. O botao de voltar nao funciona de forma util.
6. Ao tocar na pessoa, abre uma tela de detalhe com:
   - codigo de vinculo;
   - proxima dose;
   - tratamentos ativos;
   - botao de cadastrar medicamento.
7. Como a pessoa acabou de ser criada, nao existe dose nem tratamento.
8. A tela passa a sensacao de que o cuidador precisa cadastrar um medicamento
   para conseguir continuar usando o sistema.
9. Isso deixa o fluxo preso e confuso.

Tambem existe uma confusao conceitual:

- O app tem as opcoes `Cuidar de mim` e `Cuidar de outra pessoa`.
- Mas uma pessoa que sera dependente precisa criar conta como `Cuidar de mim`
  para depois virar pessoa cuidada de alguem.
- Isso parece estranho para o usuario, porque ele pensa:
  "Se eu sou dependente, por que estou criando uma conta pessoal?"

O objetivo deste redesign e deixar claro que:

- uma conta de uso pessoal pode existir sozinha;
- uma pessoa cuidada pode ser apenas um perfil gerenciado pelo cuidador;
- esse perfil pode ou nao ser vinculado a uma conta propria depois;
- cadastrar tratamento nao deve ser obrigatorio logo apos criar a pessoa cuidada;
- o cuidador deve conseguir cair na Home e usar o app normalmente.

## 2. Conceito correto do produto

O DoseCerta deve trabalhar com dois conceitos separados:

### 2.1 Conta

Conta e quem faz login no aplicativo.

Exemplos:

- Samuel cria uma conta para cuidar dos proprios remedios.
- Maria cria uma conta para cuidar da mae.
- Joao cria uma conta para marcar as proprias doses e compartilhar com Maria.

### 2.2 Perfil de cuidado

Perfil de cuidado e a pessoa cuja saude esta sendo acompanhada.

Exemplos:

- A propria conta de Samuel.
- A mae cadastrada por Maria.
- Joao, cadastrado inicialmente por Maria e depois vinculado a uma conta propria.

Isso significa:

- Uma pessoa cuidada nao precisa ter conta propria.
- O cuidador pode gerenciar tudo sozinho.
- Se a pessoa cuidada tiver celular e quiser participar, ela cria conta e usa um
  codigo de convite para vincular.
- Depois de vinculada, ela continua tendo uma conta pessoal, mas essa conta fica
  compartilhada com o cuidador.

## 3. Nova linguagem sugerida

Evitar usar "dependente" como termo principal na interface.

Usar:

- `Pessoa cuidada`
- `Pessoas cuidadas`
- `Responsavel`
- `Cuidador`
- `Minha rotina`
- `Perfil gerenciado`
- `Conta vinculada`
- `Convite pendente`

Termos tecnicos como `dependentId` podem continuar no codigo, mas a interface
deve falar a linguagem do usuario.

## 4. Novo fluxo de cadastro

### 4.1 Tela de escolha inicial

Trocar a pergunta atual:

```text
Como voce quer organizar sua rotina de cuidado?
```

Por algo mais direto:

```text
Como voce vai usar o DoseCerta?
```

Opcoes sugeridas:

### Opcao 1: `Minha saude`

Texto:

```text
Vou controlar meus remedios, consultas, estoque e lembretes.
```

Conta criada como:

```text
accountType = personal
```

### Opcao 2: `Cuidar de alguem`

Texto:

```text
Vou acompanhar a rotina de saude de outra pessoa.
```

Conta criada como:

```text
accountType = caregiver
```

### Opcao 3: `Tenho um codigo`

Texto:

```text
Recebi um convite de um responsavel para compartilhar minha rotina.
```

Essa opcao deve ser exibida na entrada do app ou apos cadastro/login.

Ela resolve a confusao do dependente.

Fluxo:

1. Pessoa cria uma conta normal.
2. App pergunta se ela recebeu codigo.
3. Ela digita o codigo.
4. A conta pessoal dela fica vinculada ao cuidador.

Mensagem conceitual:

```text
Sua conta continua sendo sua. O codigo apenas permite que o responsavel acompanhe sua rotina de cuidado.
```

## 5. Novo fluxo apos cadastro de cuidador

### 5.1 Depois de criar conta como cuidador

Nao mandar obrigatoriamente para cadastro de pessoa cuidada.

Enviar direto para a Home.

Home em estado vazio:

```text
Bom dia, Cuidador
Voce ainda nao cadastrou pessoas cuidadas.

Cadastre uma pessoa para acompanhar remedios, consultas e historico.

[Adicionar pessoa cuidada]
```

Bottom nav deve aparecer normalmente.

O usuario pode ir para:

- Inicio;
- Estoque;
- Historico;
- Consultas;
- Perfil.

Mesmo sem pessoa cadastrada, o app nao deve parecer quebrado.

### 5.2 CTA principal

Na Home vazia, o botao principal deve ser:

```text
Adicionar pessoa cuidada
```

Nao deve ser:

```text
Cadastrar medicamento
```

Porque ainda nao existe pessoa/tratamento.

## 6. Novo fluxo apos cadastrar pessoa cuidada

Depois que o cuidador cria uma pessoa cuidada, nao mandar para uma tela sem saida.

Exibir uma tela/modal de sucesso:

Titulo:

```text
Pessoa cuidada adicionada
```

Texto:

```text
Agora voce ja pode acompanhar essa pessoa no DoseCerta.
Voce pode cadastrar um tratamento agora ou enviar um convite para que ela tambem use o app.
```

Acoes:

```text
[Cadastrar tratamento]
[Compartilhar codigo]
[Ir para o inicio]
```

Comportamento:

- `Cadastrar tratamento`: abre cadastro de medicamento ja com essa pessoa
  selecionada.
- `Compartilhar codigo`: copia/mostra codigo e explica o convite.
- `Ir para o inicio`: volta para Home com a pessoa ja listada/selecionavel.

Importante:

- Nenhuma dessas acoes deve ser obrigatoria.
- O usuario sempre deve conseguir ir para a Home.

## 7. Corrigir tela de Pessoas cuidadas

Problema atual:

- Botao de voltar nao funciona bem.
- Tela parece um fim de fluxo.

Correcoes:

1. Se a tela foi aberta apos onboarding/cadastro, o botao de voltar deve levar
   para Home.
2. Se a tela foi aberta pelo Perfil, o botao de voltar deve voltar para Perfil.
3. Se nao houver stack anterior, usar fallback:

```dart
Navigator.of(context).pushReplacementNamed(AppRoutes.home)
```

4. A tela deve ter opcoes claras:

- tocar na pessoa para abrir detalhe;
- adicionar nova pessoa;
- voltar para inicio/perfil.

## 8. Redesenhar detalhe da pessoa cuidada

Hoje a tela mostra codigo, proxima dose, tratamentos e botao de cadastrar
medicamento, mesmo quando a pessoa acabou de ser criada.

Isso confunde.

### 8.1 Estado: pessoa sem tratamento e sem vinculo

Mostrar:

```text
Joao
Perfil gerenciado por voce

Ainda nao ha tratamento cadastrado
Cadastre o primeiro tratamento quando quiser acompanhar medicamentos, estoque e doses.

[Cadastrar tratamento]

Convite opcional
Se Joao tambem for usar o app, compartilhe este codigo.

LEV22S
[Copiar codigo]
[Gerar novo codigo]
```

Nao mostrar:

- `Proxima dose` vazia como bloco principal;
- `Tratamentos ativos` vazio como se fosse erro;
- fluxo que force cadastrar medicamento.

### 8.2 Estado: pessoa com tratamento, sem vinculo

Mostrar:

```text
Perfil gerenciado por voce
Essa pessoa ainda nao tem conta vinculada. Voce pode continuar marcando doses por ela.
```

Depois:

- proxima dose;
- tratamentos ativos;
- convite opcional.

### 8.3 Estado: pessoa vinculada

Mostrar:

```text
Conta vinculada
Essa pessoa tambem pode marcar as proprias doses pelo app.
```

Depois:

- proxima dose;
- tratamentos ativos;
- historico/resumo se couber.

### 8.4 Regra importante

O convite nao deve parecer obrigatorio para continuar.

Texto ruim:

```text
Aguardando vinculacao
```

Texto melhor:

```text
Convite pendente
```

Ou:

```text
Perfil gerenciado por voce
```

Porque o cuidador pode cuidar da pessoa mesmo sem ela aceitar codigo.

## 9. Novo fluxo para pessoa que recebeu codigo

O dependente/pessoa cuidada deve entender assim:

```text
Eu tenho minha conta, mas posso compartilhar minha rotina com um responsavel.
```

### 9.1 Entrada sugerida no login

Na tela de login ou apos criar conta pessoal:

```text
Recebeu um codigo de um responsavel?
[Vincular minha conta]
```

### 9.2 Tela de codigo

Titulo:

```text
Vincular responsavel
```

Texto:

```text
Digite o codigo enviado pelo seu responsavel.
Sua conta continuara sendo sua, mas ele podera acompanhar doses, consultas e historico.
```

Campo:

```text
Codigo de convite
```

Botao:

```text
Vincular conta
```

Feedback de sucesso:

```text
Conta vinculada
Seu responsavel agora pode acompanhar sua rotina de cuidado.
```

## 10. Ajuste na Home do cuidador

### 10.1 Sem pessoa cuidada

Mostrar:

```text
Bom dia, Cuidador
Nenhuma pessoa cuidada cadastrada ainda.

Adicione alguem para acompanhar tratamentos, consultas e lembretes.

[Adicionar pessoa cuidada]
```

Cards:

- nao mostrar doses vazias como erro;
- nao mostrar estoque vazio como erro;
- nao mostrar historico vazio como erro.

### 10.2 Com pessoa cuidada, mas sem tratamento

Mostrar:

```text
Visualizando Joao
Nenhum tratamento cadastrado para Joao.

[Cadastrar tratamento]
```

### 10.3 Com tratamento

Fluxo atual pode permanecer:

- doses do dia;
- proxima dose;
- botao de marcar como tomada;
- estoque/historico/consultas funcionando.

## 11. Ajuste no estoque

Se cuidador nao tiver pessoa cuidada cadastrada:

```text
Nenhuma pessoa cuidada cadastrada
Adicione uma pessoa antes de cadastrar tratamentos.

[Adicionar pessoa cuidada]
```

Se cuidador tem pessoa, mas nenhuma selecionada:

- pode mostrar seletor `Todos`;
- se for cadastrar tratamento em `Todos`, pedir para escolher uma pessoa.

Se usuario e pessoal:

```text
Nenhum tratamento cadastrado
Cadastre seu primeiro tratamento para acompanhar estoque e doses.
```

## 12. Ajuste nas consultas

Mesma logica:

Uso pessoal:

```text
Minhas consultas
```

Cuidador sem pessoa:

```text
Cadastre uma pessoa cuidada antes de adicionar consultas.
```

Cuidador com pessoa:

```text
Consultas de Joao
```

Ou em `Todos`:

```text
Consultas das pessoas cuidadas
```

Ao criar consulta como cuidador:

- se uma pessoa estiver selecionada, preselecionar ela;
- se estiver em `Todos`, exigir escolha de pessoa.

## 13. Ajuste no historico

Uso pessoal:

```text
Meu historico
```

Cuidador sem pessoa:

```text
Nenhum historico ainda
Cadastre uma pessoa cuidada e tratamentos para acompanhar a evolucao.
```

Cuidador com pessoa:

```text
Historico de Joao
```

Cuidador em todos:

```text
Historico das pessoas cuidadas
```

## 14. Fluxo final esperado

### 14.1 Uso pessoal

1. Usuario abre app.
2. Cria conta em `Minha saude`.
3. Cai direto na Home.
4. Home vazia explica que ainda nao ha tratamentos.
5. Usuario cadastra tratamento quando quiser.
6. Doses, estoque, consultas e historico funcionam para ele mesmo.

### 14.2 Cuidador sem convite

1. Usuario cria conta em `Cuidar de alguem`.
2. Cai direto na Home.
3. Home sugere adicionar pessoa cuidada.
4. Cuidador cadastra Joao.
5. App mostra sucesso com opcoes:
   - cadastrar tratamento;
   - compartilhar codigo;
   - ir para inicio.
6. Cuidador pode cadastrar tratamento e marcar doses por Joao.
7. Joao nunca precisa criar conta se nao quiser.

### 14.3 Cuidador com pessoa vinculada

1. Cuidador cadastra Joao.
2. Cuidador compartilha codigo.
3. Joao cria conta em `Minha saude` ou entra se ja tiver conta.
4. Joao toca em `Tenho um codigo`.
5. Joao vincula a conta.
6. Cuidador acompanha Joao.
7. Joao tambem pode marcar as proprias doses.

## 15. Regras de negocio

1. Pessoa cuidada pode existir sem `linkedUserId`.
2. Pessoa cuidada sem `linkedUserId` e um perfil gerenciado pelo cuidador.
3. Pessoa cuidada com `linkedUserId` e uma conta vinculada.
4. Tratamentos podem ser cadastrados antes ou depois do vinculo.
5. Convite/codigo nao e obrigatorio.
6. Codigo usado nao pode ser reutilizado.
7. Codigo expirado pode ser regenerado.
8. Cuidador nao pode se vincular ao proprio codigo.
9. Uma pessoa vinculada nao deve voltar a mostrar CTA principal de vinculo.
10. O app nunca deve prender usuario em tela sem saida.

## 16. Mudancas tecnicas sugeridas

### 16.1 Rotas/estado de navegacao

Revisar:

- `RegisterSuccessPage`
- `DependentsListPage`
- `NewDependentPage`
- `DependentDetailPage`
- `HomePage`
- `StockListPage`
- `AppointmentsListPage`
- `HistoryPage`

Objetivo:

- depois de cadastro, usar `pushNamedAndRemoveUntil(AppRoutes.home, ...)` quando
  fizer sentido;
- evitar stacks quebradas;
- garantir fallback do botao voltar.

### 16.2 Criar estado de onboarding

Adicionar um estado simples para saber de onde a tela foi aberta:

```dart
enum DependentsEntryPoint {
  onboarding,
  profile,
  home,
}
```

Ou passar argumento:

```dart
DependentsListArgs(entryPoint: DependentsEntryPoint.onboarding)
```

Assim o botao voltar sabe para onde ir.

### 16.3 Criar tela/modal de sucesso apos pessoa cuidada

Criar componente:

```text
DependentCreatedSuccessSheet
```

Recebe:

- dependent;
- activationCode;
- callbacks:
  - cadastrar tratamento;
  - copiar/compartilhar codigo;
  - ir para inicio.

### 16.4 Ajustar detalhe da pessoa cuidada por estado

Criar estados derivados:

```dart
final hasTreatments = meds.isNotEmpty;
final isLinked = dependent.isLinked;
final isManagedOnly = !dependent.isLinked;
```

Renderizar:

- bloco `Perfil gerenciado` se nao vinculado;
- bloco `Conta vinculada` se vinculado;
- bloco de tratamento vazio apenas se fizer sentido;
- esconder proxima dose quando nao ha tratamento.

### 16.5 Ajustar textos do tipo de conta

Trocar:

```text
Cuidar de mim
Cuidar de outra pessoa
```

Por:

```text
Minha saude
Cuidar de alguem
Tenho um codigo
```

Se quiser manter apenas duas opcoes no cadastro:

- `Minha saude`
- `Cuidar de alguem`

E colocar `Tenho um codigo` como link visivel na tela de login e na Home de uso
pessoal.

## 17. Criterios de aceite

- [ ] Criar conta cuidador manda para Home, nao para uma tela sem saida.
- [ ] Home de cuidador sem pessoa mostra estado vazio claro.
- [ ] Cadastrar pessoa cuidada mostra sucesso com 3 opcoes claras.
- [ ] Usuario consegue ir para inicio sem cadastrar medicamento.
- [ ] Botao voltar em `Pessoas cuidadas` funciona.
- [ ] Detalhe de pessoa recem-criada nao mostra blocos vazios confusos.
- [ ] Convite aparece como opcional, nao obrigatorio.
- [ ] Cuidador consegue cadastrar tratamento mesmo sem pessoa aceitar codigo.
- [ ] Pessoa cuidada pode criar conta pessoal e depois vincular codigo.
- [ ] Texto explica que a conta continua sendo dela.
- [ ] Uso pessoal continua simples e sem linguagem de cuidador.
- [ ] Estoque, consultas e historico respeitam contexto selecionado.
- [ ] Nao existe fluxo onde o usuario fica preso sem bottom nav ou sem saida.

## 18. Prompt de implementacao

Implemente o redesign do fluxo cuidador/pessoa cuidada/uso pessoal no DoseCerta.

Leia este documento inteiro antes de alterar codigo.

Objetivos principais:

1. Depois de criar conta como cuidador, enviar o usuario para Home com estado
   vazio, nao para uma tela obrigatoria de dependentes.
2. Permitir cadastrar pessoa cuidada sem obrigar cadastro imediato de
   medicamento/tratamento.
3. Corrigir navegacao e botao voltar da tela de pessoas cuidadas.
4. Redesenhar detalhe da pessoa cuidada para separar:
   - perfil gerenciado pelo cuidador;
   - convite pendente/opcional;
   - conta vinculada;
   - tratamentos/doses apenas quando existirem.
5. Explicar melhor o fluxo de codigo:
   - pessoa cuidada pode usar o app criando uma conta pessoal;
   - o codigo apenas vincula essa conta ao cuidador;
   - convite nao e obrigatorio para o cuidador usar o app.
6. Ajustar estados vazios de Home, Estoque, Consultas e Historico.
7. Manter compatibilidade com uso pessoal.

Regras:

- Nao quebrar microservicos existentes.
- Nao alterar contratos de API sem necessidade.
- Preferir ajustes de UX/navegacao no app Flutter.
- Textos ao usuario em portugues.
- Codigo em ingles.
- Preservar funcionamento atual de doses, estoque, consultas e historico.
- Rodar `flutter analyze` ao final.

Entrega esperada:

- Fluxo de cadastro mais direto.
- Home acessivel imediatamente.
- Convite de vinculo tratado como opcional.
- Pessoa cuidada sem tratamento com tela clara, sem CTA obrigatorio confuso.
- Botao voltar funcionando.
- Estados vazios claros para cuidador e uso pessoal.
