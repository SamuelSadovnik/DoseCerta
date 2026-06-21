# 💊 DoseCerta

O **DoseCerta** é um aplicativo mobile desenvolvido em **Flutter**, com backend em **NestJS** e arquitetura baseada em **microsserviços**. Seu objetivo é auxiliar usuários na gestão de rotinas de saúde e na adesão a tratamentos médicos, reduzindo o risco de esquecimento de medicamentos e facilitando o acompanhamento de dependentes.

Com o aplicativo, é possível cadastrar medicamentos, organizar horários de administração, receber lembretes automáticos e gerenciar dependentes por meio de um vínculo digital entre cuidador e paciente.

---

# 🏗️ Arquitetura e Padrões Utilizados

## MVVM (Model-View-ViewModel)

O aplicativo utiliza a arquitetura **MVVM**, promovendo a separação entre interface, lógica de negócio e acesso aos dados. Essa abordagem facilita a manutenção, a testabilidade e a escalabilidade do sistema.

## Factory Method

O padrão de projeto **Factory Method** foi aplicado principalmente nos **DTOs (Data Transfer Objects)**, centralizando a conversão de dados JSON recebidos da API para objetos tipados em Dart. Isso proporciona maior organização, reutilização de código e segurança na manipulação dos dados.

---

# 💾 Solução de Armazenamento Local

A persistência local foi implementada utilizando armazenamento seguro baseado em chave-valor, permitindo maior desempenho e melhor experiência para o usuário.

### Dados armazenados localmente

* **Token de autenticação (JWT)**: mantém o usuário autenticado entre sessões.
* **Cache local de dados**: possibilita carregamento mais rápido das informações e acesso a determinados dados mesmo sem conexão com a internet.

---

# 🌐 API Utilizada

O aplicativo consome uma **API REST** desenvolvida em **NestJS** e estruturada em microsserviços.

Toda a comunicação é realizada através de um **API Gateway**, responsável por receber as requisições do aplicativo e encaminhá-las para os serviços apropriados.

## Principais serviços

| Serviço         | Responsabilidade                                   |
| --------------- | -------------------------------------------------- |
| Auth-Service    | Autenticação e autorização de usuários             |
| Core-Service    | Gerenciamento de dependentes, medicamentos e doses |
| ms-linking      | Vinculação entre responsáveis e dependentes        |
| ms-scheduler    | Agendamento e sincronização de doses               |
| ms-notification | Envio e gerenciamento de notificações              |

---

# 📁 Estrutura do Projeto

| Diretório          | Descrição                                            |
| ------------------ | ---------------------------------------------------- |
| `lib/`             | Aplicação Flutter                                    |
| `backend/`         | API principal (Gateway, Auth-Service e Core-Service) |
| `ms-linking/`      | Microsserviço de vinculação                          |
| `ms-scheduler/`    | Microsserviço de agendamento                         |
| `ms-notification/` | Microsserviço de notificações                        |

---

# 🚀 Como Executar o Projeto

## Pré-requisitos

Antes de iniciar, certifique-se de possuir:

* Docker Desktop instalado e em execução;
* Flutter SDK instalado e configurado.

---

## 1. Configuração das Variáveis de Ambiente

Crie os arquivos `.env` a partir dos modelos disponibilizados.

### Windows

```cmd
copy .env.example .env
copy backend\.env.example backend\.env
copy ms-linking\.env.example ms-linking\.env
copy ms-scheduler\.env.example ms-scheduler\.env
copy ms-notification\.env.example ms-notification\.env
```

### Linux / macOS

```bash
cp .env.example .env
cp backend/.env.example backend/.env
cp ms-linking/.env.example ms-linking/.env
cp ms-scheduler/.env.example ms-scheduler/.env
cp ms-notification/.env.example ms-notification/.env
```

---

## 2. Iniciar os Microsserviços

Na raiz do projeto, execute:

```bash
docker compose up --build -d ms-linking ms-scheduler ms-notification
```

---

## 3. Iniciar a API Principal

Acesse a pasta do backend:

```bash
cd backend
docker compose up --build -d auth-service core-service gateway
```

---

## 4. Executar o Aplicativo Flutter

Retorne para a raiz do projeto:

```bash
cd ..
flutter run
```

---

# 🔌 Portas dos Serviços

| Serviço             | Endereço               |
| ------------------- | ---------------------- |
| API Gateway         | http://localhost:3000  |
| Auth-Service        | http://localhost:3001  |
| Core-Service        | http://localhost:3002  |
| ms-linking          | http://localhost:3003  |
| ms-notification     | http://localhost:3004  |
| RabbitMQ Management | http://localhost:15672 |

**Credenciais RabbitMQ**

```text
Usuário: admin
Senha: admin
```

---

# 📋 Comandos Úteis

### Listar contêineres ativos

```bash
docker ps
```

### Visualizar logs dos microsserviços

```bash
docker compose logs -f ms-linking
docker compose logs -f ms-scheduler
docker compose logs -f ms-notification
```

### Visualizar logs da API principal

```bash
cd backend
docker compose logs -f gateway core-service auth-service
```

---

# 📚 Tecnologias Utilizadas

* Flutter
* Dart
* NestJS
* Docker
* RabbitMQ
* PostgreSQL
* REST API
* MVVM
* Factory Method

---

Desenvolvido para auxiliar usuários no gerenciamento de medicamentos, lembretes e cuidados com dependentes de forma prática, segura e eficiente.
