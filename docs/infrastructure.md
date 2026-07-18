# Infrastructure Overview

The application is a Rails 7.2 monolith backed by PostgreSQL. Redis and Sidekiq provide asynchronous job execution, and Active Storage manages product media.

## Environments

Local development can run directly with `bin/rails server` or through Docker Compose. Tests use the Rails test environment and its isolated database.

## Core Services and Dependencies

- PostgreSQL stores users, catalog data, carts, orders, payments, and address snapshots.
- Redis backs Sidekiq jobs.
- Mercado Pago processes payments; Correios services provide shipping quotes.

## Deployment and Operations

Prepare schema changes with `bin/rails db:prepare`. Run Sidekiq with `bundle exec sidekiq -C config/sidekiq.yml` when it is not managed by Docker.

## Known Constraints and Risks

Checkout availability depends on external payment and shipping services. Order completion and stock reservation must remain transactional and idempotent.
