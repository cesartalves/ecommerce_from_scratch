# Environment Matrix

| Environment | Application | Database | Jobs |
|---|---|---|---|
| Development | Rails server or Docker Compose | PostgreSQL | Sidekiq or inline/manual execution |
| Test | Rails test runner | Isolated test PostgreSQL database | Test adapter |
| Production | Rails application process | PostgreSQL | Sidekiq with Redis |

## Configuration and Secrets Boundaries

`MP_ACCESS_TOKEN`, `MP_PUBLIC_KEY`, `REDIS_URL`, database variables, and `RAILS_MASTER_KEY` are environment-managed and must not be committed.

## Deployment Differences

Production requires managed database, Redis, web, and worker processes. Local Docker Compose supplies the backing services for development.

## Operational Access

Use Rails database tasks for schema management and the Rails health endpoint at `/up` for application health checks.
