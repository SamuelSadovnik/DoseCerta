# ms-linking

Microservico NestJS responsavel por criar e ativar vinculos entre responsaveis e dependentes por codigo de ativacao.

## Responsabilidade

- Gerar codigos de ativacao com expiracao.
- Ativar vinculos entre `caregiverId` e `dependentId`.
- Impedir codigo expirado, codigo reutilizado e vinculo ativo duplicado.
- Publicar o evento `LinkEstablished` no RabbitMQ.
- Expor API REST com Swagger e respostas HATEOAS.

## Pre-requisitos

- Node.js 22+
- PostgreSQL 16+
- RabbitMQ 3+

## Rodar localmente

```bash
cd ms-linking
cp .env.example .env
npm install
npm run db:migrate
npm run start:dev
```

Swagger: `http://localhost:3003/api/docs`

## Rodar via Docker

Na raiz do repositorio:

```bash
docker compose up --build ms-linking
```

RabbitMQ Management: `http://localhost:15672` (`admin` / `admin`)

## Variaveis de ambiente

| Variavel | Descricao | Exemplo |
| --- | --- | --- |
| `PORT` | Porta HTTP do servico | `3003` |
| `DATABASE_URL` | URL do PostgreSQL isolado do servico | `postgres://postgres:postgres@localhost:5435/ms_linking` |
| `RABBITMQ_URL` | URL do RabbitMQ | `amqp://admin:admin@localhost:5672` |
| `API_KEY` | Chave interna exigida no header `x-api-key` | `dosecerta-internal-key-linking` |
| `ALLOWED_IPS` | Whitelist de IPs ou CIDRs separados por virgula | `127.0.0.1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16` |
| `ACTIVATION_CODE_TTL_MINUTES` | Tempo padrao de validade do codigo | `60` |

## Endpoints

Todos os endpoints exigem o header:

```http
x-api-key: dosecerta-internal-key-linking
```

| Metodo | Rota | Descricao |
| --- | --- | --- |
| `POST` | `/api/v1/links/generate` | Gera codigo de ativacao para um dependente |
| `POST` | `/api/v1/links/activate` | Ativa vinculo usando codigo valido |
| `GET` | `/api/v1/links?_page=1&_size=10&userId=<uuid>` | Lista vinculos ativos |
| `GET` | `/api/v1/links/:id` | Consulta vinculo especifico |
| `DELETE` | `/api/v1/links/:id` | Desativa vinculo |

## Eventos publicados

Exchange: `dosecerta.events`  
Tipo: `topic`  
Routing key: `link.established`

```json
{
  "eventType": "LinkEstablished",
  "version": "1.0",
  "timestamp": "2025-10-24T14:00:00.000Z",
  "correlationId": "uuid",
  "producer": "ms-linking",
  "data": {
    "linkId": "uuid",
    "caregiverId": "uuid",
    "dependentId": "uuid",
    "dependentName": "Joao Silva",
    "caregiverName": "Maria Silva"
  }
}
```

## Eventos consumidos

Nenhum evento e consumido nesta etapa. O modulo de mensageria ja deixa a conexao RabbitMQ preparada para consumidores futuros.
