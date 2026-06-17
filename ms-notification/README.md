# ms-notification

Microservico NestJS responsavel por consumir eventos do RabbitMQ, registrar historico de notificacoes e enviar push para os usuarios corretos.

## Responsabilidade

- Consumir eventos `DoseReminder`, `DoseScheduled`, `AppointmentReminder`, `DoseTaken`, `DosePostponed`, `DoseMissed` e `LinkEstablished`.
- Registrar historico de notificacoes enviadas.
- Registrar tokens FCM dos dispositivos.
- Enviar push por FCM ou logar em modo mock durante desenvolvimento.
- Garantir idempotencia por `correlationId`.
- Expor API REST com Swagger e respostas HATEOAS.

## Pre-requisitos

- Node.js 22+
- PostgreSQL 16+
- RabbitMQ 3+
- `ms-linking` rodando para resolver responsaveis de dependentes

## Rodar localmente

```bash
cd ms-notification
cp .env.example .env
npm install
npm run db:migrate
npm run start:dev
```

Swagger: `http://localhost:3004/api/docs`

## Rodar via Docker

Na raiz do repositorio:

```bash
docker compose up --build ms-notification
```

RabbitMQ Management: `http://localhost:15672` (`admin` / `admin`)

## Variaveis de ambiente

| Variavel | Descricao | Exemplo |
| --- | --- | --- |
| `PORT` | Porta HTTP do servico | `3004` |
| `DATABASE_URL` | URL do PostgreSQL isolado do servico | `postgres://postgres:postgres@localhost:5434/ms_notification` |
| `RABBITMQ_URL` | URL do RabbitMQ | `amqp://admin:admin@localhost:5672` |
| `API_KEY` | Chave interna exigida no header `x-api-key` | `dosecerta-internal-key-notification` |
| `ALLOWED_IPS` | Whitelist de IPs ou CIDRs separados por virgula | `127.0.0.1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16` |
| `PUSH_PROVIDER` | `mock` para desenvolvimento ou `fcm` para Firebase | `mock` |
| `FCM_SERVER_KEY` | Chave do Firebase Cloud Messaging | `...` |
| `LINKING_SERVICE_URL` | URL do ms-linking para descobrir responsaveis | `http://localhost:3003` |
| `LINKING_SERVICE_API_KEY` | API key do ms-linking | `dosecerta-internal-key-linking` |

## Endpoints

Todos os endpoints exigem o header:

```http
x-api-key: dosecerta-internal-key-notification
```

| Metodo | Rota | Descricao |
| --- | --- | --- |
| `POST` | `/api/v1/devices/register` | Registra ou atualiza token FCM do dispositivo |
| `GET` | `/api/v1/notifications/:userId?_page=1&_size=10` | Lista historico de notificacoes do usuario |

## Eventos consumidos

Exchange: `dosecerta.events`  
Fila: `ms-notification.events.queue`  
DLQ: `ms-notification.dead-letter.queue`

| Evento | Routing key | Comportamento |
| --- | --- | --- |
| `DoseReminder` | `dose.reminder` | Notifica usuario pessoal ou dependente antes do horario da dose |
| `DoseScheduled` | `dose.scheduled` | Notifica usuario pessoal ou dependente |
| `AppointmentReminder` | `appointment.reminder` | Notifica usuario pessoal ou dependente antes da consulta |
| `DoseTaken` | `dose.taken` | Notifica responsavel quando ha dependente |
| `DosePostponed` | `dose.postponed` | Notifica responsavel quando ha dependente |
| `DoseMissed` | `dose.missed` | Notifica responsavel quando ha dependente |
| `LinkEstablished` | `link.established` | Notifica responsavel e dependente |

## Eventos publicados

Nenhum evento e publicado nesta etapa.
