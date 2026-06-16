# DoseCerta

Aplicativo mobile Flutter com backend NestJS e microservicos independentes para rotinas de saude, lembretes de medicamentos, dependentes e notificacoes.

## Estrutura

| Caminho | Descricao |
| --- | --- |
| `lib/` | App Flutter |
| `backend/` | API principal com gateway, auth-service e core-service |
| `ms-linking/` | Microservico de vinculacao responsavel/dependente |
| `ms-scheduler/` | Microservico agendador de doses |

## Microservicos

### ms-linking

Servico REST responsavel por gerar codigos de ativacao, ativar vinculos entre responsaveis e dependentes, impedir duplicidade e publicar `LinkEstablished`.

- Porta: `3003`
- Swagger: `http://localhost:3003/api/docs`
- Banco proprio: `postgres-linking`
- RabbitMQ routing key: `link.established`

### ms-scheduler

Servico interno sem API REST publica. Sincroniza doses pendentes da API principal por rota interna protegida e publica `DoseScheduled` no RabbitMQ quando o horario da dose chega.

- Banco proprio: `postgres-scheduler`
- RabbitMQ routing key: `dose.scheduled`
- Rota interna consumida: `GET /internal/doses/pending`

### ms-notification

Servico reservado para a proxima etapa.

## Rodar com Docker

Subir os microservicos e infraestrutura da raiz:

```bash
docker compose up --build -d ms-linking ms-scheduler
```

Subir a API principal:

```bash
cd backend
docker compose up --build -d auth-service core-service gateway
```

Portas principais:

| Servico | URL |
| --- | --- |
| App/API Gateway | `http://localhost:3000` |
| Auth Service | `http://localhost:3001` |
| Core Service | `http://localhost:3002` |
| ms-linking | `http://localhost:3003` |
| RabbitMQ Management | `http://localhost:15672` |

Credenciais padrao do RabbitMQ: `admin` / `admin`.

## Variaveis de ambiente

Copie os exemplos antes de rodar localmente:

```bash
cp .env.example .env
cp backend/.env.example backend/.env
cp ms-linking/.env.example ms-linking/.env
cp ms-scheduler/.env.example ms-scheduler/.env
```

Chaves internas relevantes:

| Variavel | Uso |
| --- | --- |
| `MS_LINKING_API_KEY` | Chave usada pelo core-service para chamar o ms-linking |
| `CORE_INTERNAL_API_KEY` | Chave exigida pelo core-service na rota interna de doses |
| `MS_SCHEDULER_MAIN_API_KEY` | Chave enviada pelo ms-scheduler ao core-service |

## Rodar o app Flutter no macOS

Com o backend e microservicos no ar:

```bash
flutter run -d macos
```

O app macOS usa `http://localhost:3000` como API base por padrao.

## Comandos uteis

```bash
docker ps
docker compose logs -f ms-linking
docker compose logs -f ms-scheduler
cd backend && docker compose logs -f gateway core-service auth-service
```
