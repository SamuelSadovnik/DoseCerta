# DoseCerta — Backend (Microsserviços)

Backend em arquitetura de microsserviços para o app Flutter DoseCerta.

## Topologia

```
                     ┌─────────────────────┐
   Flutter app ────► │  gateway  :3000     │  (única porta pública)
                     │  - valida JWT       │
                     │  - faz proxy        │
                     └──────┬───────┬──────┘
                            │       │
                  HTTP REST │       │ HTTP REST
                            ▼       ▼
              ┌─────────────────┐  ┌──────────────────┐
              │ auth-service    │  │ core-service     │
              │     :3001       │  │     :3002        │
              │ - users         │  │ - medications    │
              │ - login         │  │ - dependents     │
              │ - register      │  │ - appointments   │
              │ - emite JWT     │  │ - doses          │
              └────────┬────────┘  │ - history        │
                       │           └─────────┬────────┘
                       │                     │
                       ▼                     ▼
              ┌──────────────────────────────────────┐
              │ PostgreSQL :5432 interno             │
              │ schema auth_db │ schema core_db      │
              └──────────────────────────────────────┘
```

Cada serviço:

- Tem seu próprio `package.json`, `Dockerfile`, e ciclo de build independente
- Acessa **apenas seu schema** no Postgres (isolamento de dados)
- É um app NestJS isolado

## Como subir

```bash
cp .env.example .env
docker compose up --build
```

Endpoints expostos pelo gateway: `http://localhost:3000/api/...`

Por padrão, o Postgres do Compose fica em `localhost:5433` no host para evitar conflito com PostgreSQL local; dentro da rede Docker os serviços continuam usando `postgres:5432`.

Exemplo:

```bash
# Registrar
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"João","email":"joao@test.com","password":"123456","accountType":"personal"}'

# Login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"identifier":"joao@test.com","password":"123456"}'

# Listar medicamentos (precisa do accessToken do login)
curl http://localhost:3000/api/medications \
  -H "Authorization: Bearer <accessToken>"
```

## Padrões aplicados (para o relatório técnico)

- **Microsserviços** — cada serviço tem responsabilidade única, deploy isolado, próprio schema
- **API Gateway** — `gateway` é o único ponto de entrada público, centraliza autenticação
- **Repository Pattern** — TypeORM `Repository<T>` em cada feature do core/auth
- **DTO Pattern** — `class-validator` + `class-transformer` para validação de input
- **Factory Provider (NestJS)** — `useFactory` em `JwtModule.registerAsync` e na config do TypeORM, lendo variáveis de ambiente em runtime
- **Strategy Pattern** — `JwtStrategy` (Passport) para extração e validação do token
- **Guard Pattern** — `JwtAuthGuard` protege rotas que exigem usuário autenticado

## Estrutura

```
backend/
├── docker-compose.yml
├── postgres-init/
│   └── 01-create-schemas.sql
├── auth-service/
│   ├── src/
│   │   ├── auth/        (login, register, JWT)
│   │   ├── users/       (entidade User, CRUD interno)
│   │   ├── health/
│   │   └── config/      (TypeORM factory)
│   └── Dockerfile
├── core-service/
│   ├── src/
│   │   ├── medications/ (totalmente implementado)
│   │   ├── dependents/  (CRUD)
│   │   ├── appointments/(CRUD + confirm)
│   │   ├── doses/       (today + take + postpone)
│   │   ├── history/     (monthly aggregation)
│   │   └── common/      (JwtAuthGuard interno, decorator @CurrentUser)
│   └── Dockerfile
└── gateway/
    ├── src/
    │   ├── auth-proxy/  (proxy /api/auth/* → auth-service)
    │   ├── core-proxy/  (proxy /api/* protegido → core-service)
    │   └── common/      (JwtAuthGuard global)
    └── Dockerfile
```
