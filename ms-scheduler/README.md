# ms-scheduler

Microservico NestJS responsavel por monitorar doses pendentes e publicar eventos quando o horario agendado chega.

## Responsabilidade

- Sincronizar doses `pending` e `postponed` da API principal por uma rota interna protegida.
- Armazenar os agendamentos em um PostgreSQL proprio.
- Publicar o evento `DoseScheduled` no RabbitMQ quando `scheduledAt <= now()`.
- Garantir idempotencia local marcando cada dose como publicada e reutilizando o mesmo `correlationId`.
- Rodar como servico interno, sem API REST publica.

## Pre-requisitos

- Node.js 22+
- PostgreSQL 16+
- RabbitMQ 3+
- API principal DoseCerta rodando com `INTERNAL_API_KEY` configurada

## Rodar localmente

```bash
cd ms-scheduler
cp .env.example .env
npm install
npm run db:migrate
npm run start:dev
```

Como o servico nao expoe REST, a validacao e feita pelos logs, banco `ms_scheduler` e mensagens publicadas no RabbitMQ.

## Rodar via Docker

Na raiz do repositorio:

```bash
docker compose up --build ms-scheduler
```

RabbitMQ Management: `http://localhost:15672` (`admin` / `admin`)

## Variaveis de ambiente

| Variavel | Descricao | Exemplo |
| --- | --- | --- |
| `DATABASE_URL` | URL do PostgreSQL isolado do servico | `postgres://postgres:postgres@localhost:5436/ms_scheduler` |
| `RABBITMQ_URL` | URL do RabbitMQ | `amqp://admin:admin@localhost:5672` |
| `MAIN_API_URL` | URL da API principal usada na sincronizacao | `http://localhost:3002` |
| `MAIN_API_KEY` | Chave enviada para a API principal no header `x-api-key` | `dosecerta-internal-key-scheduler` |
| `SYNC_INTERVAL_MS` | Intervalo para buscar novas doses pendentes | `30000` |
| `PUBLISH_INTERVAL_MS` | Intervalo para publicar doses vencidas | `10000` |
| `SYNC_LOOK_AHEAD_MINUTES` | Janela futura de sincronizacao em minutos | `1440` |
| `BATCH_SIZE` | Maximo de eventos publicados por ciclo | `50` |

## Integracao com a API principal

O scheduler chama a rota interna:

```http
GET /internal/doses/pending?lookAheadMinutes=1440
x-api-key: dosecerta-internal-key-scheduler
```

Essa rota deve retornar doses pendentes ou adiadas dentro da janela de sincronizacao. O scheduler salva uma copia minima dos dados no proprio banco e nao acessa diretamente o banco da API principal.

## Eventos publicados

Exchange: `dosecerta.events`  
Tipo: `topic`  
Routing key: `dose.scheduled`

```json
{
  "eventType": "DoseScheduled",
  "version": "1.0",
  "timestamp": "2025-10-24T14:00:00.000Z",
  "correlationId": "uuid",
  "producer": "ms-scheduler",
  "data": {
    "doseId": "uuid",
    "userId": "uuid",
    "dependentId": "uuid | null",
    "medicationName": "Paracetamol",
    "dosage": "500mg",
    "scheduledAt": "2025-10-24T14:00:00.000Z",
    "note": "Com comida"
  }
}
```

## Eventos consumidos

Nenhum evento e consumido nesta etapa.
