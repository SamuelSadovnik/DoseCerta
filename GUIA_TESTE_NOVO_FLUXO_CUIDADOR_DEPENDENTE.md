# Guia de teste: novo fluxo de cuidador, pessoa cuidada e uso pessoal

Este guia serve para validar o novo modelo do DoseCerta depois do redesenho do
fluxo de cuidador/dependente.

O objetivo principal do teste e confirmar que:

- o cuidador nao fica preso depois de criar conta;
- cadastrar pessoa cuidada nao obriga cadastrar tratamento;
- o codigo de convite e opcional;
- a pessoa cuidada pode existir sem conta propria;
- se quiser, a pessoa cuidada cria uma conta pessoal e vincula com codigo;
- uso pessoal continua simples e independente.

## 1. Ideia principal do novo modelo

Agora pense assim:

### Conta

Conta e quem faz login.

Exemplos:

- Cuidador Teste faz login para cuidar de outras pessoas.
- Joao faz login para cuidar da propria rotina.
- Samuel faz login para cuidar dos proprios remedios.

### Pessoa cuidada

Pessoa cuidada e o perfil de saude acompanhado dentro do app.

Ela pode ser:

- a propria pessoa que fez login;
- uma pessoa gerenciada pelo cuidador;
- uma pessoa gerenciada pelo cuidador e tambem vinculada a uma conta propria.

### Convite

O codigo de convite nao e obrigatorio.

Ele serve apenas para quando a pessoa cuidada tambem quer usar o app pelo proprio
celular/computador.

Ou seja:

```text
Cuidador pode cuidar de Joao sem Joao aceitar codigo.
Joao so precisa aceitar codigo se tambem for usar o app.
```

## 2. Antes de testar

Garanta que backend, microsservicos e app estao rodando.

### Backend e microservicos

Na raiz:

```bash
docker compose up -d
```

No backend:

```bash
cd backend
docker compose up -d
```

Endpoints esperados:

```text
Gateway: http://localhost:3000/api/health
Auth:    http://localhost:3001/health
Core:    http://localhost:3002/health
```

### App macOS

Na raiz:

```bash
flutter run -d macos
```

Ou, se ja tiver buildado:

```bash
open -n build/macos/Build/Products/Debug/dosecerta.app
```

Para testar cuidador e pessoa cuidada ao mesmo tempo, abra duas instancias:

```bash
open -n build/macos/Build/Products/Debug/dosecerta.app
open -n build/macos/Build/Products/Debug/dosecerta.app
```

## 3. Contas sugeridas para teste

Se a base estiver limpa, crie novas contas.

Se ja existir usuario com o mesmo email, troque o numero no email.

### Cuidador

```text
Nome: Cuidador Teste
Email: cuidador.fluxo.001@dosecerta.local
Senha: 123456
Tipo: Cuidar de alguém
```

### Pessoa que vai usar o app tambem

```text
Nome: Joao Teste
Email: joao.fluxo.001@dosecerta.local
Senha: 123456
Tipo: Minha saúde
```

### Uso pessoal independente

```text
Nome: Pessoal Teste
Email: pessoal.fluxo.001@dosecerta.local
Senha: 123456
Tipo: Minha saúde
```

## 4. Teste 1: criar conta como cuidador

Objetivo: validar que o cuidador nao cai mais em um fluxo travado.

Passo a passo:

1. Abra o app.
2. Clique em `Criar conta`.
3. Escolha `Cuidar de alguém`.
4. Preencha nome, email e senha.
5. Finalize o cadastro.

Resultado esperado:

- A tela de sucesso deve mostrar duas opcoes:
  - `Ir para Início`
  - `Adicionar pessoa cuidada`
- `Ir para Início` deve ser a opcao principal.
- O app nao deve obrigar cadastrar pessoa cuidada agora.

Agora clique em:

```text
Ir para Início
```

Resultado esperado:

- Deve abrir a Home.
- Deve aparecer um estado vazio explicando que ainda nao existe pessoa cuidada.
- Deve aparecer CTA:

```text
Adicionar pessoa cuidada
```

Nao deve aparecer uma tela morta nem obrigar cadastrar medicamento.

## 5. Teste 2: cuidador sem pessoa cadastrada

Objetivo: validar estados vazios nas abas principais.

Com a conta de cuidador recem-criada e sem pessoa cuidada:

### Home

1. Va para `Início`.

Esperado:

- Mensagem dizendo que nao ha pessoa cuidada cadastrada.
- Botao `Adicionar pessoa cuidada`.
- Nao deve mostrar cards zerados como erro.

### Estoque

1. Va para `Estoque`.

Esperado:

- Mensagem:

```text
Nenhuma pessoa cuidada cadastrada
```

- CTA para adicionar pessoa cuidada.
- Botao inferior tambem deve levar para adicionar pessoa cuidada, nao para
  cadastrar tratamento.

### Historico

1. Va para `Histórico`.

Esperado:

- Mensagem de historico vazio.
- CTA para adicionar pessoa cuidada.
- Nao deve mostrar calendario vazio como se ja existisse acompanhamento.

### Consultas

1. Va para `Consultas`.

Esperado:

- Mensagem de nenhuma pessoa cuidada.
- CTA para adicionar pessoa cuidada.
- Botao inferior deve levar para adicionar pessoa cuidada, nao nova consulta.

## 6. Teste 3: cadastrar pessoa cuidada

Objetivo: validar que cadastrar pessoa nao obriga tratamento.

Passo a passo:

1. Na Home, clique em `Adicionar pessoa cuidada`.
2. Cadastre:

```text
Nome: Joao
Nascimento: qualquer data valida
Parentesco: outro/conjuge/pai/etc
```

3. Salve.

Resultado esperado:

Apos salvar, deve abrir uma tela de sucesso:

```text
Pessoa cuidada adicionada
```

Ela deve oferecer:

- `Cadastrar tratamento`
- `Copiar código de convite`
- `Ir para Início`

Importante:

- Nenhuma acao deve ser obrigatoria.
- Voce deve conseguir clicar em `Ir para Início`.
- Voce deve conseguir copiar codigo sem vincular ninguem.
- Voce deve conseguir cadastrar tratamento se quiser.

## 7. Teste 4: ir para inicio sem cadastrar tratamento

Objetivo: validar que pessoa cuidada sem tratamento nao quebra fluxo.

Na tela de sucesso da pessoa cuidada:

1. Clique em `Ir para Início`.

Resultado esperado:

- Volta para Home.
- Agora deve existir a pessoa Joao no contexto do cuidador.
- Se selecionar Joao, deve mostrar que nao ha tratamento ainda.
- O app continua navegavel.

Teste as abas:

- `Início`
- `Estoque`
- `Histórico`
- `Consultas`
- `Perfil`

Resultado esperado:

- Tudo deve abrir.
- Nada deve obrigar cadastrar medicamento.
- Estados vazios devem explicar o que falta.

## 8. Teste 5: tela de Pessoas cuidadas

Objetivo: validar lista e botao voltar.

Passo a passo:

1. Va em `Perfil`.
2. Clique em `Pessoas cuidadas`.

Resultado esperado:

- Deve listar Joao.
- Status deve ser algo como:

```text
Convite disponível
```

ou equivalente.

- Nao deve parecer que o app esta bloqueado esperando aceite.

Agora teste o botao de voltar:

1. Clique no botao de voltar.

Resultado esperado:

- Deve voltar para a tela anterior/perfil.
- Nao deve ficar travado na lista.

## 9. Teste 6: detalhe da pessoa cuidada sem tratamento

Objetivo: validar que a tela nao parece morta nem obrigatoria.

Passo a passo:

1. Entre em `Perfil`.
2. Entre em `Pessoas cuidadas`.
3. Toque em Joao.

Resultado esperado:

- Deve aparecer `Pessoa cuidada`.
- Deve aparecer uma area explicando que e um perfil gerenciado pelo cuidador.
- O codigo deve aparecer como convite opcional.
- Deve existir botao para copiar codigo.
- Deve existir botao `Gerar novo código`.
- Deve aparecer mensagem:

```text
Ainda não há tratamento cadastrado
```

- Deve explicar que o tratamento pode ser cadastrado quando quiser.
- Nao deve mostrar `Proxima dose` vazia como bloco principal.
- Nao deve mostrar uma lista de tratamentos vazia como se fosse erro.

## 10. Teste 7: cadastrar tratamento depois

Objetivo: validar que cadastrar tratamento continua funcionando.

No detalhe de Joao:

1. Clique em `Cadastrar tratamento`.
2. Confira se Joao ja vem selecionado no formulario.
3. Cadastre um tratamento.

Exemplo:

```text
Medicamento: Paracetamol
Dosagem: 500mg
Quantidade: 10
Duração: 5 dias
Frequência: 2x ao dia
Pessoa: Joao
```

Resultado esperado:

- O tratamento deve ser salvo.
- Ao voltar para Home/Estoque, Joao deve ter tratamento.
- A tela de detalhe de Joao agora pode mostrar:
  - proxima dose;
  - tratamentos ativos;
  - botao para cadastrar outro tratamento.

## 11. Teste 8: convite opcional

Objetivo: validar que o cuidador consegue usar o app mesmo sem Joao aceitar.

Com Joao ainda sem conta vinculada:

1. Cadastre tratamento para Joao.
2. Va para Home.
3. Selecione Joao.
4. Marque dose como tomada quando existir dose disponivel.
5. Va em Estoque.
6. Va em Historico.

Resultado esperado:

- Cuidador consegue usar tudo para Joao.
- Nao precisa vincular conta.
- Codigo fica disponivel apenas como opcao.

## 12. Teste 9: pessoa cuidada cria conta e vincula codigo

Objetivo: validar o caminho quando Joao tambem quer usar o app.

Em uma segunda janela do app:

1. Crie uma conta `Minha saúde` para Joao.
2. Entre com a conta de Joao.
3. Va em `Perfil`.
4. Clique em `Responsável`.
5. Digite o codigo copiado pelo cuidador.
6. Confirme.

Resultado esperado:

- Texto da tela deve explicar que a conta continua sendo do Joao.
- Ao vincular, deve aparecer sucesso.
- Joao deve ver tratamentos/doses criados pelo cuidador.
- Cuidador deve continuar vendo Joao.
- Na tela do cuidador, Joao deve aparecer como conta vinculada/vinculo ativo.

## 13. Teste 10: uso pessoal independente

Objetivo: garantir que o fluxo pessoal nao ficou estranho.

Passo a passo:

1. Faça logout.
2. Crie uma conta nova.
3. Escolha `Minha saúde`.
4. Complete cadastro.
5. Clique em `Ir para Início`.

Resultado esperado:

- Home deve abrir normalmente.
- Nao deve falar de pessoa cuidada.
- Estoque deve falar de tratamentos do proprio usuario.
- Consultas devem ser `Minhas consultas`.
- Historico deve ser `Meu histórico`.

Agora cadastre um tratamento para si:

```text
Medicamento: Dipirona
Dosagem: 500mg
Quantidade: 10
Duração: 5 dias
Frequência: 2x ao dia
```

Resultado esperado:

- Tratamento aparece para a propria conta.
- Doses aparecem na Home.
- Historico funciona.
- Nao deve pedir dependente/pessoa cuidada.

## 14. Teste 11: gerar novo codigo

Objetivo: validar fluxo de codigo expirado/perdido.

Na conta do cuidador:

1. Va em `Pessoas cuidadas`.
2. Abra Joao.
3. Clique em `Gerar novo código`.

Resultado esperado:

- Deve aparecer mensagem de sucesso.
- Codigo deve mudar na tela.
- Codigo antigo nao deve ser usado para novo vinculo.

Observacao:

- Se Joao ja estiver vinculado, o app/backend nao devem permitir gerar novo
  codigo para aquela pessoa.

## 15. Checklist rapido

Marque conforme testar:

- [ ] Cuidador criado vai para tela de sucesso com `Ir para Início`.
- [ ] Cuidador consegue entrar na Home sem cadastrar pessoa.
- [ ] Home vazia do cuidador tem CTA correto.
- [ ] Estoque vazio do cuidador tem CTA correto.
- [ ] Consultas vazias do cuidador tem CTA correto.
- [ ] Historico vazio do cuidador tem CTA correto.
- [ ] Pessoa cuidada criada mostra tela de sucesso.
- [ ] Tela de sucesso permite ir para inicio sem cadastrar tratamento.
- [ ] Tela de sucesso permite copiar codigo.
- [ ] Tela de sucesso permite cadastrar tratamento.
- [ ] Lista de pessoas cuidadas volta corretamente.
- [ ] Detalhe de pessoa sem tratamento nao mostra blocos confusos.
- [ ] Convite aparece como opcional.
- [ ] Cuidador consegue cadastrar tratamento antes do vinculo.
- [ ] Cuidador consegue usar Joao sem Joao aceitar codigo.
- [ ] Joao consegue criar conta `Minha saúde`.
- [ ] Joao consegue vincular codigo pelo Perfil.
- [ ] Uso pessoal independente continua funcionando.
- [ ] Novo tratamento vindo do detalhe de Joao preseleciona Joao.

## 16. Possiveis problemas para observar

Durante o teste, preste atencao nestes pontos:

- Se algum botao de voltar prende em tela errada.
- Se algum texto ainda fala `dependente` de forma confusa.
- Se o cuidador consegue cadastrar consulta/tratamento sem escolher pessoa
  quando deveria escolher.
- Se a conta pessoal passa a parecer obrigatoriamente dependente.
- Se uma pessoa sem tratamento ainda mostra proxima dose vazia como se fosse erro.
- Se depois de vincular, Joao nao enxerga os dados criados pelo cuidador.

## 17. Resultado esperado final

O novo fluxo deve parecer assim:

```text
Cuidador cria conta
-> vai para Home
-> adiciona pessoa cuidada quando quiser
-> pode ir para inicio sem cadastrar tratamento
-> pode cadastrar tratamento quando quiser
-> pode compartilhar codigo se a pessoa tambem for usar o app
```

E para pessoa cuidada:

```text
Pessoa cria conta Minha saúde
-> usa sozinha se quiser
-> se recebeu codigo, vincula responsavel
-> continua sendo dona da propria conta
-> responsavel passa a acompanhar rotina
```

Esse e o modelo que deve ficar claro para o usuario.
