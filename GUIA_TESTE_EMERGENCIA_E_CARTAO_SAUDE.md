# Guia de teste: Cartão de Saúde, Rede de Emergência e SOS

Este guia valida as melhorias de emergência implementadas no DoseCerta.

## O que foi implementado

### Perfil do usuário

- `Informações adicionais` virou **Cartão de Saúde**.
- `Contatos de emergência` virou **Rede de emergência**.
- Foi adicionada a opção **Botão de emergência** no Perfil.
- O Cartão de Saúde agora possui mais campos:
  - alergias;
  - doenças/condições;
  - tipo sanguíneo;
  - medicamentos de uso contínuo;
  - médico de referência;
  - plano de saúde;
  - hospital preferencial;
  - observações médicas.
- A Rede de emergência permite definir um contato principal.
- A tela de Emergência usa o contato principal como prioridade.

### Pessoa cuidada

- Cada pessoa cuidada agora pode ter:
  - Cartão de Saúde próprio;
  - Rede de emergência própria;
  - contato principal próprio.
- Esses dados ficam no perfil compartilhado da pessoa cuidada.
- Cuidador e dependente vinculado acessam o mesmo perfil.
- Quando uma conta pessoal que já tinha Cartão/Rede é vinculada a um cuidador, esses dados são migrados para o perfil compartilhado da pessoa cuidada.
- Se o cuidador editar o Cartão/Rede depois do vínculo, o dependente passa a ver a alteração também.

### SOS

- O botão de emergência deixou de ser apenas uma mensagem visual.
- Agora abre uma tela real de emergência.
- A tela permite:
  - ligar para contato principal;
  - chamar SAMU `192`;
  - chamar Bombeiros `193`;
  - abrir o Cartão de Saúde;
  - ver resumo dos dados médicos preenchidos.

## Pré-requisitos

Suba o projeto normalmente:

```bash
docker compose up -d
flutter run -d macos
```

Para testar cuidador e dependente ao mesmo tempo, rode duas instâncias do app macOS.

## Fluxo 1: uso pessoal

Objetivo: validar que uma pessoa usando sozinha consegue configurar dados de emergência próprios.

1. Crie ou entre com uma conta do tipo **Minha saúde**.
2. Vá em **Perfil**.
3. Toque em **Cartão de Saúde**.
4. Preencha:
   - alergias;
   - condições;
   - tipo sanguíneo;
   - medicamentos contínuos;
   - médico;
   - plano;
   - hospital;
   - observações.
5. Salve.
6. Volte para o Perfil.
7. Toque em **Rede de emergência**.
8. Cadastre um contato.
9. Marque como contato principal.
10. Salve.
11. Volte para o Perfil.
12. Toque em **Botão de emergência**.

Resultado esperado:

- A tela de emergência abre.
- O contato principal aparece como primeira ação.
- O resumo do Cartão de Saúde aparece com os dados preenchidos.
- Existem ações para SAMU, Bombeiros e Cartão de Saúde.

## Fluxo 2: cuidador cria pessoa cuidada

Objetivo: validar Cartão de Saúde e contatos próprios da pessoa cuidada.

1. Entre como cuidador.
2. Vá em **Perfil**.
3. Acesse **Pessoas cuidadas**.
4. Crie ou abra uma pessoa cuidada.
5. Na tela da pessoa cuidada, procure a seção **Segurança e emergência**.
6. Em **Cartão de Saúde**, toque em **Editar**.
7. Preencha dados médicos da pessoa cuidada.
8. Salve.
9. Em **Rede de emergência**, toque em **Cadastrar** ou **Editar**.
10. Cadastre um contato da pessoa cuidada.
11. Salve.

Resultado esperado:

- O Cartão de Saúde aparece no detalhe da pessoa cuidada.
- A Rede de emergência aparece no detalhe da pessoa cuidada.
- O contato principal aparece com botão de ligação.
- Os dados pertencem à pessoa cuidada, não ao cuidador.

## Fluxo 3: dependente vinculado

Objetivo: validar que cuidador e dependente veem o mesmo perfil compartilhado.

1. Em uma janela, entre como conta pessoal.
2. Vá em **Perfil > Cartão de Saúde** e preencha alguns dados.
3. Vá em **Perfil > Rede de emergência** e cadastre um contato principal.
4. Em outra janela, entre como cuidador.
5. Crie uma pessoa cuidada correspondente a essa conta pessoal.
6. Copie o código de convite.
7. Volte para a conta pessoal.
8. Vá em **Perfil > Responsável**.
9. Vincule usando o código.
10. Volte para o cuidador e abra o detalhe da pessoa cuidada.
11. Confira a seção **Segurança e emergência**.

Resultado esperado:

- O vínculo continua funcionando.
- Tratamentos, consultas e histórico continuam sincronizados.
- O Cartão de Saúde preenchido antes do vínculo aparece para o cuidador.
- A Rede de emergência preenchida antes do vínculo aparece para o cuidador.
- O app não apaga dados já cadastrados pelo cuidador.

## Fluxo 4: cuidador edita dados compartilhados

Objetivo: validar o caminho inverso, quando o cuidador cadastra ou corrige dados para uma pessoa vinculada.

1. Entre como cuidador.
2. Abra **Perfil > Pessoas cuidadas**.
3. Abra uma pessoa cuidada que esteja com status de conta vinculada.
4. Em **Cartão de Saúde**, toque em **Editar**.
5. Altere um campo, por exemplo **Plano de saúde**.
6. Salve.
7. Em **Rede de emergência**, toque em **Editar**.
8. Adicione ou altere um contato principal.
9. Na outra janela, entre na conta pessoal vinculada.
10. Abra **Perfil > Cartão de Saúde**, **Rede de emergência** e **Botão de emergência**.

Resultado esperado:

- A conta pessoal vê o Cartão de Saúde alterado pelo cuidador.
- A conta pessoal vê a Rede de emergência alterada pelo cuidador.
- A tela de Emergência usa os dados compartilhados da pessoa cuidada.
- Se a pessoa pessoal editar esses dados novamente, o cuidador também vê a atualização no detalhe da pessoa cuidada.

## Fluxo 5: botão de emergência em dose ou consulta

Objetivo: validar que o botão de emergência dos feedbacks abre a tela certa.

1. Cadastre um tratamento com horário próximo.
2. Abra a dose na Home.
3. Marque como tomada ou adie.
4. Na tela de feedback, toque em **Emergência**.

Resultado esperado:

- O app abre a tela de Emergência.
- Não aparece mais apenas snackbar.
- O botão mostra ações reais.

Repita também com consulta:

1. Cadastre uma consulta.
2. Abra a consulta.
3. Confirme, reagende, conclua ou cancele.
4. Na tela de feedback, toque em **Emergência**.

Resultado esperado:

- A mesma tela de Emergência abre.

## Fluxo 6: dados vazios

Objetivo: validar estados vazios.

1. Use uma conta sem contato de emergência.
2. Abra **Botão de emergência**.

Resultado esperado:

- A primeira ação deve ser **Cadastrar contato principal**.
- O app não deve quebrar.
- SAMU, Bombeiros e Cartão de Saúde continuam disponíveis.

3. Use uma pessoa cuidada sem Cartão de Saúde.
4. Abra o detalhe dela.

Resultado esperado:

- A seção informa que não há dados médicos cadastrados.
- A seção permite editar/cadastrar.

## O que observar

Durante o teste, validar:

- Os dados salvos permanecem após sair e voltar da tela.
- O cuidador consegue salvar dados da pessoa cuidada.
- O dependente vinculado continua sincronizando tratamentos/consultas.
- O uso pessoal sem vínculo continua funcionando normalmente.
- O botão de emergência não força uma ligação automaticamente.
- A ligação usa o app/ambiente do sistema operacional quando possível.

## Observação técnica

Nesta etapa, foram adicionados campos ao `Dependent` no backend:

- `healthInfo`
- `emergencyContacts`

Como o `core-service` usa TypeORM com `synchronize: true` no ambiente local, as colunas são criadas automaticamente no banco local ao subir o serviço.

Em ambiente de produção, o ideal seria criar uma migration formal para esses campos.
